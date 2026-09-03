import 'profanity_dictionary.dart';
import 'profanity_filter_cache.dart';
import 'profanity_match.dart';
import 'profanity_matcher.dart';

/// An immutable, synchronous Korean profanity filter.
///
/// Uncustomized instances share one lazily created matcher per isolate.
/// Customized instances own an isolated matcher configuration. Compiled scanners
/// are initialized lazily on first use and then reused by later calls.
final class KoreanProfanityFilter {
  /// Creates an immutable filter configuration.
  ///
  /// If [dictionary] is omitted, the bundled strict dictionary is used.
  /// [minimumTier] controls whether a supplied dictionary includes only strict
  /// entries or strict and lenient entries. [addedWords], [removedWords], and
  /// [ignoreWords] customize only this instance. Set [choseongSearch] to opt in
  /// to initial-consonant matching when the dictionary provides patterns.
  factory KoreanProfanityFilter({
    ProfanityDictionary? dictionary,
    ProfanityTier minimumTier = ProfanityTier.strict,
    Iterable<String> addedWords = const <String>[],
    Iterable<String> removedWords = const <String>[],
    Iterable<String> ignoreWords = const <String>[],
    bool choseongSearch = false,
  }) {
    final isDefault = dictionary == null &&
        minimumTier == ProfanityTier.strict &&
        addedWords.isEmpty &&
        removedWords.isEmpty &&
        ignoreWords.isEmpty &&
        !choseongSearch;
    return KoreanProfanityFilter._(
      isDefault
          ? DefaultMatcherCache.acquire()
          : ProfanityMatcher(
              dictionary: dictionary,
              minimumTier: minimumTier,
              addedWords: addedWords,
              removedWords: removedWords,
              ignoreWords: ignoreWords,
              choseongSearch: choseongSearch,
            ),
    );
  }

  const KoreanProfanityFilter._(this._matcher);

  final ProfanityMatcher _matcher;

  /// Whether [text] contains at least one accepted occurrence.
  bool contains(String text) => findAll(text).isNotEmpty;

  /// Returns every accepted occurrence in deterministic source order.
  ///
  /// Overlapping occurrences are retained. The returned list is immutable.
  /// Match offsets are UTF-16 offsets into [text], so
  /// `text.substring(match.start, match.end) == match.text`.
  List<ProfanityMatch> findAll(String text) => _matcher.findAll(text);

  /// Returns [text] with accepted occurrences replaced by [maskCharacter].
  ///
  /// [maskCharacter] must contain exactly one Unicode scalar or an
  /// [ArgumentError] is thrown. Overlapping and touching ranges are merged,
  /// and one mask scalar replaces each original scalar in those ranges.
  String mask(String text, {String maskCharacter = '*'}) =>
      _matcher.mask(text, maskCharacter: maskCharacter);
}
