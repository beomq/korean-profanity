import 'package:korean_profanity/korean_profanity.dart';

void main() {
  final filter = KoreanProfanityFilter();
  const gapText = '씨 11 발';
  final match = filter.findAll(gapText).single;

  print('direct=${filter.contains('씨1발')}');
  print('gap=${filter.contains(gapText)}');
  print(
    'match=start:${match.start},end:${match.end},text:${match.text},'
    'word:${match.word},tier:${match.tier.name},gap:${match.isGapMatch}',
  );
  print('mask=${filter.mask(gapText)}');
  print(
    'added=${KoreanProfanityFilter(addedWords: const [
          '우리회사욕'
        ]).contains('우리회사욕')}',
  );
  print(
    'removed=${KoreanProfanityFilter(removedWords: const [
          '시발'
        ]).contains('시발')}',
  );
  print(
    'ignored=${KoreanProfanityFilter(ignoreWords: const [
          '시발점'
        ]).contains('시발점')}',
  );
  print('choseongDefault=${filter.contains('수박')}');
  print(
    'choseongOptIn=${KoreanProfanityFilter(minimumTier: ProfanityTier.lenient, choseongSearch: true).contains('수박')}',
  );
  _printInvalidMask(filter, '', 'invalidEmpty');
  _printInvalidMask(filter, '**', 'invalidMulti');
}

void _printInvalidMask(
  KoreanProfanityFilter filter,
  String maskCharacter,
  String label,
) {
  try {
    filter.mask('시발', maskCharacter: maskCharacter);
    print('$label=accepted');
  } on ArgumentError {
    print('$label=ArgumentError');
  }
}
