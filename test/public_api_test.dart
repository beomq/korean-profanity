import 'package:korean_profanity/korean_profanity.dart';
import 'package:test/test.dart';

void main() {
  group('KoreanProfanityFilter public API', () {
    test('default filter detects direct and normalized gap matches', () {
      final filter = KoreanProfanityFilter();

      expect(filter.contains('씨1발'), isTrue);
      final matches = filter.findAll('씨 11 발');
      expect(matches, hasLength(1));
      expect(matches.single.start, 0);
      expect(matches.single.end, 6);
      expect(matches.single.text, '씨 11 발');
      expect(matches.single.word, '씨발');
      expect(matches.single.tier, ProfanityTier.strict);
      expect(matches.single.isGapMatch, isTrue);
      expect(
        '씨 11 발'.substring(matches.single.start, matches.single.end),
        matches.single.text,
      );
      expect(filter.contains('씨 11 발'), matches.isNotEmpty);
    });

    test('requires exactly one Unicode scalar for a mask character', () {
      final filter = KoreanProfanityFilter();

      expect(
        () => filter.mask('text', maskCharacter: ''),
        throwsArgumentError,
      );
      expect(
        () => filter.mask('text', maskCharacter: 'ab'),
        throwsArgumentError,
      );
      expect(filter.mask('시발', maskCharacter: '😀'), '😀😀');
    });

    test('constructs every immutable customization option', () {
      expect(
        () => KoreanProfanityFilter(
          dictionary: ProfanityDictionary(
            strictWords: const ['strict'],
            lenientWords: const ['lenient'],
            allowWords: const ['allow'],
            choseongPatterns: const ['ㅅㅂ'],
          ),
          minimumTier: ProfanityTier.lenient,
          addedWords: const ['added'],
          removedWords: const ['removed'],
          ignoreWords: const ['ignore'],
          choseongSearch: false,
        ),
        returnsNormally,
      );
    });
  });
}
