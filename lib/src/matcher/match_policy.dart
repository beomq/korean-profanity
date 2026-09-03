import '../normalized_text.dart';
import '../profanity_dictionary.dart';
import '../profanity_match.dart';
import 'dictionary_entry.dart';
import 'pattern_scanner.dart';

List<ProfanityMatch> evaluateMatches(
  NormalizedText normalized,
  PatternScanner? scanner,
  PatternScanner? allowScanner,
  PatternScanner? choseongScanner, {
  required bool choseongSearch,
}) {
  final allowed = _sourceRanges(allowScanner, normalized);
  final candidates = <_Candidate>[];
  _collect(candidates, scanner, normalized, allowed, choseong: false);
  if (choseongSearch) {
    _collect(
      candidates,
      choseongScanner,
      normalized,
      allowed,
      choseong: true,
    );
  }
  final literalRanges = [
    for (final candidate in candidates)
      if (candidate.mode == MatchMode.literal)
        (candidate.match.start, candidate.match.end),
  ];
  final accepted = candidates
      .where(
        (candidate) =>
            candidate.mode == MatchMode.literal ||
            !literalRanges.any(
              (range) =>
                  range.$1 <= candidate.match.start &&
                  range.$2 >= candidate.match.end,
            ),
      )
      .map((candidate) => candidate.match)
      .toList();
  return List.unmodifiable(_deduplicateAndSort(accepted));
}

List<(int, int)> _sourceRanges(
  PatternScanner? scanner,
  NormalizedText normalized,
) {
  if (scanner == null) return const [];
  return [
    for (final hit in scanner.scan(normalized.canonical))
      (() {
        final span = normalized.sourceSpan(hit.start, hit.end);
        return (span.start, span.end);
      })(),
  ];
}

void _collect(
  List<_Candidate> output,
  PatternScanner? scanner,
  NormalizedText normalized,
  List<(int, int)> allowed, {
  required bool choseong,
}) {
  if (scanner == null) return;
  final text = choseong ? normalized.choseong : normalized.canonical;
  final sourceScalars =
      choseong ? normalized.choseongScalars : normalized.canonicalScalars;
  for (final hit in scanner.scan(text)) {
    if (hit.entry.mode == MatchMode.asciiWord &&
        !hasAsciiIdentifierBoundary(sourceScalars, hit.start, hit.end)) {
      continue;
    }
    final span = normalized.sourceSpan(hit.start, hit.end, choseong: choseong);
    if (allowed.any(
      (range) => range.$1 <= span.start && range.$2 >= span.end,
    )) {
      continue;
    }
    output.add(
      _Candidate(
        ProfanityMatch(
          start: span.start,
          end: span.end,
          text: normalized.original.substring(span.start, span.end),
          word: hit.entry.canonical,
          tier: hit.entry.tier,
          isGapMatch: span.isGap,
        ),
        hit.entry.mode,
      ),
    );
  }
}

List<ProfanityMatch> _deduplicateAndSort(List<ProfanityMatch> candidates) {
  final unique = <String, ProfanityMatch>{};
  for (final match in candidates) {
    final key = '${match.start}:${match.end}:${match.word}';
    final previous = unique[key];
    if (previous == null || _severity(match.tier) > _severity(previous.tier)) {
      unique[key] = match;
    }
  }
  final matches = unique.values.toList();
  matches.sort((left, right) {
    var result = left.start.compareTo(right.start);
    if (result != 0) return result;
    result = (right.end - right.start).compareTo(left.end - left.start);
    if (result != 0) return result;
    result = _severity(right.tier).compareTo(_severity(left.tier));
    if (result != 0) return result;
    return left.word.compareTo(right.word);
  });
  return matches;
}

int _severity(ProfanityTier tier) => tier == ProfanityTier.strict ? 1 : 0;

final class _Candidate {
  const _Candidate(this.match, this.mode);

  final ProfanityMatch match;
  final MatchMode mode;
}
