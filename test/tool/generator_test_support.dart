part of 'generate_dictionary_test.dart';

const _header = 'pattern,canonical,tier,match_mode,source_id,note\n';
const _validDictionary = '$_header시발,시발,strict,substring,licensed,core\n';

const _sources = '''sources:
  - id: licensed
    repository: https://example.invalid/repository
    commit: 0123456789abcdef0123456789abcdef01234567
    path: words.txt
    retrieved: 2026-09-03
    license: MIT
    sha256: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  - id: tanat_fixture
    repository: https://example.invalid/tanat
    commit: 0123456789abcdef0123456789abcdef01234567
    path: words.txt
    retrieved: 2026-09-03
    license: UNKNOWN
    sha256: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
''';

Future<ProcessResult> _runGenerator(
  Directory fixture, {
  String? dictionary,
  bool check = false,
}) {
  final dictionaryFile = File('${fixture.path}/dictionary.csv');
  final sourcesFile = File('${fixture.path}/sources.yaml');
  if (dictionary != null || !dictionaryFile.existsSync()) {
    dictionaryFile.writeAsStringSync(dictionary ?? _validDictionary);
  }
  sourcesFile.writeAsStringSync(_sources);
  return Process.run(
    Platform.resolvedExecutable,
    <String>[
      'run',
      'tool/generate_dictionary.dart',
      if (check) '--check',
      '--dictionary',
      dictionaryFile.path,
      '--sources',
      sourcesFile.path,
      '--output',
      '${fixture.path}/generated',
    ],
  );
}

List<int> _generatedBytes(Directory fixture) {
  final files = Directory('${fixture.path}/generated')
      .listSync()
      .whereType<File>()
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return <int>[
    for (final file in files) ...file.readAsBytesSync(),
  ];
}
