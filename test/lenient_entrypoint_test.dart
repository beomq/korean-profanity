import 'package:korean_profanity/korean_profanity.dart' as strict;
import 'package:korean_profanity/korean_profanity_lenient.dart' as lenient;
import 'package:test/test.dart';

void main() {
  late lenient.KoreanProfanityFilter lenientFilter;

  setUp(() {
    lenientFilter = lenient.KoreanProfanityFilter(
      dictionary: lenient.koreanLenientDictionary,
      minimumTier: lenient.ProfanityTier.lenient,
    );
  });

  test('optional dictionary is cached and is a strict superset', () {
    final strictFilter = strict.KoreanProfanityFilter();

    expect(
      identical(
        lenient.koreanLenientDictionary,
        lenient.koreanLenientDictionary,
      ),
      isTrue,
    );
    expect(strictFilter.contains('토토'), isFalse);
    expect(lenientFilter.contains('토토'), isTrue);
    expect(strictFilter.contains('씨 11 발'), isTrue);
    expect(lenientFilter.contains('씨 11 발'), isTrue);
    expect(
      lenientFilter.findAll('토토').single.tier,
      lenient.ProfanityTier.lenient,
    );
  });

  test('preserves ASCII word boundaries', () {
    expect(lenientFilter.contains('class'), isFalse);
  });

  test('preserves literal dominance and canonical mappings', () {
    expect(lenientFilter.findAll('쉬발').single.word, '시발');
    expect(
      lenientFilter.findAll('10새끼').map((match) => match.word),
      <String>['10새끼'],
    );
  });

  test('preserves choseong metadata', () {
    final choseongFilter = lenient.KoreanProfanityFilter(
      dictionary: lenient.koreanLenientDictionary,
      minimumTier: lenient.ProfanityTier.lenient,
      choseongSearch: true,
    );
    final match = choseongFilter.findAll('수박').single;

    expect(match.word, '시발');
    expect(match.tier, lenient.ProfanityTier.lenient);
  });
}
