import 'package:korean_profanity/src/normalized_text.dart';
import 'package:korean_profanity/src/normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('canonical normalization', () {
    final cases = <({String name, String input, String canonical})>[
      (name: 'empty', input: '', canonical: ''),
      (name: 'precomposed Hangul', input: '시발', canonical: '시발'),
      (name: 'conjoining LV', input: '가', canonical: '가'),
      (name: 'conjoining LVT', input: '각', canonical: '각'),
      (name: 'compatibility LV', input: 'ㄱㅏ', canonical: '가'),
      (name: 'compatibility LVT', input: 'ㄱㅏㄱ', canonical: '각'),
      (name: 'halfwidth LV', input: 'ﾡￂ', canonical: '가'),
      (name: 'halfwidth LVT', input: 'ﾡￂﾡ', canonical: '각'),
      (name: 'ambiguous next leading', input: 'ㄱㅏㄴㅏ', canonical: '가나'),
      (name: 'ASCII lowercase', input: 'FuCk', canonical: 'fuck'),
      (name: 'fullwidth ASCII', input: 'ｆｕｃｋ！', canonical: 'fuck!'),
      (name: 'ideographic space', input: 'A　B', canonical: 'a b'),
      (name: 'supplementary scalar', input: '😀', canonical: '😀'),
      (name: 'isolated digit', input: '１시간', canonical: '1시간'),
      (name: 'incomplete leading', input: 'ᄀ', canonical: 'ᄀ'),
      (name: 'incomplete vowel', input: 'ᅡ', canonical: 'ᅡ'),
      (name: 'invalid compatibility cluster', input: 'ㄳ', canonical: 'ㄳ'),
      (name: 'archaic leading', input: 'ᄔᅡ', canonical: 'ᄔᅡ'),
      (name: 'non-ASCII case unchanged', input: 'Äİ', canonical: 'Äİ'),
      (name: 'symbols only', input: '😀🎉', canonical: '😀🎉'),
    ];

    for (final entry in cases) {
      test(entry.name, () {
        expect(normalizeText(entry.input).canonical, entry.canonical);
      });
    }

    test('does not steal a consonant from the next syllable', () {
      expect(normalizeText('ㄱㅏㄴㅏ').canonicalCodePoints, [0xac00, 0xb098]);
    });

    test('preserves unpaired surrogate code units without throwing', () {
      final high = String.fromCharCode(0xd800);
      final low = String.fromCharCode(0xdc00);
      expect(normalizeText('$high-$low').canonical.codeUnits, [
        0xd800,
        0x2d,
        0xdc00,
      ]);
    });
  });

  group('UTF-16 source spans', () {
    final cases = <({String input, String canonical, List<(int, int)> spans})>[
      (input: '시발', canonical: '시발', spans: [(0, 1), (1, 2)]),
      (input: '시발', canonical: '시발', spans: [(0, 2), (2, 5)]),
      (input: 'ㅅㅣㅂㅏㄹ', canonical: '시발', spans: [(0, 2), (2, 5)]),
      (input: 'ﾵￜﾲￂﾩ', canonical: '시발', spans: [(0, 2), (2, 5)]),
      (input: '시😀발', canonical: '시😀발', spans: [(0, 1), (1, 3), (3, 4)]),
      (input: 'Ａ', canonical: 'a', spans: [(0, 1)]),
    ];

    for (final entry in cases) {
      test('maps ${entry.input.runes.map(_hex).join(' ')}', () {
        final normalized = normalizeText(entry.input);
        expect(normalized.canonical, entry.canonical);
        expect(
          normalized.canonicalScalars.map((s) => (s.start, s.end)),
          entry.spans,
        );
      });
    }

    test('a mapped range never splits a supplementary scalar', () {
      final normalized = normalizeText('a😀b');
      expect(normalized.sourceSpan(1, 2), const NormalizedSpan(1, 3, false));
      expect(normalized.original.substring(1, 3), '😀');
    });
  });

  group('Hangul-internal gaps', () {
    final removable = <({String input, String canonical, int end})>[
      (input: '씨1발', canonical: '씨발', end: 3),
      (input: '씨11발', canonical: '씨발', end: 4),
      (input: '씨 1 발', canonical: '씨발', end: 5),
      (input: '씨 11 발', canonical: '씨발', end: 6),
      (input: '씨.1.발', canonical: '씨발', end: 5),
      (input: '시, 발', canonical: '시발', end: 4),
      (input: '시-발', canonical: '시발', end: 3),
      (input: '시+발', canonical: '시발', end: 3),
      (input: '시·발', canonical: '시발', end: 3),
      (input: '시₩발', canonical: '시발', end: 3),
      (input: '시©발', canonical: '시발', end: 3),
      (input: '시—발', canonical: '시발', end: 3),
      (input: 'ㅅ . ㅂ', canonical: 'ㅅㅂ', end: 5),
    ];

    for (final entry in removable) {
      test('removes ${entry.input}', () {
        final normalized = normalizeText(entry.input);
        expect(normalized.canonical, entry.canonical);
        expect(
          normalized.sourceSpan(0, normalized.canonicalScalars.length),
          NormalizedSpan(0, entry.end, true),
        );
        expect(normalized.canonicalScalars.last.isGapBefore, isTrue);
      });
    }

    final barriers = <String>[
      '시\n발',
      '시\r발',
      '시\u2028발',
      '시\u2029발',
      '시😀발',
      '시❤발',
      '시\u00AD발',
      '시\u200B발',
      '시\u200C발',
      '시\u200D발',
      '시\u2060발',
    ];
    for (final input in barriers) {
      test('keeps barrier ${input.runes.map(_hex).join(' ')}', () {
        final normalized = normalizeText(input);
        expect(normalized.canonical, input);
        expect(normalized.canonical, isNot('시발'));
        expect(
          normalized.sourceSpan(0, normalized.canonicalScalars.length).isGap,
          isFalse,
        );
      });
    }

    test('requires Hangul on both sides', () {
      expect(normalizeText('1 시간').canonical, '1 시간');
      expect(normalizeText('시간 1').canonical, '시간 1');
      expect(normalizeText('a.시').canonical, 'a.시');
      expect(normalizeText('시.a').canonical, '시.a');
    });
  });

  group('choseong stream', () {
    test('derives initials while retaining canonical direct jamo', () {
      final normalized = normalizeText('수박 ㅅㅂ');
      expect(normalized.canonical, '수박ㅅㅂ');
      expect(normalized.choseong, 'ㅅㅂㅅㅂ');
    });

    test('retains source spans and gap edges', () {
      final normalized = normalizeText('시 . 발');
      expect(normalized.canonical, '시발');
      expect(normalized.choseong, 'ㅅㅂ');
      expect(
        normalized.sourceSpan(0, 2, choseong: true),
        const NormalizedSpan(0, 8, true),
      );
    });
  });
}

String _hex(int value) => 'U+${value.toRadixString(16).toUpperCase()}';
