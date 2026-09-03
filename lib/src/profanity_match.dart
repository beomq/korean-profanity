import 'profanity_dictionary.dart';

/// An immutable accepted occurrence mapped to the original input.
final class ProfanityMatch {
  /// Creates a profanity occurrence over the UTF-16 range `[start, end)`.
  const ProfanityMatch({
    required this.start,
    required this.end,
    required this.text,
    required this.word,
    required this.tier,
    required this.isGapMatch,
  });

  /// Inclusive UTF-16 offset in the original input.
  final int start;

  /// Exclusive UTF-16 offset in the original input.
  final int end;

  /// Exact original input slice represented by this occurrence.
  final String text;

  /// Canonical dictionary term that produced this occurrence.
  final String word;

  /// Severity tier assigned to the canonical dictionary entry.
  final ProfanityTier tier;

  /// Whether this occurrence traversed normalized gap characters.
  final bool isGapMatch;
}
