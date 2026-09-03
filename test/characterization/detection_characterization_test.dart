import 'package:korean_profanity/korean_profanity_lenient.dart' as lenient;
import 'package:korean_profanity/src/normalized_text.dart';
import 'package:korean_profanity/src/normalizer.dart';
import 'package:korean_profanity/src/profanity_matcher.dart';
import 'package:test/test.dart';

import '../fixtures/detection_cases.dart';

void main() {
  test('fixture is complete with exactly rows 1-58', () {
    expect(detectionCases, hasLength(58));
    expect(detectionCases.map((entry) => entry.id),
        List.generate(58, (i) => i + 1));
  });

  for (final entry in detectionCases) {
    test('row ${entry.id}: ${entry.normalization}', () {
      final matcher = ProfanityMatcher(
        dictionary: entry.includeLenient ||
                entry.minimumTier == lenient.ProfanityTier.lenient
            ? lenient.koreanLenientDictionary
            : null,
        minimumTier: entry.minimumTier,
        choseongSearch: entry.choseong,
        addedWords: entry.added,
        removedWords: entry.removed,
        ignoreWords: entry.ignored,
      );
      final normalized = normalizeText(entry.input);
      final matches = matcher.findAll(entry.input);

      expect(normalized.canonical, entry.normalization);
      expect(_barrierIndices(normalized), entry.barrierIndices);
      expect(matcher.contains(entry.input), entry.matches.isNotEmpty);
      expect(matches, hasLength(entry.matches.length));
      for (var index = 0; index < entry.matches.length; index++) {
        final actual = matches[index];
        final expected = entry.matches[index];
        expect(actual.start, expected.start);
        expect(actual.end, expected.end);
        expect(actual.word, expected.word);
        expect(actual.tier, expected.tier);
        expect(actual.isGapMatch, expected.gap);
        expect(entry.input.substring(actual.start, actual.end), actual.text);
      }
      expect(matcher.mask(entry.input), entry.mask);
      if (entry.matches.isEmpty) expect(matcher.mask(entry.input), entry.input);
    });
  }
}

List<int> _barrierIndices(NormalizedText normalized) => [
      for (var index = 0; index < normalized.canonicalScalars.length; index++)
        if (_isHardBarrier(normalized.canonicalScalars[index].value)) index,
    ];

bool _isHardBarrier(int scalar) =>
    scalar == 0x0a ||
    scalar == 0x0d ||
    scalar == 0x2028 ||
    scalar == 0x2029 ||
    scalar >= 0x10000 ||
    (scalar >= 0x200b && scalar <= 0x200f) ||
    (scalar >= 0x202a && scalar <= 0x202e) ||
    (scalar >= 0x2060 && scalar <= 0x206f);
