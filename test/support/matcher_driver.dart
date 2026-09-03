import 'dart:io';

import 'package:korean_profanity/src/profanity_matcher.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('usage: matcher_driver.dart <text>');
    exitCode = 64;
    return;
  }

  final text = arguments.single;
  final matcher = ProfanityMatcher();
  final matches = matcher.findAll(text);
  if (matches.isEmpty) {
    print('contains=false, mask=${matcher.mask(text)}');
    return;
  }

  final match = matches.first;
  print(
    'contains=true, word=${match.word}, span=[${match.start},${match.end}), '
    'gap=${match.isGapMatch}, mask=${matcher.mask(text)}',
  );
}
