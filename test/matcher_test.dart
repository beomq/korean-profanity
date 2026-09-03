import 'package:korean_profanity/korean_profanity.dart';
import 'package:korean_profanity/korean_profanity_lenient.dart' as lenient;
import 'package:korean_profanity/src/profanity_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('matcher policy', () {
    test('strict and lenient thresholds are isolated', () {
      final strict = ProfanityMatcher();
      final suppliedButStrict = ProfanityMatcher(
        dictionary: lenient.koreanLenientDictionary,
        minimumTier: ProfanityTier.strict,
      );
      final lenientMatcher = ProfanityMatcher(
        dictionary: lenient.koreanLenientDictionary,
        minimumTier: ProfanityTier.lenient,
      );

      expect(strict.contains('토토 하자'), isFalse);
      expect(suppliedButStrict.contains('토토 하자'), isFalse);
      expect(
        ProfanityMatcher(choseongSearch: true).contains('수박'),
        isFalse,
      );
      expect(
        lenientMatcher.findAll('토토 하자').single.tier,
        ProfanityTier.lenient,
      );
      expect(lenientMatcher.contains('시발'), isTrue);
    });

    test('custom dictionary replaces bundled data and remains immutable', () {
      final strictWords = <String>['금칙'];
      final dictionary = ProfanityDictionary(
        strictWords: strictWords,
        lenientWords: const ['주의'],
        allowWords: const ['금칙어'],
      );
      strictWords.add('나중');
      final matcher = ProfanityMatcher(dictionary: dictionary);

      expect(matcher.contains('시발'), isFalse);
      expect(matcher.contains('나중'), isFalse);
      expect(matcher.contains('금칙어'), isFalse);
      expect(matcher.findAll('금칙!').single.word, '금칙');
    });

    test('rejects empty and normalized duplicate configuration', () {
      expect(
        () => ProfanityMatcher(addedWords: const ['']),
        throwsArgumentError,
      );
      expect(
        () => ProfanityMatcher(ignoreWords: const ['   ']),
        throwsArgumentError,
      );
      expect(
        () => ProfanityMatcher(
          dictionary: ProfanityDictionary(strictWords: const ['Ａ', 'a']),
        ),
        throwsArgumentError,
      );
      expect(
        () => ProfanityMatcher(
          dictionary: ProfanityDictionary(lenientWords: const ['']),
        ),
        throwsArgumentError,
      );
      expect(
        () => ProfanityMatcher(
          dictionary: ProfanityDictionary(choseongPatterns: const ['']),
        ),
        throwsArgumentError,
      );
    });

    test('deduplicates repeated removal and ignore configuration', () {
      final removed = ProfanityMatcher(removedWords: const ['시발', '시발']);
      final ignored = ProfanityMatcher(
        ignoreWords: const ['시발점', '시발점'],
      );

      expect(removed.contains('시발'), isFalse);
      expect(ignored.contains('시발점'), isFalse);
    });

    test('accepts an empty dictionary without fallback or partial state', () {
      final matcher = ProfanityMatcher(dictionary: ProfanityDictionary());

      expect(matcher.findAll('시발 anything'), isEmpty);
      expect(matcher.mask('시발 anything'), '시발 anything');
    });

    test('allow occurrences suppress only fully covered candidates', () {
      final matcher = ProfanityMatcher(
        dictionary: ProfanityDictionary(
          strictWords: const ['금칙', '칙'],
          allowWords: const ['금칙어'],
        ),
      );

      expect(matcher.findAll('금칙어'), isEmpty);
      expect(matcher.findAll('큰금칙').map((match) => match.word), ['금칙', '칙']);
    });

    test('returns deterministic dense overlaps and supports reuse', () {
      final words = [for (var length = 1; length <= 32; length++) '가' * length];
      final matcher = ProfanityMatcher(
        dictionary: ProfanityDictionary(strictWords: words),
      );

      final first = matcher.findAll('가' * 64);
      expect(first, hasLength(1552));
      expect(first.take(3).map((match) => match.word.length), [32, 31, 30]);
      expect(matcher.findAll('clean'), isEmpty);
      expect(matcher.findAll('가' * 64).map(_signature), first.map(_signature));
    });

    test('reuses one matcher across scheduled same-isolate calls', () async {
      final matcher = ProfanityMatcher();
      final results = await Future.wait([
        for (var index = 0; index < 32; index++)
          Future(() => matcher.findAll(index.isEven ? '개새끼' : 'clean')),
      ]);

      for (var index = 0; index < results.length; index++) {
        expect(results[index].length, index.isEven ? 2 : 0);
      }
    });

    test('mask merges touching ranges and counts source scalars', () {
      final matcher = ProfanityMatcher(
        dictionary: ProfanityDictionary(strictWords: const ['욕', '😀']),
      );

      expect(matcher.mask('욕😀'), '**');
      expect(matcher.mask('x욕😀y', maskCharacter: '●'), 'x●●y');
      expect(() => matcher.mask('욕', maskCharacter: ''), throwsArgumentError);
      expect(() => matcher.mask('욕', maskCharacter: '**'), throwsArgumentError);
    });

    test('literal match dominates its contained substring', () {
      final matches = ProfanityMatcher().findAll('10새끼');

      expect(matches.map((match) => match.word), ['10새끼']);
    });

    test('normalized removal also removes choseong canonical entries', () {
      final matcher = ProfanityMatcher(
        choseongSearch: true,
        removedWords: const ['시발'],
      );

      expect(matcher.findAll('시발'), isEmpty);
      expect(matcher.findAll('수박'), isEmpty);
      expect(matcher.findAll('ㅅㅂ'), isEmpty);
    });
  });
}

String _signature(ProfanityMatch match) =>
    '${match.start}:${match.end}:${match.word}:${match.tier.name}';
