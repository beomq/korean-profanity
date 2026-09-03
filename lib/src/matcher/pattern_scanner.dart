import '../aho_corasick.dart';
import '../normalized_text.dart';
import 'dictionary_entry.dart';

final class PatternHit {
  const PatternHit(this.entry, this.start, this.end);

  final DictionaryEntry entry;
  final int start;
  final int end;
}

final class PatternScanner {
  PatternScanner(List<DictionaryEntry> entries)
      : entries = List.unmodifiable(entries),
        _patternLengths = List.unmodifiable(
          entries.map((entry) => entry.pattern.runes.length),
        ),
        _automaton = AhoCorasick(
          entries.map((entry) => entry.pattern).toList(growable: false),
        );

  final List<DictionaryEntry> entries;
  final List<int> _patternLengths;
  final AhoCorasick _automaton;

  List<PatternHit> scan(String text) => [
        for (final hit in _automaton.scanHits(text))
          PatternHit(
            entries[hit.patternId],
            hit.end - _patternLengths[hit.patternId],
            hit.end,
          ),
      ];
}

bool hasAsciiIdentifierBoundary(
  List<NormalizedScalar> scalars,
  int start,
  int end,
) {
  if (start > 0 && _isAsciiIdentifier(scalars[start - 1].value)) return false;
  if (end < scalars.length && _isAsciiIdentifier(scalars[end].value)) {
    return false;
  }
  return true;
}

bool _isAsciiIdentifier(int scalar) =>
    (scalar >= 0x30 && scalar <= 0x39) ||
    (scalar >= 0x41 && scalar <= 0x5a) ||
    (scalar >= 0x61 && scalar <= 0x7a) ||
    scalar == 0x5f;
