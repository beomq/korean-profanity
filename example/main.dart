import 'dart:io';

import 'package:korean_profanity/korean_profanity.dart';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    _printUsage();
    return;
  }

  final input =
      arguments.isEmpty ? stdin.readLineSync() ?? '' : arguments.join(' ');
  final filter = KoreanProfanityFilter();
  final matches = filter.findAll(input);

  stdout.writeln('input=$input');
  stdout.writeln('contains=${matches.isNotEmpty}');
  stdout.writeln('matches=${matches.length}');
  for (final match in matches) {
    stdout.writeln(
      'match=${match.word} range=${match.start}:${match.end} '
      'text=${match.text} tier=${match.tier.name} gap=${match.isGapMatch}',
    );
  }
  stdout.writeln('masked=${filter.mask(input)}');
}

void _printUsage() {
  stdout.writeln('Usage: fvm dart run example/main.dart [text | --help]');
  stdout.writeln('If text is omitted, one line is read from standard input.');
  stdout.writeln('Prints contains, every typed match, and masked text.');
}
