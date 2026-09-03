import 'dart:io';

import 'package:korean_profanity/korean_profanity_lenient.dart';
import 'package:korean_profanity/src/generated/dictionary_lenient_data.g.dart';
import 'package:korean_profanity/src/generated/dictionary_strict_data.g.dart';

var _sink = 0;

void main() {
  print(
      'Dart ${Platform.version.split(' ').first} on ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}; ${Platform.numberOfProcessors} CPUs');
  _printNodeObservations();
  for (final count in const <int>[10, 100, 1000]) {
    _construction('strict-construction', count, () => KoreanProfanityFilter());
    _construction(
      'lenient-construction',
      count,
      () => KoreanProfanityFilter(
        dictionary: koreanLenientDictionary,
        minimumTier: ProfanityTier.lenient,
      ),
    );
    _profile('strict', KoreanProfanityFilter(), count);
    _profile(
      'lenient',
      KoreanProfanityFilter(
        dictionary: koreanLenientDictionary,
        minimumTier: ProfanityTier.lenient,
      ),
      count,
    );
  }
  print('checksum=$_sink');
  print('Reported timings are observational; no timing threshold applied.');
}

void _printNodeObservations() {
  final strict = <String>{
    ...generatedStrictSubstringWords.keys,
    ...generatedStrictAsciiWordWords.keys,
    ...generatedStrictLiteralWords.keys,
  };
  final lenient = <String>{
    ...strict,
    ...generatedLenientSubstringWords.keys,
    ...generatedLenientAsciiWordWords.keys,
    ...generatedLenientLiteralWords.keys,
  };
  final allow = <String>{
    ...generatedAllowSubstringWords.keys,
    ...generatedAllowAsciiWordWords.keys,
    ...generatedAllowLiteralWords.keys,
  };
  final choseong = <String>{
    ...generatedStrictChoseongWords.keys,
    ...generatedLenientChoseongWords.keys,
  };
  print('automaton-nodes strict=${_trieNodes(strict)} '
      'lenient=${_trieNodes(lenient)} allow=${_trieNodes(allow)} '
      'choseong=${_trieNodes(choseong)}');
}

int _trieNodes(Iterable<String> patterns) {
  final prefixes = <String>{};
  for (final pattern in patterns) {
    final prefix = <int>[];
    for (final scalar in pattern.runes) {
      prefix.add(scalar);
      prefixes.add(String.fromCharCodes(prefix));
    }
  }
  return prefixes.length + 1;
}

void _construction(
  String name,
  int count,
  KoreanProfanityFilter Function() create,
) {
  final stopwatch = Stopwatch()..start();
  for (var index = 0; index < count; index++) {
    _sink ^= create().contains('clean') ? 1 : 0;
  }
  stopwatch.stop();
  _print(name, count, stopwatch.elapsedMicroseconds);
}

void _profile(String profile, KoreanProfanityFilter filter, int count) {
  const workloads = <String, String>{
    'no-hit': '오늘은 맑고 평온한 날입니다',
    'one-hit': '문장 끝에 시발',
    'dense-hit': '시발 개새끼 씨발 병신 새끼',
    'evasion-gap': '씨 11 발',
  };
  for (final workload in workloads.entries) {
    filter.contains(workload.value);
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < count; index++) {
      _sink += filter.findAll(workload.value).length;
    }
    stopwatch.stop();
    _print('$profile-${workload.key}', count, stopwatch.elapsedMicroseconds);
  }
}

void _print(String name, int count, int microseconds) {
  print('$name messages=$count elapsed_us=$microseconds');
}
