import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('strict transitive import graph cannot reach lenient declarations', () {
    final root = Directory.current.absolute;
    final reachable = _walk(
      File('${root.path}/lib/korean_profanity.dart'),
      root,
    );
    final leaks = reachable.where((file) {
      final source = file.readAsStringSync();
      return source.contains('generatedLenient') ||
          file.path.contains('lenient_data.g.dart');
    });

    expect(leaks.map((file) => file.path), isEmpty);
  });
}

Set<File> _walk(File entrypoint, Directory root) {
  final pending = <File>[entrypoint.absolute];
  final visitedPaths = <String>{};
  final visited = <File>{};
  final directive = RegExp(r"^(?:import|export)\s+'([^']+)'", multiLine: true);
  while (pending.isNotEmpty) {
    final file = pending.removeLast();
    if (!visitedPaths.add(file.path)) continue;
    visited.add(file);
    for (final match in directive.allMatches(file.readAsStringSync())) {
      final uri = match.group(1)!;
      if (uri.startsWith('dart:') || !uri.endsWith('.dart')) continue;
      final path = uri.startsWith('package:korean_profanity/')
          ? '${root.path}/lib/${uri.substring('package:korean_profanity/'.length)}'
          : File('${file.parent.path}/$uri').absolute.path;
      pending.add(File(path));
    }
  }
  return visited;
}
