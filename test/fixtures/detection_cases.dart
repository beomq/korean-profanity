import 'package:korean_profanity/korean_profanity.dart';

final class ExpectedDetection {
  const ExpectedDetection(
    this.start,
    this.end,
    this.word, {
    this.tier = ProfanityTier.strict,
    this.gap = false,
  });

  final int start;
  final int end;
  final String word;
  final ProfanityTier tier;
  final bool gap;
}

final class DetectionCase {
  const DetectionCase(
    this.id,
    this.input,
    this.normalization,
    this.matches,
    this.mask, {
    this.includeLenient = false,
    this.minimumTier = ProfanityTier.strict,
    this.choseong = false,
    this.added = const <String>[],
    this.removed = const <String>[],
    this.ignored = const <String>[],
    this.barrierIndices = const <int>[],
  });

  final int id;
  final String input;
  final String normalization;
  final List<ExpectedDetection> matches;
  final String mask;
  final bool includeLenient;
  final ProfanityTier minimumTier;
  final bool choseong;
  final List<String> added;
  final List<String> removed;
  final List<String> ignored;
  final List<int> barrierIndices;
}

const detectionCases = <DetectionCase>[
  DetectionCase(1, '시발', '시발', [ExpectedDetection(0, 2, '시발')], '**'),
  DetectionCase(2, '이런 시발', '이런시발', [ExpectedDetection(3, 5, '시발')], '이런 **'),
  DetectionCase(
      3, '시 발', '시발', [ExpectedDetection(0, 3, '시발', gap: true)], '***'),
  DetectionCase(
      4, '시.발', '시발', [ExpectedDetection(0, 3, '시발', gap: true)], '***'),
  DetectionCase(
      5, '시 . 발', '시발', [ExpectedDetection(0, 5, '시발', gap: true)], '*****'),
  DetectionCase(6, '시\n발', '시\n발', [], '시\n발', barrierIndices: [1]),
  DetectionCase(7, '시😀발', '시😀발', [], '시😀발', barrierIndices: [1]),
  DetectionCase(
      8, '씨1발', '씨발', [ExpectedDetection(0, 3, '씨발', gap: true)], '***'),
  DetectionCase(
      9, '씨11발', '씨발', [ExpectedDetection(0, 4, '씨발', gap: true)], '****'),
  DetectionCase(
      10, '씨 11 발', '씨발', [ExpectedDetection(0, 6, '씨발', gap: true)], '******'),
  DetectionCase(
      11, '씨.1.발', '씨발', [ExpectedDetection(0, 5, '씨발', gap: true)], '*****'),
  DetectionCase(
      12, '병1신', '병신', [ExpectedDetection(0, 3, '병신', gap: true)], '***'),
  DetectionCase(13, '1시간', '1시간', [], '1시간'),
  DetectionCase(14, '3발 슛', '3발슛', [], '3발 슛'),
  DetectionCase(15, '10새끼', '10새끼', [ExpectedDetection(0, 4, '10새끼')], '****'),
  DetectionCase(16, '18넘', '18넘', [ExpectedDetection(0, 3, '18넘')], '***'),
  DetectionCase(
      17, '10JIL', '10jil', [ExpectedDetection(0, 5, '10jil')], '*****'),
  DetectionCase(18, 'ㅅㅂ', 'ㅅㅂ', [ExpectedDetection(0, 2, '시발')], '**'),
  DetectionCase(
      19, 'ㅅ . ㅂ', 'ㅅㅂ', [ExpectedDetection(0, 5, '시발', gap: true)], '*****'),
  DetectionCase(20, '수박', '수박', [], '수박'),
  DetectionCase(21, '수박', '수박',
      [ExpectedDetection(0, 2, '시발', tier: ProfanityTier.lenient)], '**',
      choseong: true, minimumTier: ProfanityTier.lenient),
  DetectionCase(22, '시발', '시발', [ExpectedDetection(0, 5, '시발')], '*****'),
  DetectionCase(23, '쉬발', '쉬발', [ExpectedDetection(0, 2, '시발')], '**'),
  DetectionCase(24, '씌발', '씌발', [ExpectedDetection(0, 2, '시발')], '**'),
  DetectionCase(25, '씨빨', '씨빨', [ExpectedDetection(0, 2, '씨발')], '**'),
  DetectionCase(26, '^^ㅣ발', '^^ㅣ발', [ExpectedDetection(0, 4, '시발')], '****'),
  DetectionCase(27, 'fuck', 'fuck', [ExpectedDetection(0, 4, 'fuck')], '****'),
  DetectionCase(28, 'FuCk', 'fuck', [ExpectedDetection(0, 4, 'fuck')], '****'),
  DetectionCase(29, 'ｆｕｃｋ', 'fuck', [ExpectedDetection(0, 4, 'fuck')], '****'),
  DetectionCase(30, '정말 fuck!', '정말 fuck!', [ExpectedDetection(3, 7, 'fuck')],
      '정말 ****!'),
  DetectionCase(31, 'ass!', 'ass!', [ExpectedDetection(0, 3, 'ass')], '***!'),
  DetectionCase(32, 'class', 'class', [], 'class'),
  DetectionCase(33, 'assistant', 'assistant', [], 'assistant'),
  DetectionCase(34, 'Essex', 'essex', [], 'Essex'),
  DetectionCase(35, 'fuck123', 'fuck123', [], 'fuck123'),
  DetectionCase(
      36,
      '개fuck새끼',
      '개fuck새끼',
      [ExpectedDetection(1, 5, 'fuck'), ExpectedDetection(5, 7, '새끼')],
      '개******'),
  DetectionCase(37, '개새끼', '개새끼',
      [ExpectedDetection(0, 3, '개새끼'), ExpectedDetection(1, 3, '새끼')], '***'),
  DetectionCase(
      38,
      '이런 개새끼야',
      '이런개새끼야',
      [ExpectedDetection(3, 6, '개새끼'), ExpectedDetection(4, 6, '새끼')],
      '이런 ***야'),
  DetectionCase(
      39,
      '개새끼123',
      '개새끼123',
      [ExpectedDetection(0, 3, '개새끼'), ExpectedDetection(1, 3, '새끼')],
      '***123'),
  DetectionCase(40, '새끼', '새끼', [ExpectedDetection(0, 2, '새끼')], '**'),
  DetectionCase(41, '시간이 없다', '시간이없다', [], '시간이 없다'),
  DetectionCase(42, '시발점', '시발점', [ExpectedDetection(0, 2, '시발')], '**점'),
  DetectionCase(43, '시발점', '시발점', [], '시발점', ignored: ['시발점']),
  DetectionCase(44, '개새끼', '개새끼', [ExpectedDetection(0, 3, '개새끼')], '***',
      ignored: ['새끼']),
  DetectionCase(45, '수간', '수간', [ExpectedDetection(0, 2, '수간')], '**'),
  DetectionCase(46, '관장님 오셨다', '관장님오셨다', [], '관장님 오셨다'),
  DetectionCase(47, '토토 하자', '토토하자', [], '토토 하자'),
  DetectionCase(48, '토토 하자', '토토하자',
      [ExpectedDetection(0, 2, '토토', tier: ProfanityTier.lenient)], '** 하자',
      includeLenient: true, minimumTier: ProfanityTier.lenient),
  DetectionCase(49, '오랄', '오랄', [], '오랄'),
  DetectionCase(50, '오랄', '오랄',
      [ExpectedDetection(0, 2, '오랄', tier: ProfanityTier.lenient)], '**',
      includeLenient: true, minimumTier: ProfanityTier.lenient),
  DetectionCase(51, '', '', [], ''),
  DetectionCase(52, '😀🎉', '😀🎉', [], '😀🎉', barrierIndices: [0, 1]),
  DetectionCase(53, 'ㅋㅋㅋㅋㅋㅋ', 'ㅋㅋㅋㅋㅋㅋ', [], 'ㅋㅋㅋㅋㅋㅋ'),
  DetectionCase(54, 'a.s.s', 'a.s.s', [], 'a.s.s'),
  DetectionCase(
      55, '시, 발', '시발', [ExpectedDetection(0, 4, '시발', gap: true)], '****'),
  DetectionCase(
      56, '우리회사욕', '우리회사욕', [ExpectedDetection(0, 5, '우리회사욕')], '*****',
      added: ['우리회사욕']),
  DetectionCase(57, '시발', '시발', [], '시발', removed: ['시발']),
  DetectionCase(58, '시\u200B발', '시\u200B발', [], '시\u200B발',
      barrierIndices: [1]),
];
