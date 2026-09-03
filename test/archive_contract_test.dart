import 'dart:collection';
import 'dart:io';

import 'package:test/test.dart';

const _excludedPackageDirectories = {
  '.git',
  '.dart_tool',
  'build',
  'doc',
  'temp',
};

String _join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';

Set<String> _archiveMembers(String output) {
  final treeLine = RegExp(r'^((?:│   |    )*)[├└]── (.+)$');
  final sizeSuffix = RegExp(r' \([^)]*\)$');
  final parentNames = <String>[];
  final members = <String>{};

  for (final line in output.split('\n')) {
    final match = treeLine.firstMatch(line);
    if (match == null) continue;

    final depth = match.group(1)!.length ~/ 4;
    if (parentNames.length > depth) {
      parentNames.removeRange(depth, parentNames.length);
    }
    final name = match.group(2)!.replaceFirst(sizeSuffix, '');
    final path = [...parentNames, name].join('/');
    members.add(path);
    parentNames.add(name);
  }

  return members;
}

Future<void> _copyPackage(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  final pending = Queue<Directory>()..add(source);

  while (pending.isNotEmpty) {
    final sourceDirectory = pending.removeFirst();
    final relativeDirectory = sourceDirectory.path == source.path
        ? ''
        : sourceDirectory.path.substring(source.path.length + 1);
    final destinationDirectory = relativeDirectory.isEmpty
        ? destination
        : Directory(_join(destination.path, relativeDirectory));
    await destinationDirectory.create(recursive: true);

    await for (final entity in sourceDirectory.list(followLinks: false)) {
      final relativePath = entity.path.substring(source.path.length + 1);
      final topLevelName = relativePath.split(Platform.pathSeparator).first;
      if (_excludedPackageDirectories.contains(topLevelName)) continue;

      if (entity is Directory) {
        pending.add(entity);
      } else if (entity is File) {
        await entity.copy(_join(destination.path, relativePath));
      } else if (entity is Link) {
        final target = await entity.target();
        await Link(_join(destination.path, relativePath)).create(target);
      }
    }
  }
}

void main() {
  test(
    'publish archive includes website source and excludes compiled output',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'korean_profanity_archive_contract_',
      );

      try {
        final packageCopy = Directory(_join(tempRoot.path, 'package'));
        await _copyPackage(Directory.current, packageCopy);

        final websiteCopy = Directory(_join(packageCopy.path, 'website'));
        final generatedArtifactNames = [
          'main.dart.js',
          'main.dart.js.map',
          'main.dart.js.deps',
          'main.dart.js.info.json',
          'main.dart.js.arbitrary-sidecar',
          'compiler-output.map',
          'compiler-output.deps',
          'main.dart.mjs',
          'main.dart.wasm',
        ];
        for (final name in generatedArtifactNames) {
          await File(_join(websiteCopy.path, name)).writeAsString(
            'generated compiler artifact fixture',
          );
        }

        final result = await Process.run(
          Platform.resolvedExecutable,
          const ['pub', 'publish', '--dry-run'],
          workingDirectory: packageCopy.path,
        );
        final output = '${result.stdout}\n${result.stderr}';

        expect(
          result.exitCode,
          0,
          reason: 'pub publish --dry-run must succeed.\n$output',
        );
        final archiveMembers = _archiveMembers(output);
        expect(archiveMembers, contains('website'));
        for (final source in const [
          'DESIGN.md',
          'components.css',
          'index.html',
          'main.dart',
          'responsive.css',
          'style.css',
        ]) {
          expect(
            archiveMembers,
            contains('website/$source'),
            reason: 'website/$source must be published',
          );
        }
        for (final name in generatedArtifactNames) {
          expect(
            archiveMembers,
            isNot(contains('website/$name')),
            reason: 'website/$name must not be published',
          );
        }
      } finally {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
