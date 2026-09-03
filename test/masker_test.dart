import 'package:korean_profanity/korean_profanity.dart';
import 'package:test/test.dart';

void main() {
  test('masks a normalized gap once per original scalar', () {
    final filter = KoreanProfanityFilter();

    expect(filter.mask('씨 11 발'), '******');
    expect(filter.mask('씨 11 발', maskCharacter: '😀'), '😀😀😀😀😀😀');
  });

  test('merges overlapping and touching match ranges', () {
    final filter = KoreanProfanityFilter();

    expect(filter.mask('개fuck새끼'), '개******');
    expect(filter.mask('개새끼'), '***');
  });

  test('rejects empty and multi-scalar mask values', () {
    final filter = KoreanProfanityFilter();

    expect(() => filter.mask('시발', maskCharacter: ''), throwsArgumentError);
    expect(
      () => filter.mask('시발', maskCharacter: '**'),
      throwsArgumentError,
    );
  });
}
