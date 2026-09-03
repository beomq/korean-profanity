import 'dart:convert';
import 'dart:io';

import 'src/dictionary_parser.dart';
import 'src/model.dart';
import 'src/options.dart';
import 'src/output.dart';
import 'src/renderer.dart';
import 'src/sha256.dart';
import 'src/source_manifest.dart';
import 'src/text_format.dart';

void main(List<String> arguments) {
  try {
    final options = GeneratorOptions.parse(arguments);
    if (options.help) {
      stdout.write(generatorHelp);
      return;
    }

    final dictionaryText = canonicalText(
      File(options.dictionaryPath).readAsStringSync(),
    );
    final sourcesText = canonicalText(
      File(options.sourcesPath).readAsStringSync(),
    );
    final sources = parseSources(sourcesText);
    final entries = parseDictionary(dictionaryText, sources.keys.toSet());
    final version = sha256Hex(
      utf8.encode(dictionaryText + sourcesText),
    ).substring(0, 12);
    final generated = renderDictionaryFiles(entries, sources, version);
    final outputs = <File, String>{
      for (final entry in generated.entries)
        File('${options.outputPath}/${entry.key}'): entry.value,
    };
    final legacy = File('${options.outputPath}/$legacyGeneratedFile');

    if (options.check) {
      final stale = outputs.entries.where(
        (entry) =>
            !entry.key.existsSync() ||
            entry.key.readAsStringSync() != entry.value,
      );
      if (stale.isNotEmpty || legacy.existsSync()) {
        for (final entry in stale) {
          stderr.writeln('stale generated output: ${entry.key.path}');
        }
        if (legacy.existsSync()) {
          stderr.writeln('stale generated output: ${legacy.path}');
        }
        exitCode = 1;
        return;
      }
      stdout.writeln('check: generated output is current');
    } else {
      for (final entry in outputs.entries) {
        atomicWrite(entry.key, entry.value);
        stdout.writeln('write: ${entry.key.path}');
      }
      if (legacy.existsSync()) legacy.deleteSync();
    }
    printCounts(entries, version);
  } on ValidationException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('argument error: ${error.message}');
    stderr.write(generatorHelp);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('file error: ${error.message} (${error.path})');
    exitCode = 1;
  }
}
