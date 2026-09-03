import 'dart:io';
import 'dart:math';

import 'package:korean_profanity/src/aho_corasick.dart';

void main(List<String> arguments) {
  if (arguments.isNotEmpty) {
    _runFailureCase(arguments.single);
    return;
  }

  const patterns = ['개새끼', '새끼'];
  final overlap = AhoCorasick(patterns).scan('개새끼');
  print('overlap 개새끼 IDs: $overlap');

  final random = Random(0xA110CA5);
  const alphabet = ['가', '나', '다', '😀'];
  for (var round = 0; round < 1000; round++) {
    final dictionary = <String>{};
    final count = random.nextInt(8);
    while (dictionary.length < count) {
      dictionary.add(_word(random, alphabet, random.nextInt(4) + 1));
    }
    final patterns = dictionary.toList();
    final message = _word(random, alphabet, random.nextInt(18));
    final actual = AhoCorasick(patterns).scan(message);
    final expected = _oracle(patterns, message);
    if (!_same(actual, expected)) {
      stderr.writeln('oracle mismatch at round $round');
      exitCode = 1;
      return;
    }
  }
  print('PASS: 1,000 deterministic messages matched oracle');
}

void _runFailureCase(String name) {
  try {
    switch (name) {
      case 'blank':
        AhoCorasick(const ['']);
      case 'duplicate':
        AhoCorasick(const ['중복', '중복']);
      default:
        throw ArgumentError.value(name, 'case', 'expected blank or duplicate');
    }
    stderr.writeln('failure case unexpectedly succeeded');
    exitCode = 1;
  } on ArgumentError catch (error) {
    stderr.writeln('${error.runtimeType}: $error');
    exitCode = 64;
  }
}

String _word(Random random, List<String> alphabet, int length) =>
    List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();

List<int> _oracle(List<String> patterns, String message) {
  final text = message.runes.toList();
  final runes = [for (final pattern in patterns) pattern.runes.toList()];
  return [
    for (var end = 0; end < text.length; end++)
      for (var id = 0; id < runes.length; id++)
        if (_endsWith(text, end, runes[id])) id,
  ];
}

bool _endsWith(List<int> text, int end, List<int> pattern) {
  final start = end - pattern.length + 1;
  if (start < 0) return false;
  for (var index = 0; index < pattern.length; index++) {
    if (text[start + index] != pattern[index]) return false;
  }
  return true;
}

bool _same(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
