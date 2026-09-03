import 'package:korean_profanity/korean_profanity.dart';
import 'package:test/test.dart';

void main() {
  test('exposes the exact typed public API contract', () {
    final ProfanityDictionary dictionary = ProfanityDictionary(
      strictWords: const <String>['strict'],
      lenientWords: const <String>['lenient'],
      allowWords: const <String>['allowed'],
      choseongPatterns: const <String>['ㅅㅂ'],
    );
    final KoreanProfanityFilter filter = KoreanProfanityFilter(
      dictionary: dictionary,
      minimumTier: ProfanityTier.strict,
      addedWords: const <String>['added'],
      removedWords: const <String>['removed'],
      ignoreWords: const <String>['ignored'],
      choseongSearch: false,
    );
    const ProfanityMatch match = ProfanityMatch(
      start: 0,
      end: 2,
      text: 'text',
      word: 'word',
      tier: ProfanityTier.lenient,
      isGapMatch: false,
    );

    final bool contains = filter.contains('added');
    final List<ProfanityMatch> foundMatches = filter.findAll('added');
    final String masked = filter.mask('added');
    final int start = match.start;
    final int end = match.end;
    final String text = match.text;
    final String word = match.word;
    final ProfanityTier tier = match.tier;
    final bool isGapMatch = match.isGapMatch;
    final String version = dictionaryVersion;

    expect(contains, isTrue);
    expect(foundMatches.single.word, 'added');
    expect(masked, '*****');
    expect([start, end, text, word, tier, isGapMatch], hasLength(6));
    expect(version, matches(RegExp(r'^[0-9a-f]{12}$')));
  });
}
