import 'dart:io';

import 'package:korean_profanity/src/aho_corasick.dart';
import 'package:test/test.dart';

void main() {
  test('uses immutable hash transitions instead of binary search', () {
    final source = File('lib/src/aho_corasick.dart').readAsStringSync();

    expect(source, contains('final List<Map<int, int>> _transitions;'));
    expect(source, contains('_transitions[state][scalar]'));
    expect(source, contains('List<Map<int, int>>.unmodifiable'));
    expect(source, contains('Map<int, int>.unmodifiable(node.edges)'));
    expect(source, isNot(contains('_nodeEdgeStart')));
    expect(source, isNot(contains('_edgeScalar')));
    expect(source, isNot(contains('while (low <= high)')));
  });

  test('looks up a wide immutable root transition table exactly', () {
    final patterns = [
      for (var scalar = 0x1000; scalar < 0x1400; scalar++)
        String.fromCharCode(scalar),
      '😀한',
    ];
    final automaton = AhoCorasick(patterns);

    expect(automaton.scan('${String.fromCharCode(0x13ff)}😀한'), [1023, 1024]);
    expect(automaton.scan('unmatched'), isEmpty);
    expect(automaton.scan('${String.fromCharCode(0x13ff)}😀한'), [1023, 1024]);
  });
}
