final class GeneratorOptions {
  const GeneratorOptions({
    required this.check,
    required this.help,
    required this.dictionaryPath,
    required this.sourcesPath,
    required this.outputPath,
  });

  final bool check;
  final bool help;
  final String dictionaryPath;
  final String sourcesPath;
  final String outputPath;

  static GeneratorOptions parse(List<String> arguments) {
    var check = false;
    var help = false;
    var dictionary = 'data/dictionary.csv';
    var sources = 'data/sources.yaml';
    var output = 'lib/src/generated';
    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--check':
          check = true;
        case '--write':
          check = false;
        case '--help':
        case '-h':
          help = true;
        case '--dictionary':
          dictionary = _value(arguments, ++index, '--dictionary');
        case '--sources':
          sources = _value(arguments, ++index, '--sources');
        case '--output':
          output = _value(arguments, ++index, '--output');
        default:
          throw FormatException('unknown option ${arguments[index]}');
      }
    }
    return GeneratorOptions(
      check: check,
      help: help,
      dictionaryPath: dictionary,
      sourcesPath: sources,
      outputPath: output,
    );
  }

  static String _value(List<String> arguments, int index, String option) {
    if (index >= arguments.length) {
      throw FormatException('$option requires a path');
    }
    return arguments[index];
  }
}

const generatorHelp = '''Generate the checked-in Korean profanity dictionary.

Usage:
  fvm dart run tool/generate_dictionary.dart [--write]
  fvm dart run tool/generate_dictionary.dart --check
  fvm dart run tool/generate_dictionary.dart --help

Modes:
  --write              Write generated output atomically (default).
  --check              Fail if checked-in output is missing or stale.
  --help, -h           Show this help.

Fixture/path options:
  --dictionary PATH    Curated CSV (default: data/dictionary.csv).
  --sources PATH       Provenance manifest (default: data/sources.yaml).
  --output DIRECTORY   Generated directory (default: lib/src/generated).

A successful write/check prints the dictionary version and actual source,
tier, and match-mode counts. Generation is offline and performs no downloads.
''';
