# korean-profanity

`korean_profanity` is a small, synchronous Korean profanity filter for Dart and
Flutter. It runs directly in your process from an embedded dictionary. There is
no server call, account, or text upload.

## Install

```sh
dart pub add korean_profanity
```

Use `flutter pub add korean_profanity` in a Flutter app.

```dart
import 'package:korean_profanity/korean_profanity.dart';

void main() {
  final filter = KoreanProfanityFilter();
  print(filter.contains('씨1발')); // true
  print(filter.mask('씨 11 발')); // ******
}
```

The main library includes the strict dictionary. Matcher scanners are built
lazily on the first call and reused by that immutable filter instance.

## Examples

### 1. Detect, inspect, and mask

`findAll` returns every accepted overlap in deterministic source order. It does
not reduce results to non-overlapping matches.

```dart
import 'package:korean_profanity/korean_profanity.dart';

void main() {
  final filter = KoreanProfanityFilter();
  final matches = filter.findAll('개새끼');

  print(filter.contains('개새끼')); // true
  print(matches.map((match) => match.word).toList()); // [개새끼, 새끼]
  print(filter.mask('개새끼')); // ***
}
```

### 2. Warn after a Flutter button click

This stateful form checks only when the user clicks `등록`. The warning is
shown through `errorText`, so it is attached to the labeled field.

```dart
import 'package:flutter/material.dart';
import 'package:korean_profanity/korean_profanity.dart';

void main() => runApp(const MaterialApp(home: CommentForm()));

class CommentForm extends StatefulWidget {
  const CommentForm({super.key});

  @override
  State<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final _controller = TextEditingController();
  final _filter = KoreanProfanityFilter();
  List<ProfanityMatch> _hits = const [];
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _hits = _filter.findAll(_controller.text);
      _errorText = _hits.isNotEmpty ? '부적절한 표현이 있어요' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: '댓글',
                      errorText: _errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _submit, child: const Text('등록')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 3. Validate a `TextFormField`

```dart
import 'package:flutter/material.dart';
import 'package:korean_profanity/korean_profanity.dart';

TextFormField commentField(KoreanProfanityFilter filter) {
  return TextFormField(
    decoration: const InputDecoration(labelText: '댓글'),
    validator: (value) {
      if (filter.contains(value ?? '')) return '부적절한 표현이 있어요';
      return null;
    },
  );
}
```

### 4. Mask before sending

Filtering is local, but your own send function may still transmit its argument.
Mask first when that matches your product policy.

```dart
import 'package:korean_profanity/korean_profanity.dart';

Future<void> sendComment(String text) async {
  final safeText = KoreanProfanityFilter().mask(text, maskCharacter: '●');
  await Future<void>.value(safeText);
}

Future<void> main() => sendComment('씨 11 발');
```

### 5. Customize without shared mutation

Each filter is immutable. Added, removed, and ignored words affect only the new
instance. The strict dictionary is the default. Lenient terms and bundled
choseong matching are available through the optional entrypoint.

```dart
import 'package:korean_profanity/korean_profanity.dart';
import 'package:korean_profanity/korean_profanity_lenient.dart' as lenient;

void main() {
  final custom = KoreanProfanityFilter(
    addedWords: const ['우리회사욕'],
    removedWords: const ['시발'],
    ignoreWords: const ['시발점'],
  );
  final broad = lenient.KoreanProfanityFilter(
    dictionary: lenient.koreanLenientDictionary,
    minimumTier: lenient.ProfanityTier.lenient,
    choseongSearch: true,
  );

  print(custom.contains('우리회사욕')); // true
  print(custom.contains('시발')); // false
  print(custom.contains('시발점')); // false
  print(broad.contains('토토')); // true, lenient term
  print(broad.contains('수박')); // true, choseong match for ㅅㅂ
}
```

You can also supply a `ProfanityDictionary` with your own strict, lenient,
allowlist, and choseong entries.

## Matching behavior

The normalizer handles a deliberately narrow set of Korean evasion forms. It
folds supported modern Hangul forms, selected visual variants, and internal
spaces or digits when they occur inside a possible match. For example:

| Input | Strict result | Reason |
| --- | --- | --- |
| `씨1발` | detected | an internal digit is treated as a gap |
| `씨 11 발` | detected | internal spaces and digits are treated as gaps |
| `시😀발` | not detected | emoji is a hard boundary |
| `시간` | not detected | the bundled allowlist protects the ordinary word |

`ProfanityMatch.start` and `end` are UTF-16 offsets into the original string.
This matches Dart's `substring` indexing, including text containing emoji.
`match.text` is always the original slice. `isGapMatch` tells you whether the
accepted occurrence crossed ignored gaps.

Strict terms are shipped by the main import. Context-sensitive terms are kept
in the optional lenient dictionary to reduce ordinary-word collisions. The
allowlist can suppress a candidate only when it fully covers that occurrence.
Choseong search is opt-in because matching initials can create more false
positives.

`dictionaryVersion` identifies the generated data used by the package. This
release reports `b9a61fbaac59`.

## Privacy, size, and performance

Detection and masking are offline and synchronous. Input is not sent anywhere
by this package. Keep in mind that logging a match or passing masked text to
your own network code is still application behavior that you control.

Measured release evidence for this version:

* Clean package archive: 18-19 KB.
* Strict AOT delta for a consumer that uses detection and `findAll` only:
  98,496 bytes.
* Strict AOT delta for a consumer that also retains masking code: 114,912
  bytes.
* Strict web gzip delta: 23-26 KB.

The archive range is compressed publish size, not runtime size; Pub's displayed
value varies with rounding. The exact AOT values are separate measured profiles:
calling `mask` retains code that a detection-only consumer can tree-shake.
Compiler tree-shaking and retained output paths vary by consumer, which is why
the web result is reported as a range rather than a universal package cost.
Runtime timings are observational. Run the included benchmark on your machine
instead of treating one timing as a limit:

```sh
fvm dart run benchmark/profanity_benchmark.dart
```

## Choosing a package

Use source and behavior, not package names alone, when comparing filters.

| Package | Source facts verified for this release | Fair reading |
| --- | --- | --- |
| `korean_profanity` | The API and tests in this repository verify typed matches, UTF-16 source ranges, all overlaps, masking, tiers, an allowlist, and immutable customization. Some dictionary input licenses remain unknown. | Choose it when those verified contracts fit your policy, after reviewing the data notices. |
| Xim-ya `korean_profanity_filter` | The pinned source at commit `9952105318d1644a2ccf294e875d8b5d62b2bbaa` is MIT-licensed and supplied reviewed regex roots used by this package. | Check its current source when you want its regex-oriented design. This release evidence does not claim parity for metadata, masking, tiers, or offsets. |
| `safe_text` | No pinned `safe_text` source is part of this release provenance or verification record. | No dictionary, API, maintenance, license, size, or runtime comparison is claimed. Verify its current source and notices before choosing it. |

This table leaves unknowns unknown rather than turning package descriptions
into unsupported feature or quality claims.

## Limitations and data notices

This is a dictionary matcher, not a moderation policy or a language model. It
can miss new spellings and context, and it can flag benign text. Review results
for your audience, add product-specific words, and offer an appeal path where a
decision affects a person.

Normalization is not full Unicode normalization, transliteration, typo
correction, or morphological analysis. Emoji remains a boundary. Gap handling
is deliberately bounded. Lenient and choseong modes trade fewer misses for
more false positives.

The package code is MIT-licensed. Some reviewed dictionary inputs from
Tanat05/korean-profanity-resources have no stated license or original
provenance. Redistribution of entries derived from those files is an
owner/legal risk. Read [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the
pinned source records before release or redistribution. The notices do not
grant permission or claim Riot Games authorship.

## Run the command-line example

```sh
fvm dart run example/main.dart '씨 11 발'
printf '씨 11 발\n' | fvm dart run example/main.dart
fvm dart run example/main.dart --help
```

## 한국어 빠른 안내

`korean_profanity`는 서버 전송 없이 앱 안에서 동작하는 순수 Dart 욕설
필터입니다. 기본 import에는 strict 사전만 포함되며, lenient 사전과 초성
검색은 별도 entrypoint에서 선택합니다.

```dart
import 'package:korean_profanity/korean_profanity.dart';

void main() {
  final filter = KoreanProfanityFilter();
  print(filter.contains('씨 11 발')); // true
  print(filter.mask('씨 11 발')); // ******
}
```

`findAll`은 겹치는 모든 결과와 원문 기준 UTF-16 범위를 반환합니다.
`addedWords`, `removedWords`, `ignoreWords`로 인스턴스별 설정을 만들 수
있습니다. `씨1발`, `씨 11 발`은 감지하지만 이모지가 경계인 `시😀발`은
감지하지 않습니다. 오탐과 미탐 가능성이 있으므로 서비스 정책에 맞게
검토하고, 배포 전 데이터 출처와 미확인 라이선스 위험을
`THIRD_PARTY_NOTICES.md`에서 확인하세요.

Issues: <https://github.com/beomq/korean-profanity/issues>
