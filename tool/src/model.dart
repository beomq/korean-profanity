const dictionaryHeader = <String>[
  'pattern',
  'canonical',
  'tier',
  'match_mode',
  'source_id',
  'note',
];

const tiers = <String>{'strict', 'lenient', 'allow'};
const modes = <String>{'substring', 'ascii_word', 'literal', 'choseong'};

const sourceFields = <String>{
  'id',
  'repository',
  'commit',
  'path',
  'retrieved',
  'license',
  'sha256',
};

const projectContractStrictPatterns = <String>{
  '수간',
  '10새끼',
  '18넘',
  '10jil',
  'fuck',
  'ass',
};

typedef SourceManifest = Map<String, Map<String, String>>;

final class DictionaryEntry {
  const DictionaryEntry({
    required this.row,
    required this.pattern,
    required this.canonical,
    required this.tier,
    required this.mode,
    required this.sourceId,
    required this.note,
  });

  final int row;
  final String pattern;
  final String canonical;
  final String tier;
  final String mode;
  final String sourceId;
  final String note;
}

final class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;
}

int compareEntries(DictionaryEntry left, DictionaryEntry right) {
  for (final comparison in <int>[
    left.tier.compareTo(right.tier),
    left.mode.compareTo(right.mode),
    left.pattern.compareTo(right.pattern),
    left.canonical.compareTo(right.canonical),
    left.sourceId.compareTo(right.sourceId),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

bool listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
