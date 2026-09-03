import 'package:korean_profanity/korean_profanity.dart';
import 'dart:isolate';

import 'package:korean_profanity/korean_profanity_lenient.dart' as lenient;
import 'package:korean_profanity/src/profanity_filter_cache.dart';
import 'package:test/test.dart';

void main() {
  group('constructor customization', () {
    test('shares one lazily built matcher only across default filters', () {
      expect(DefaultMatcherCacheTestSeam.buildCount, 0);

      expect(
        () => KoreanProfanityFilter(addedWords: const ['']),
        throwsArgumentError,
      );
      final custom = KoreanProfanityFilter(addedWords: const ['내부검증욕']);
      expect(custom.contains('내부검증욕'), isTrue);
      expect(DefaultMatcherCacheTestSeam.buildCount, 0);

      final first = KoreanProfanityFilter();
      final second = KoreanProfanityFilter();
      expect(DefaultMatcherCacheTestSeam.acquisitionCount, 2);
      expect(DefaultMatcherCacheTestSeam.buildCount, 1);
      expect(first.contains('시발'), isTrue);
      expect(second.contains('개새끼'), isTrue);
      expect(DefaultMatcherCacheTestSeam.buildCount, 1);

      final removed = KoreanProfanityFilter(removedWords: const ['시발']);
      final replaced = KoreanProfanityFilter(
        dictionary: ProfanityDictionary(strictWords: const ['전용금칙어']),
      );
      final choseong = KoreanProfanityFilter(choseongSearch: true);
      expect(removed.contains('시발'), isFalse);
      expect(replaced.contains('전용금칙어'), isTrue);
      expect(replaced.contains('시발'), isFalse);
      expect(choseong.contains('수박'), isFalse);
      expect(first.contains('시발'), isTrue);
      expect(first.contains('전용금칙어'), isFalse);
      expect(DefaultMatcherCacheTestSeam.acquisitionCount, 2);
      expect(DefaultMatcherCacheTestSeam.buildCount, 1);
    });

    test('adds, removes, and ignores normalized words', () {
      final added = KoreanProfanityFilter(addedWords: const ['우리회사욕']);
      final removed = KoreanProfanityFilter(removedWords: const ['시 발']);
      final ignored = KoreanProfanityFilter(ignoreWords: const ['시발점']);

      expect(added.contains('우리회사욕'), isTrue);
      expect(removed.contains('시발'), isFalse);
      expect(ignored.contains('시발점'), isFalse);
    });

    test('honors minimum tier for a supplied dictionary', () {
      final dictionary = ProfanityDictionary(
        strictWords: const ['엄격'],
        lenientWords: const ['느슨'],
      );
      final strict = KoreanProfanityFilter(dictionary: dictionary);
      final lenient = KoreanProfanityFilter(
        dictionary: dictionary,
        minimumTier: ProfanityTier.lenient,
      );

      expect(strict.contains('엄격 느슨'), isTrue);
      expect(strict.contains('느슨'), isFalse);
      expect(lenient.findAll('느슨').single.tier, ProfanityTier.lenient);
    });

    test('enables optional bundled choseong matching only when opted in', () {
      final defaultFilter = KoreanProfanityFilter();
      final choseongFilter = KoreanProfanityFilter(
        dictionary: lenient.koreanLenientDictionary,
        minimumTier: ProfanityTier.lenient,
        choseongSearch: true,
      );

      expect(defaultFilter.contains('수박'), isFalse);
      expect(choseongFilter.contains('수박'), isTrue);
      expect(choseongFilter.findAll('수박').single.word, '시발');
    });

    test('new configurations do not mutate existing or default instances', () {
      final original = KoreanProfanityFilter();
      final custom = KoreanProfanityFilter(
        addedWords: const ['우리회사욕'],
        removedWords: const ['시발'],
      );

      expect(original.contains('시발'), isTrue);
      expect(original.contains('우리회사욕'), isFalse);
      expect(custom.contains('시발'), isFalse);
      expect(custom.contains('우리회사욕'), isTrue);
      expect(KoreanProfanityFilter().contains('시발'), isTrue);
    });

    test('returned matches and dictionary collections are immutable', () {
      final matches = KoreanProfanityFilter().findAll('개새끼');
      final dictionary = ProfanityDictionary(strictWords: const ['욕']);

      expect(() => matches.clear(), throwsUnsupportedError);
      expect(() => dictionary.strictWords.add('추가'), throwsUnsupportedError);
    });

    test('reuses one instance deterministically across shared calls', () {
      final filter = KoreanProfanityFilter();
      final expected = [
        for (final match in filter.findAll('개새끼'))
          (match.start, match.end, match.word),
      ];

      expect(expected, [(0, 3, '개새끼'), (1, 3, '새끼')]);
      for (var call = 0; call < 64; call++) {
        expect(
          [
            for (final match in filter.findAll('개새끼'))
              (match.start, match.end, match.word),
          ],
          expected,
        );
        expect(filter.contains('씨1발'), isTrue);
      }
      expect(dictionaryVersion, matches(RegExp(r'^[0-9a-f]{12}$')));
    });

    test('collects serial synchronous calls through futures', () async {
      final filter = KoreanProfanityFilter();
      final results = await Future.wait([
        for (var index = 0; index < 64; index++)
          Future.value(filter.findAll('씨 11 발').single.word),
      ]);

      expect(results, everyElement('씨발'));
      expect(filter.mask('씨 11 발'), '******');
    });

    test('runs independently and deterministically in separate isolates',
        () async {
      expect(KoreanProfanityFilter().contains('시발'), isTrue);
      expect(DefaultMatcherCacheTestSeam.buildCount, 1);

      final results = await Future.wait([
        for (var index = 0; index < 4; index++)
          Isolate.run(
            () => KoreanProfanityFilter()
                .findAll(index.isEven ? '개새끼' : 'clean')
                .length,
          ),
      ]);

      expect(results, orderedEquals([2, 0, 2, 0]));
      expect(DefaultMatcherCacheTestSeam.buildCount, 1);
    });

    test('handles dense overlap input with bounded deterministic output', () {
      final matches = KoreanProfanityFilter().findAll('개새끼개새끼');

      expect(matches, hasLength(4));
      expect(matches.map((match) => match.start), orderedEquals([0, 1, 3, 4]));
    });

    test('rejects malformed custom values without poisoning construction', () {
      for (final customization in <KoreanProfanityFilter Function()>[
        () => KoreanProfanityFilter(addedWords: const ['']),
        () => KoreanProfanityFilter(removedWords: const ['   ']),
        () => KoreanProfanityFilter(ignoreWords: const ['']),
      ]) {
        for (var attempt = 0; attempt < 2; attempt++) {
          expect(customization, throwsArgumentError);
        }
      }
      expect(KoreanProfanityFilter().contains('시발'), isTrue);
    });
  });
}
