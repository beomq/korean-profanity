import '../profanity_match.dart';

String maskMatches(
  String text,
  List<ProfanityMatch> matches, {
  String maskCharacter = '*',
}) {
  if (maskCharacter.runes.length != 1) {
    throw ArgumentError.value(
      maskCharacter,
      'maskCharacter',
      'must contain exactly one Unicode scalar',
    );
  }
  if (matches.isEmpty) return text;

  final ranges = matches.map((match) => (match.start, match.end)).toList()
    ..sort((left, right) => left.$1.compareTo(right.$1));
  final merged = <(int, int)>[];
  for (final range in ranges) {
    if (merged.isEmpty || range.$1 > merged.last.$2) {
      merged.add(range);
      continue;
    }
    final previous = merged.removeLast();
    merged.add((previous.$1, range.$2 > previous.$2 ? range.$2 : previous.$2));
  }

  final output = StringBuffer();
  var offset = 0;
  var rangeIndex = 0;
  for (final scalar in text.runes) {
    final scalarLength = scalar > 0xffff ? 2 : 1;
    while (rangeIndex < merged.length && offset >= merged[rangeIndex].$2) {
      rangeIndex++;
    }
    final masked = rangeIndex < merged.length &&
        offset >= merged[rangeIndex].$1 &&
        offset < merged[rangeIndex].$2;
    output.write(
        masked ? maskCharacter : text.substring(offset, offset + scalarLength));
    offset += scalarLength;
  }
  return output.toString();
}
