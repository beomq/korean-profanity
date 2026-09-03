import 'model.dart';

SourceManifest parseSources(String text) {
  final lines = text.split('\n');
  if (lines.isEmpty || lines.first.trim() != 'sources:') {
    throw const ValidationException('sources row 1: expected "sources:"');
  }
  final sources = <String, Map<String, String>>{};
  Map<String, String>? current;
  var currentRow = 0;

  void finish() {
    final source = current;
    if (source == null) return;
    final missing = sourceFields.difference(source.keys.toSet());
    if (missing.isNotEmpty) {
      throw ValidationException(
        'sources row $currentRow: missing ${missing.toList()..sort()}',
      );
    }
    final id = source['id']!;
    if (id.isEmpty) {
      throw ValidationException('sources row $currentRow: blank id');
    }
    if (sources.containsKey(id)) {
      throw ValidationException('sources row $currentRow: duplicate id $id');
    }
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(source['commit']!)) {
      throw ValidationException('sources row $currentRow: invalid commit');
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(source['sha256']!)) {
      throw ValidationException('sources row $currentRow: invalid sha256');
    }
    sources[id] = Map<String, String>.unmodifiable(source);
  }

  for (var index = 1; index < lines.length; index++) {
    final raw = lines[index];
    if (raw.isEmpty && index == lines.length - 1) continue;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (trimmed.startsWith('- ')) {
      finish();
      current = <String, String>{};
      currentRow = index + 1;
      _parseSourceField(trimmed.substring(2), current, index + 1);
    } else {
      if (current == null) {
        throw ValidationException(
          'sources row ${index + 1}: field outside source entry',
        );
      }
      _parseSourceField(trimmed, current, index + 1);
    }
  }
  finish();
  if (sources.isEmpty) {
    throw const ValidationException('sources: at least one source is required');
  }
  return Map<String, Map<String, String>>.unmodifiable(sources);
}

void _parseSourceField(
  String text,
  Map<String, String> target,
  int row,
) {
  final separator = text.indexOf(':');
  if (separator <= 0) {
    throw ValidationException('sources row $row: malformed field');
  }
  final key = text.substring(0, separator).trim();
  var value = text.substring(separator + 1).trim();
  if (!sourceFields.contains(key)) {
    throw ValidationException('sources row $row: unknown field $key');
  }
  if (target.containsKey(key)) {
    throw ValidationException('sources row $row: duplicate field $key');
  }
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    value = value.substring(1, value.length - 1);
  }
  if (value.isEmpty) {
    throw ValidationException('sources row $row: blank $key');
  }
  target[key] = value;
}
