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
fvm dart compile js -O4 website/main.dart -o build/website/main.dart.js
test -s build/website/main.dart.js
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
grep -F 'DESIGN.md' "$output"
grep -F 'components.css' "$output"
grep -F 'index.html' "$output"
grep -F 'main.dart' "$output"
grep -F 'responsive.css' "$output"
grep -F 'style.css' "$output"
! grep -Ei '^[│ ]*[├└]── (data|tool|benchmark|doc|docs|evidence|\.omo|build|pubspec\.lock|.*\.(js|mjs|wasm)(\.[^ /]+)*|.*\.(map|deps)|.*(credential|token|secret).*|service-account.*|.*\.(pem|p12|key))( |/|$)' "$output"
rm -f "$output"
trap - EXIT INT TERM
```

Read the complete file list. It must contain the public libraries, generated
dictionaries, README, changelog, MIT code license, third-party notices, and
exactly the website sources `website/index.html`, `website/style.css`,
`website/components.css`, `website/responsive.css`, `website/main.dart`, and
`website/DESIGN.md`. It must exclude raw data, `data/`,
`tool/`, `benchmark/`, `.omo/`, `doc/`, `docs/`, tests, dartdoc/build output,
lockfiles, credentials, tokens, secrets, private keys, screenshots, temporary
assets, and compiled website JavaScript or generated compiler sidecars. Pages compilation must
write only under ignored `build/website`; never copy generated output back into
`website/`. Resolve every warning and rerun the dry run after any metadata or
archive change.

## 4. Verify the Pages build locally

```sh
rm -rf build/compiler build/website
mkdir -p build/compiler build/website
fvm dart compile js -O4 website/main.dart -o build/compiler/main.dart.js
install -m 0644 \
  website/index.html \
  website/style.css \
  website/components.css \
  website/responsive.css \
  build/website/
install -m 0644 build/compiler/main.dart.js build/website/main.dart.js
rm -rf build/compiler
test -s build/website/index.html
test -s build/website/style.css
test -s build/website/components.css
test -s build/website/responsive.css
test -s build/website/main.dart.js
test -z "$(find build/website -type f \
  \( -name '*.map' -o -name '*.deps' -o -name '*.dart.js.*' \) \
  -print -quit)"
rm -rf build
```

After a separately approved push to `main`, the Pages workflow builds this
same artifact and deploys it. Verify
`https://beomq.github.io/korean-profanity/` before publication. A workflow run
creates an external Pages write and is not authorized by these local checks.

## 5. External write gates

Stop here unless the maintainer separately authorizes each exact external
write. Passing local checks does not authorize repository creation, issue
posting, commits, pushes, tags, releases, or publication. Never automate these
gates or add publishing credentials to this repository.

1. Create or verify `https://github.com/beomq/korean-profanity` and review the
   exact source commit.
2. Separately approve any commit and push to `main`; this push triggers the
   Pages deployment.
3. Verify the Pages workflow and live demo, then separately approve creation
   and push of tag `v0.1.0`.
4. Rerun this entire checklist from that tag, separately approve publication,
   then run interactive `fvm dart pub publish` without `--force`.
5. Verify pub.dev shows `korean_profanity` 0.1.0 before separately approving a
   GitHub Release.

Posting the license clarification issue is its own external write and also
requires explicit approval. This checklist intentionally performs none of the
external actions above.
