import 'dart:collection';

import 'generated/dictionary_version.g.dart';

/// The severity threshold assigned to a profanity dictionary entry.
enum ProfanityTier {
  /// A high-confidence term included by the default filter.
  strict,

  /// A context-sensitive term available only when explicitly selected.
  lenient,
}

/// Immutable configuration for profanity, allowlist, and choseong entries.
final class ProfanityDictionary {
  /// Creates an immutable custom dictionary.
  ///
  /// Every iterable is copied. Empty or normalized-duplicate entries are
  /// rejected when the dictionary is used to construct a filter.
  factory ProfanityDictionary({
    Iterable<String> strictWords = const <String>[],
    Iterable<String> lenientWords = const <String>[],
    Iterable<String> allowWords = const <String>[],
    Iterable<String> choseongPatterns = const <String>[],
  }) {
    return ProfanityDictionary._(
      strictWords,
      lenientWords,
      allowWords,
      choseongPatterns,
    );
  }

  ProfanityDictionary._(
    Iterable<String> strictWords,
    Iterable<String> lenientWords,
    Iterable<String> allowWords,
    Iterable<String> choseongPatterns,
  )   : strictWords = UnmodifiableListView(strictWords.toList()),
        lenientWords = UnmodifiableListView(lenientWords.toList()),
        allowWords = UnmodifiableListView(allowWords.toList()),
        choseongPatterns = UnmodifiableListView(choseongPatterns.toList());

  /// High-confidence terms supplied to this dictionary.
  final List<String> strictWords;

  /// Context-sensitive terms supplied to this dictionary.
  final List<String> lenientWords;

  /// Terms that suppress fully covered profanity occurrences.
  final List<String> allowWords;

  /// Initial-consonant patterns used when choseong search is enabled.
  final List<String> choseongPatterns;
}

/// Version of the bundled dictionary data.
///
/// This is the first 12 hexadecimal characters of SHA-256 over the canonical
/// curated dictionary followed by the canonical provenance manifest. Use it
/// to identify the exact bundled data in diagnostics or moderation records.
/// It is not a package version.
const String dictionaryVersion = generatedDictionaryVersion;
