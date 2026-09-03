import 'dart:io';

import 'package:korean_profanity/korean_profanity.dart';
import 'package:korean_profanity/src/generated/dictionary_lenient_data.g.dart';
import 'package:korean_profanity/src/generated/dictionary_strict_data.g.dart';
import 'package:test/test.dart';

part 'generator_test_support.dart';

void main() {
  late Directory fixture;

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('korean_dictionary_test_');
  });

  tearDown(() {
    fixture.deleteSync(recursive: true);
  });

  test('accepts BOM/CRLF input and emits deterministic sorted data', () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '\uFEFFpattern,canonical,tier,match_mode,source_id,note\r\n'
          '씨발,씨발,strict,substring,licensed,core\r\n'
          '개새끼,개새끼,strict,substring,licensed,core\r\n'
          '시간,시간,allow,substring,licensed,ordinary word\r\n',
    );

    expect(result.exitCode, 0, reason: result.stderr as String);
    final generatedDirectory = Directory('${fixture.path}/generated');
    expect(
      generatedDirectory
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet(),
      <String>{
        'dictionary_version.g.dart',
        'dictionary_strict_data.g.dart',
        'dictionary_lenient_data.g.dart',
      },
    );
    final generated = File(
      '${generatedDirectory.path}/dictionary_strict_data.g.dart',
    ).readAsStringSync();
    expect(
      generated.indexOf('"개새끼"'),
      lessThan(generated.indexOf('"씨발"')),
    );
    expect(generated, contains('generatedStrictSubstringWords'));
    expect(
      result.stdout,
      allOf(
        contains('source counts:'),
        contains('tier counts:'),
        contains('mode counts:'),
      ),
    );

    final first = _generatedBytes(fixture);
    final second = await _runGenerator(fixture);
    expect(second.exitCode, 0, reason: second.stderr as String);
    expect(_generatedBytes(fixture), first);
  });

  test('rejects invalid quote placement with a row-numbered diagnostic',
      () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '$_header"시발"junk,시발,strict,substring,licensed,bad quote\n',
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('row 2: invalid quote placement'));
  });

  test('rejects unterminated quoted fields', () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '$_header"시발,시발,strict,substring,licensed,unterminated\n',
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('row 2: unterminated CSV quote'));
  });

  test('rejects a duplicate with row-numbered diagnostics', () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '$_validDictionary'
          '시발,시발,strict,substring,licensed,duplicate\n',
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('row 3: duplicate pattern'));
  });

  test('rejects unsupported Han text instead of silently filtering it',
      () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '$_header人民,人民,lenient,substring,licensed,bad script\n',
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('row 2: unsupported script'));
  });

  test('rejects missing and unknown source provenance', () async {
    for (final row in <String>[
      '시발,시발,strict,substring,,missing\n',
      '시발,시발,strict,substring,absent,unknown\n',
    ]) {
      final result = await _runGenerator(fixture, dictionary: _header + row);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('row 2:'));
      expect(result.stderr, contains('source_id'));
    }
  });

  test('rejects blank rows and malformed tier/mode values', () async {
    for (final entry in <({String row, String diagnostic})>[
      (row: '\n', diagnostic: 'blank row'),
      (
        row: '시발,시발,severe,substring,licensed,bad tier\n',
        diagnostic: 'invalid tier',
      ),
      (
        row: '시발,시발,strict,regex,licensed,bad mode\n',
        diagnostic: 'invalid match_mode',
      ),
    ]) {
      final result = await _runGenerator(
        fixture,
        dictionary:
            '$_header${entry.row}씨발,씨발,strict,substring,licensed,tail\n',
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('row 2: ${entry.diagnostic}'));
    }
  });

  test('rejects unauthorized Tanat strict exceptions', () async {
    for (final entry in <({String row, String diagnostic})>[
      (
        row: '기타,기타,strict,substring,tanat_fixture,project_contract\n',
        diagnostic: 'Tanat-only entries default to lenient',
      ),
      (
        row: '수간,수간,strict,substring,tanat_fixture,reviewed\n',
        diagnostic: 'strict Tanat exception requires note project_contract',
      ),
    ]) {
      final result = await _runGenerator(
        fixture,
        dictionary: _header + entry.row,
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('row 2: ${entry.diagnostic}'));
    }
  });

  test('rejects cross-tier pattern collisions', () async {
    final result = await _runGenerator(
      fixture,
      dictionary: '$_validDictionary'
          '시발,시발,lenient,substring,licensed,conflict\n',
    );
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('row 3: cross-tier collision'));
  });

  test('--check detects stale output without replacing it', () async {
    expect((await _runGenerator(fixture)).exitCode, 0);
    final output = File(
      '${fixture.path}/generated/dictionary_strict_data.g.dart',
    );
    output.writeAsStringSync('// stale\n');

    final result = await _runGenerator(fixture, check: true);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('stale generated output'));
    expect(output.readAsStringSync(), '// stale\n');
  });

  test('only six Tanat strict rows use the project contract exception', () {
    final rows = File('data/dictionary.csv')
        .readAsLinesSync()
        .skip(1)
        .map((line) => line.split(','))
        .where(
            (fields) => fields[2] == 'strict' && fields[4].startsWith('tanat'))
        .toList();
    expect(
      rows.map((fields) => fields[0]).toSet(),
      <String>{'수간', '10새끼', '18넘', '10jil', 'fuck', 'ass'},
    );
    expect(
        rows,
        everyElement(predicate<List<String>>(
            (fields) => fields[5] == 'project_contract')));
  });

  test('checked-in dictionary contains the reviewed contract entries', () {
    expect(dictionaryVersion, matches(RegExp(r'^[0-9a-f]{12}$')));
    expect(generatedStrictSubstringWords['시발'], '시발');
    expect(generatedStrictLiteralWords['10새끼'], '10새끼');
    expect(generatedStrictAsciiWordWords['fuck'], 'fuck');
    expect(generatedLenientSubstringWords.keys,
        containsAll(<String>['관장', '토토', '오랄']));
    expect(generatedLenientChoseongWords['ㅅㅂ'], '시발');
    expect(generatedAllowSubstringWords['시간'], '시간');
    expect(
      generatedSourceCounts.values.fold<int>(0, (sum, count) => sum + count),
      generatedTierCounts.values.fold<int>(0, (sum, count) => sum + count),
    );
  });

  test('--help documents write, check, and fixture paths', () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/generate_dictionary.dart', '--help'],
    );
    expect(result.exitCode, 0);
    expect(
      result.stdout,
      allOf(
        contains('write'),
        contains('--check'),
        contains('--dictionary'),
        contains('--sources'),
      ),
    );
  });
}
