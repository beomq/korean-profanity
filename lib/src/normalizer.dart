import 'normalized_text.dart';

const _syllableBase = 0xac00;
const _syllableEnd = 0xd7a3;
const _vowelCount = 21;
const _trailingCount = 28;
const _compatibilityInitials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
const _halfwidthInitials = 'ﾡﾢﾤﾧﾨﾩﾱﾲﾳﾵﾶﾷﾸﾹﾺﾻﾼﾽﾾ';
const _compatibilityVowels = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ';
const _halfwidthVowels = 'ￂￃￄￅￆￇￊￋￌￍￎￏￒￓￔￕￖￗￚￛￜ';
const _compatibilityFinals = 'ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ';
const _halfwidthFinals = 'ﾡﾢﾣﾤﾥﾦﾧﾩﾪﾫﾬﾭﾮﾯﾰﾱﾲﾴﾵﾶﾷﾸﾺﾻﾼﾽﾾ';

/// Performs the package's deliberately narrow Unicode normalization.
NormalizedText normalizeText(String text) {
  final source = _decode(text);
  final composed = <NormalizedScalar>[];

  var index = 0;
  while (index < source.length) {
    final current = source[index];
    final value = _fold(current.value);
    final leading = _leadingIndex(value);
    final vowel = index + 1 < source.length
        ? _vowelIndex(_fold(source[index + 1].value))
        : null;

    if (leading != null && vowel != null) {
      var consumed = 2;
      var trailing = 0;
      if (index + 2 < source.length) {
        final candidate = _fold(source[index + 2].value);
        final candidateTrailing = _trailingIndex(candidate);
        final startsNext = _leadingIndex(candidate) != null &&
            index + 3 < source.length &&
            _vowelIndex(_fold(source[index + 3].value)) != null;
        if (candidateTrailing != null && !startsNext) {
          trailing = candidateTrailing;
          consumed = 3;
        }
      }
      final syllable = _syllableBase +
          (leading * _vowelCount + vowel) * _trailingCount +
          trailing;
      composed.add(
        NormalizedScalar(
          syllable,
          current.start,
          source[index + consumed - 1].end,
          isHangulLike: true,
        ),
      );
      index += consumed;
      continue;
    }

    composed.add(
      NormalizedScalar(
        value,
        current.start,
        current.end,
        isHangulLike: _isHangulLike(value),
      ),
    );
    index++;
  }

  final canonical = _removeInternalGaps(composed);
  final choseong = canonical.map(_toChoseong).toList(growable: false);
  return NormalizedText(text, canonical, choseong);
}

List<NormalizedScalar> _removeInternalGaps(List<NormalizedScalar> input) {
  final output = <NormalizedScalar>[];
  final pending = <NormalizedScalar>[];

  for (final scalar in input) {
    if (_isGapCandidate(scalar.value)) {
      if (pending.isNotEmpty ||
          (output.isNotEmpty && output.last.isHangulLike)) {
        pending.add(scalar);
      } else {
        output.add(scalar);
      }
      continue;
    }

    if (pending.isNotEmpty) {
      if (output.last.isHangulLike && scalar.isHangulLike) {
        output.add(scalar.withGapBefore());
        pending.clear();
        continue;
      }
      output.addAll(pending);
      pending.clear();
    }
    output.add(scalar);
  }
  output.addAll(pending);
  return List.unmodifiable(output);
}

NormalizedScalar _toChoseong(NormalizedScalar scalar) {
  final value = scalar.value;
  int? initial;
  if (value >= _syllableBase && value <= _syllableEnd) {
    initial = (value - _syllableBase) ~/ (_vowelCount * _trailingCount);
  } else {
    initial = _leadingIndex(value);
  }
  if (initial == null) return scalar;
  return NormalizedScalar(
    _compatibilityInitials.codeUnitAt(initial),
    scalar.start,
    scalar.end,
    isHangulLike: true,
    isGapBefore: scalar.isGapBefore,
  );
}

List<_SourceScalar> _decode(String text) {
  final result = <_SourceScalar>[];
  var offset = 0;
  while (offset < text.length) {
    final first = text.codeUnitAt(offset);
    if (first >= 0xd800 && first <= 0xdbff && offset + 1 < text.length) {
      final second = text.codeUnitAt(offset + 1);
      if (second >= 0xdc00 && second <= 0xdfff) {
        final value = 0x10000 + ((first - 0xd800) << 10) + second - 0xdc00;
        result.add(_SourceScalar(value, offset, offset + 2));
        offset += 2;
        continue;
      }
    }
    result.add(_SourceScalar(first, offset, offset + 1));
    offset++;
  }
  return result;
}

int _fold(int value) {
  if (value >= 0xff01 && value <= 0xff5e) value -= 0xfee0;
  if (value == 0x3000) value = 0x20;
  if (value >= 0x41 && value <= 0x5a) value += 0x20;
  return value;
}

int? _leadingIndex(int value) {
  if (value >= 0x1100 && value <= 0x1112) return value - 0x1100;
  final compatibility = _compatibilityInitials.codeUnits.indexOf(value);
  if (compatibility >= 0) return compatibility;
  final halfwidth = _halfwidthInitials.codeUnits.indexOf(value);
  return halfwidth < 0 ? null : halfwidth;
}

int? _vowelIndex(int value) {
  if (value >= 0x1161 && value <= 0x1175) return value - 0x1161;
  final compatibility = _compatibilityVowels.codeUnits.indexOf(value);
  if (compatibility >= 0) return compatibility;
  final halfwidth = _halfwidthVowels.codeUnits.indexOf(value);
  return halfwidth < 0 ? null : halfwidth;
}

int? _trailingIndex(int value) {
  if (value >= 0x11a8 && value <= 0x11c2) return value - 0x11a7;
  final compatibility = _compatibilityFinals.codeUnits.indexOf(value);
  if (compatibility >= 0) return compatibility + 1;
  final halfwidth = _halfwidthFinals.codeUnits.indexOf(value);
  return halfwidth < 0 ? null : halfwidth + 1;
}

bool _isHangulLike(int value) =>
    (value >= _syllableBase && value <= _syllableEnd) ||
    (value >= 0x1100 && value <= 0x11c2) ||
    (value >= 0x3131 && value <= 0x3163) ||
    _halfwidthInitials.codeUnits.contains(value) ||
    _halfwidthVowels.codeUnits.contains(value);

bool _isGapCandidate(int value) {
  if (value == 0x09 ||
      value == 0x20 ||
      value == 0xa0 ||
      value == 0x1680 ||
      value == 0x202f ||
      value == 0x205f) {
    return true;
  }
  if (value >= 0x2000 && value <= 0x200a && value != 0x200b) return true;
  if (value >= 0x30 && value <= 0x39) return true;
  if ((value >= 0x21 && value <= 0x2f) ||
      (value >= 0x3a && value <= 0x40) ||
      (value >= 0x5b && value <= 0x60) ||
      (value >= 0x7b && value <= 0x7e) ||
      _isLatin1Gap(value) ||
      (value >= 0x20a0 && value <= 0x20cf)) {
    return true;
  }
  if ((value >= 0x2000 && value <= 0x206f) ||
      (value >= 0x3001 && value <= 0x303f)) {
    return !_isFormatBarrier(value) && value != 0x2028 && value != 0x2029;
  }
  return false;
}

bool _isLatin1Gap(int value) =>
    (value >= 0xa1 && value <= 0xa9) ||
    (value >= 0xab && value <= 0xac) ||
    (value >= 0xae && value <= 0xb4) ||
    (value >= 0xb6 && value <= 0xb9) ||
    (value >= 0xbb && value <= 0xbf) ||
    value == 0xd7 ||
    value == 0xf7;

bool _isFormatBarrier(int value) =>
    (value >= 0x200b && value <= 0x200f) ||
    (value >= 0x202a && value <= 0x202e) ||
    (value >= 0x2060 && value <= 0x206f);

final class _SourceScalar {
  const _SourceScalar(this.value, this.start, this.end);

  final int value;
  final int start;
  final int end;
}
