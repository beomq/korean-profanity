import 'dart:math';

import 'package:korean_profanity/src/aho_corasick.dart';
import 'package:test/test.dart';

void main() {
  group('AhoCorasick', () {
    test('emits overlapping pattern IDs and scalar end positions', () {
      final automaton = AhoCorasick(const ['개새끼', '새끼', '끼', '개']);

      expect(automaton.scan('개새끼'), [3, 0, 1, 2]);
      expect(
        automaton.scanHits('개새끼'),
        const [
          AhoHit(patternId: 3, end: 1),
          AhoHit(patternId: 0, end: 3),
          AhoHit(patternId: 1, end: 3),
          AhoHit(patternId: 2, end: 3),
        ],
      );
      expect(automaton.scan('개새끼새끼'), [3, 0, 1, 2, 1, 2]);
    });

    test('matches Unicode scalars rather than UTF-16 code units', () {
      final automaton = AhoCorasick(const ['😀', '😀한', '한']);

      expect(automaton.scan('x😀한😀'), [0, 1, 2, 0]);
      expect(
        automaton.scanHits('x😀한😀'),
        const [
          AhoHit(patternId: 0, end: 2),
          AhoHit(patternId: 1, end: 3),
          AhoHit(patternId: 2, end: 3),
          AhoHit(patternId: 0, end: 4),
        ],
      );
    });

    test('supports empty dictionaries and reusable immutable scans', () {
      final empty = AhoCorasick(const []);
      final automaton = AhoCorasick(const ['aba', 'ba']);

      expect(empty.scan('anything'), isEmpty);
      expect(automaton.scan('aba'), [0, 1]);
      expect(automaton.scan('unrelated'), isEmpty);
      expect(automaton.scan('aba'), [0, 1]);
    });

    test('rejects malformed patterns with ArgumentError', () {
      expect(() => AhoCorasick(const ['']), throwsArgumentError);
      expect(() => AhoCorasick(const ['same', 'same']), throwsArgumentError);
    });

    test('matches a fixed-seed differential oracle exactly', () {
      final random = Random(0xA110CA5);
      const alphabet = <String>['가', '나', '다', '😀'];

      for (var round = 0; round < 1000; round++) {
        final patterns = _patterns(random, alphabet);
        final message = _word(random, alphabet, random.nextInt(18));
        expect(
          AhoCorasick(patterns).scan(message),
          _oracle(patterns, message),
          reason: 'round=$round patterns=$patterns message=$message',
        );
      }
    });

    test('handles dense overlapping output without hanging', () {
      final patterns = [
        for (var length = 1; length <= 64; length++) '가' * length
      ];
      final matches = AhoCorasick(patterns).scan('가' * 128);

      expect(matches, hasLength(6176));
      expect(matches.take(3), [0, 0, 1]);
    });
  });
}

List<String> _patterns(Random random, List<String> alphabet) {
  final count = random.nextInt(8);
  final patterns = <String>{};
  while (patterns.length < count) {
    patterns.add(_word(random, alphabet, random.nextInt(4) + 1));
  }
  return patterns.toList();
}

String _word(Random random, List<String> alphabet, int length) =>
    List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();

List<int> _oracle(List<String> patterns, String message) {
  final text = message.runes.toList();
  final patternRunes = [for (final pattern in patterns) pattern.runes.toList()];
  final result = <int>[];
  for (var end = 0; end < text.length; end++) {
    for (var id = 0; id < patternRunes.length; id++) {
      final pattern = patternRunes[id];
      final start = end - pattern.length + 1;
      if (start >= 0 && _equalsAt(text, start, pattern)) result.add(id);
    }
  }
  return result;
}

bool _equalsAt(List<int> text, int start, List<int> pattern) {
  for (var index = 0; index < pattern.length; index++) {
    if (text[start + index] != pattern[index]) return false;
  }
  return true;
}
