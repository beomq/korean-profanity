import 'dart:io';

import 'model.dart';

void atomicWrite(File output, String contents) {
  output.parent.createSync(recursive: true);
  final temporary = File('${output.path}.tmp.$pid');
  try {
    temporary.writeAsStringSync(contents, flush: true);
    temporary.renameSync(output.path);
  } finally {
    if (temporary.existsSync()) temporary.deleteSync();
  }
}

void printCounts(List<DictionaryEntry> entries, String version) {
  Map<String, int> countBy(String Function(DictionaryEntry) select) {
    final counts = <String, int>{};
    for (final entry in entries) {
      counts.update(select(entry), (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String show(Map<String, int> counts) =>
      counts.entries.map((entry) => '${entry.key}=${entry.value}').join(', ');

  stdout.writeln('dictionaryVersion: $version');
  stdout.writeln('entries: ${entries.length}');
  stdout.writeln('source counts: ${show(countBy((entry) => entry.sourceId))}');
  stdout.writeln('tier counts: ${show(countBy((entry) => entry.tier))}');
  stdout.writeln('mode counts: ${show(countBy((entry) => entry.mode))}');
}
