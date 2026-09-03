import 'model.dart';
import 'text_format.dart';

List<DictionaryEntry> parseDictionary(
  String text,
  Set<String> sourceIds,
) {
  final lines = text.split('\n');
  if (lines.isEmpty) {
    throw const ValidationException('row 1: missing CSV header');
  }
  final header = parseCsvLine(lines.first, 1);
  if (!listEquals(header, dictionaryHeader)) {
    throw ValidationException(
      'row 1: expected header ${dictionaryHeader.join(',')}',
    );
  }

  final entries = <DictionaryEntry>[];
  final seen = <String, DictionaryEntry>{};
  for (var index = 1; index < lines.length; index++) {
    final row = index + 1;
    final line = lines[index];
    if (line.isEmpty && index == lines.length - 1) continue;
    if (line.isEmpty) {
      throw ValidationException('row $row: blank row');
    }
    final fields = parseCsvLine(line, row);
    if (fields.length != dictionaryHeader.length) {
      throw ValidationException(
        'row $row: expected ${dictionaryHeader.length} fields, got ${fields.length}',
      );
    }
    _rejectBlankFields(fields, row);
    final entry = DictionaryEntry(
      row: row,
      pattern: fields[0],
      canonical: fields[1],
      tier: fields[2],
      mode: fields[3],
      sourceId: fields[4],
      note: fields[5],
    );
    _validateEntry(entry, sourceIds);
    final collisionKey = '${entry.mode}\u0000${entry.pattern}';
    final previous = seen[collisionKey];
    if (previous != null) {
      _rejectCollision(entry, previous);
    }
    seen[collisionKey] = entry;
    entries.add(entry);
  }
  if (entries.isEmpty) {
    throw const ValidationException('row 2: dictionary must not be empty');
  }
  return entries..sort(compareEntries);
}

void _rejectBlankFields(List<String> fields, int row) {
  for (var field = 0; field < fields.length; field++) {
    if (fields[field].trim().isEmpty) {
      throw ValidationException(
        'row $row: blank ${dictionaryHeader[field]}',
      );
    }
  }
}

void _validateEntry(DictionaryEntry entry, Set<String> sourceIds) {
  if (!tiers.contains(entry.tier)) {
    throw ValidationException('row ${entry.row}: invalid tier ${entry.tier}');
  }
  if (!modes.contains(entry.mode)) {
    throw ValidationException(
      'row ${entry.row}: invalid match_mode ${entry.mode}',
    );
  }
  if (!sourceIds.contains(entry.sourceId)) {
    throw ValidationException(
      'row ${entry.row}: unknown source_id ${entry.sourceId}',
    );
  }
  if (!_hasSupportedScript(entry.pattern) ||
      !_hasSupportedScript(entry.canonical)) {
    throw ValidationException('row ${entry.row}: unsupported script');
  }
  if (entry.sourceId.startsWith('tanat_') && entry.tier == 'strict') {
    if (!projectContractStrictPatterns.contains(entry.pattern)) {
      throw ValidationException(
        'row ${entry.row}: Tanat-only entries default to lenient',
      );
    }
    if (entry.note != 'project_contract') {
      throw ValidationException(
        'row ${entry.row}: strict Tanat exception requires note project_contract',
      );
    }
  }
}

void _rejectCollision(DictionaryEntry entry, DictionaryEntry previous) {
  if (previous.tier != entry.tier) {
    throw ValidationException(
      'row ${entry.row}: cross-tier collision for ${entry.pattern}',
    );
  }
  if (previous.canonical == entry.canonical) {
    throw ValidationException(
      'row ${entry.row}: duplicate pattern ${entry.pattern}',
    );
  }
  throw ValidationException(
    'row ${entry.row}: conflicting pattern ${entry.pattern}',
  );
}

bool _hasSupportedScript(String value) {
  for (final rune in value.runes) {
    final supported = rune <= 0x7f ||
        (rune >= 0x1100 && rune <= 0x11ff) ||
        (rune >= 0x3130 && rune <= 0x318f) ||
        (rune >= 0xa960 && rune <= 0xa97f) ||
        (rune >= 0xac00 && rune <= 0xd7a3) ||
        (rune >= 0xd7b0 && rune <= 0xd7ff) ||
        (rune >= 0xff01 && rune <= 0xff5e) ||
        (rune >= 0xffa0 && rune <= 0xffdc);
    if (!supported) return false;
  }
  return true;
}
