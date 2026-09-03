/// One normalized Unicode scalar and its contributing original UTF-16 range.
final class NormalizedScalar {
  const NormalizedScalar(
    this.value,
    this.start,
    this.end, {
    required this.isHangulLike,
    this.isGapBefore = false,
  });

  final int value;
  final int start;
  final int end;
  final bool isHangulLike;

  /// Whether removable source content occurred after the preceding scalar.
  final bool isGapBefore;

  NormalizedScalar withGapBefore() => NormalizedScalar(
        value,
        start,
        end,
        isHangulLike: isHangulLike,
        isGapBefore: true,
      );
}

/// An original UTF-16 range corresponding to a normalized scalar range.
final class NormalizedSpan {
  const NormalizedSpan(this.start, this.end, this.isGap);

  final int start;
  final int end;
  final bool isGap;

  @override
  bool operator ==(Object other) =>
      other is NormalizedSpan &&
      start == other.start &&
      end == other.end &&
      isGap == other.isGap;

  @override
  int get hashCode => Object.hash(start, end, isGap);

  @override
  String toString() => 'NormalizedSpan($start, $end, $isGap)';
}

/// Canonical and choseong views of one original string.
final class NormalizedText {
  NormalizedText(
    this.original,
    List<NormalizedScalar> canonicalScalars,
    List<NormalizedScalar> choseongScalars,
  )   : canonicalScalars = List.unmodifiable(canonicalScalars),
        choseongScalars = List.unmodifiable(choseongScalars);

  final String original;
  final List<NormalizedScalar> canonicalScalars;
  final List<NormalizedScalar> choseongScalars;

  String get canonical => String.fromCharCodes(canonicalCodePoints);
  String get choseong => String.fromCharCodes(choseongCodePoints);

  List<int> get canonicalCodePoints =>
      List.unmodifiable(canonicalScalars.map((scalar) => scalar.value));
  List<int> get choseongCodePoints =>
      List.unmodifiable(choseongScalars.map((scalar) => scalar.value));

  /// Maps `[start, end)` in a normalized stream to the original UTF-16 span.
  NormalizedSpan sourceSpan(int start, int end, {bool choseong = false}) {
    final scalars = choseong ? choseongScalars : canonicalScalars;
    RangeError.checkValidRange(start, end, scalars.length);
    if (start == end) {
      final offset =
          start == scalars.length ? original.length : scalars[start].start;
      return NormalizedSpan(offset, offset, false);
    }

    var isGap = false;
    for (var index = start + 1; index < end; index++) {
      isGap |= scalars[index].isGapBefore;
    }
    return NormalizedSpan(scalars[start].start, scalars[end - 1].end, isGap);
  }
}
