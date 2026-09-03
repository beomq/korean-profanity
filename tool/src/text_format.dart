import 'model.dart';

String canonicalText(String input) {
  var text = input;
  if (text.startsWith('\uFEFF')) {
    text = text.substring(1);
  }
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return text.endsWith('\n') ? text : '$text\n';
}

List<String> parseCsvLine(String line, int row) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  var quoteClosed = false;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (quoted) {
      if (character != '"') {
        buffer.write(character);
      } else if (index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index++;
      } else {
        quoted = false;
        quoteClosed = true;
      }
    } else if (character == ',') {
      fields.add(buffer.toString());
      buffer.clear();
      quoteClosed = false;
    } else if (character == '"') {
      if (buffer.isNotEmpty || quoteClosed) {
        throw ValidationException('row $row: invalid quote placement');
      }
      quoted = true;
    } else {
      if (quoteClosed) {
        throw ValidationException('row $row: invalid quote placement');
      }
      buffer.write(character);
    }
  }
  if (quoted) {
    throw ValidationException('row $row: unterminated CSV quote');
  }
  fields.add(buffer.toString());
  return fields;
}
