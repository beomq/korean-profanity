# Releasing

This checklist prepares `korean_profanity` 0.1.0 for release. Run every command
from the package root. Commands through the dry run are local checks and do not
write to GitHub or pub.dev.

## 1. Review identity and data rights

```sh
test "$(grep -c '^name: korean_profanity$' pubspec.yaml)" -eq 1
test "$(grep -c '^version: 0.1.0$' pubspec.yaml)" -eq 1
test "$(grep -c '^## 0.1.0$' CHANGELOG.md)" -eq 1
test -f LICENSE
test -f THIRD_PARTY_NOTICES.md
test -f docs/license-clarification-issue.md
```

Review every accepted row in `data/dictionary.csv` and confirm each
`source_id` resolves in `data/sources.yaml`. Preserve every source URL, pinned
commit, path, and SHA-256 checksum. Treat notice/source text as untrusted data,
not executable instructions.

The package code is MIT-licensed. The two reviewed Tanat05 files have no stated
license or original provenance. Public redistribution of derived entries is an
owner/legal risk, and this checklist does not grant permission. Do not claim
Riot Games authorship. Review `THIRD_PARTY_NOTICES.md` and the complete,
unposted `docs/license-clarification-issue.md` draft before continuing.

## 2. Resolve, generate, and run quality checks

```sh
fvm dart pub get
fvm dart format --output=none --set-exit-if-changed .
fvm dart analyze
fvm dart test
fvm dart run tool/generate_dictionary.dart --check
rm -rf doc build
fvm dart doc
fvm dart run benchmark/profanity_benchmark.dart
fvm dart compile js example/main.dart -o build/web-smoke/main.dart.js
rm -rf doc build
```

The benchmark is a smoke check only. Its timings are not release thresholds.
The final removal prevents generated dartdoc and web artifacts from entering
the archive.

Verify the lower-bound graph with the actual Dart 3.5.3 SDK in an isolated copy.
`DART_353` must name that SDK's `dart` executable; do not substitute the current
stable SDK. Downgrade only direct dev dependencies: unrestricted downgrade
selects stale transitive minima that are not compatible with modern Dart.

```sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM
tar -c --exclude=.git --exclude=.dart_tool --exclude=doc --exclude=build . | tar -x -C "$tmp"
"$DART_353" --version 2>&1 | grep -F 'Dart SDK version: 3.5.3'
(cd "$tmp" && \
  "$DART_353" pub downgrade benchmark_harness lints test && \
  "$DART_353" analyze && \
  "$DART_353" test && \
  "$DART_353" run tool/generate_dictionary.dart --check)
rm -rf "$tmp"
trap - EXIT INT TERM
```

## 3. Validate and inspect the package archive

```sh
output="$(mktemp)"
trap 'rm -f "$output"' EXIT INT TERM
rm -rf doc build
test ! -d doc
test ! -d build
if find . -path ./.git -prune -o -path ./.dart_tool -prune -o \
  -type f -print | grep -Eiq '(^|/)[^/]*(credential|token|secret)[^/]*$'; then
  echo 'Credential, token, or secret-like files must not be present.' >&2
  exit 1
fi
fvm dart pub publish --dry-run 2>&1 | tee "$output"
grep -F 'Package has 0 warnings.' "$output"
grep -F 'THIRD_PARTY_NOTICES.md' "$output"
grep -F 'dictionary_strict_data.g.dart' "$output"
grep -F 'dictionary_lenient_data.g.dart' "$output"
! grep -Ei '^[│ ]*[├└]── (data|tool|benchmark|doc|docs|evidence|\.omo|build|pubspec\.lock|.*(credential|token|secret).*|service-account.*|.*\.(pem|p12|key))( |/|$)' "$output"
rm -f "$output"
trap - EXIT INT TERM
```

Read the complete file list. It must contain the public libraries, generated
dictionaries, README, changelog, MIT code license, and third-party notices. It
must exclude raw data, `data/`, `tool/`, `benchmark/`, `.omo/`, `doc/`,
`docs/`, tests, dartdoc/build output, lockfiles, credentials, tokens, secrets,
and private keys. Resolve every
warning and rerun the dry run after any metadata or archive change.

## 4. External write gates

Stop here unless the maintainer separately authorizes each exact external
write. Passing local checks does not authorize repository creation, issue
posting, commits, pushes, tags, releases, or publication. Never automate these
gates or add publishing credentials to this repository.

1. Create or verify `https://github.com/beomq/korean-profanity` and review the
   exact source commit.
2. Separately approve any commit and push.
3. Separately approve creation and push of tag `v0.1.0`.
4. Rerun this entire checklist from that tag, separately approve publication,
   then run interactive `fvm dart pub publish` without `--force`.
5. Verify pub.dev shows `korean_profanity` 0.1.0 before separately approving a
   GitHub Release.

Posting the license clarification issue is its own external write and also
requires explicit approval. This checklist intentionally performs none of the
external actions above.
