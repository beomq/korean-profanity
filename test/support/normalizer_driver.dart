import 'package:korean_profanity/src/normalizer.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    throw ArgumentError('expected exactly one input argument');
  }

  final normalized = normalizeText(arguments.single);
  final span = normalized.sourceSpan(0, normalized.canonicalScalars.length);
  var barrierNoJoin = false;
  for (var index = 1; index + 1 < normalized.canonicalScalars.length; index++) {
    final scalars = normalized.canonicalScalars;
    if (!scalars[index].isHangulLike &&
        scalars[index - 1].isHangulLike &&
        scalars[index + 1].isHangulLike) {
      barrierNoJoin = true;
    }
  }

  print('normalized=${normalized.canonical}');
  print('original span=[${span.start},${span.end})');
  print('gap=${span.isGap}');
  print('barrier/no-join=$barrierNoJoin');
}
