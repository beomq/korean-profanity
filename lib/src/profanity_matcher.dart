import 'bundled_dictionary.dart';
import 'matcher/dictionary_entry.dart';
import 'matcher/mask_ranges.dart';
import 'matcher/match_policy.dart';
import 'matcher/pattern_scanner.dart';
import 'normalizer.dart';
import 'profanity_dictionary.dart';
import 'profanity_match.dart';

/// Internal immutable orchestration for normalization and match policy.
final class ProfanityMatcher {
  factory ProfanityMatcher({
    ProfanityDictionary? dictionary,
    ProfanityTier minimumTier = ProfanityTier.strict,
    Iterable<String> addedWords = const <String>[],
    Iterable<String> removedWords = const <String>[],
    Iterable<String> ignoreWords = const <String>[],
    bool choseongSearch = false,
  }) {
    final enablesLenient = minimumTier == ProfanityTier.lenient;
    if (dictionary != null) _validateDictionary(dictionary);
    final entries = dictionary == null
        ? bundledStrictEntries()
        : _dictionaryEntries(dictionary, includeLenient: enablesLenient);
    final metadata =
        dictionary == null ? null : bundledDictionaryData(dictionary);
    final allows = dictionary == null
        ? bundledAllowEntries()
        : metadata?.allowEntries ?? _customAllowEntries(dictionary);
    final availableChoseong = dictionary == null
        ? bundledStrictChoseongEntries()
        : metadata?.choseongEntries ?? _customChoseongEntries(dictionary);
    final choseong = [
      for (final entry in availableChoseong)
        if (entry.tier == ProfanityTier.strict || enablesLenient) entry,
    ];
    return ProfanityMatcher._build(
      entries,
      allows,
      choseong,
      addedWords,
      removedWords,
      ignoreWords,
      choseongSearch,
    );
  }

  ProfanityMatcher._(
    this._entries,
    this._allowEntries,
    this._choseongEntries,
    this._choseongSearch,
  );

  factory ProfanityMatcher._build(
    List<DictionaryEntry> entries,
    List<DictionaryEntry> allowEntries,
    List<DictionaryEntry> choseongEntries,
    Iterable<String> addedWords,
    Iterable<String> removedWords,
    Iterable<String> ignoreWords,
    bool choseongSearch,
  ) {
    final removals = removedWords.map(_normalizeWord).toSet();
    final active = <DictionaryEntry>[
      for (final entry in entries)
        if (!removals.contains(_normalizeWord(entry.pattern)) &&
            !removals.contains(_normalizeWord(entry.canonical)))
          _normalizeEntry(entry),
      for (final word in addedWords)
        DictionaryEntry(
          _normalizeWord(word),
          _normalizeWord(word),
          ProfanityTier.strict,
          MatchMode.substring,
        ),
    ];
    final normalizedChoseong = [
      for (final entry in choseongEntries)
        if (!removals.contains(_normalizeWord(entry.pattern)) &&
            !removals.contains(_normalizeWord(entry.canonical)))
          _normalizeEntry(entry),
    ];
    _rejectDuplicates(active, 'dictionary');
    _rejectDuplicates(normalizedChoseong, 'choseongPatterns');
    final activeChoseong =
        choseongSearch ? normalizedChoseong : const <DictionaryEntry>[];

    final allowsByPattern = <String, DictionaryEntry>{
      for (final entry in allowEntries)
        _normalizeWord(entry.pattern): _normalizeEntry(entry),
      for (final word in ignoreWords)
        _normalizeWord(word): DictionaryEntry(
          _normalizeWord(word),
          _normalizeWord(word),
          ProfanityTier.strict,
          MatchMode.substring,
        ),
    };
    return ProfanityMatcher._(
      List.unmodifiable(active),
      List.unmodifiable(allowsByPattern.values),
      List.unmodifiable(activeChoseong),
      choseongSearch,
    );
  }

  final List<DictionaryEntry> _entries;
  final List<DictionaryEntry> _allowEntries;
  final List<DictionaryEntry> _choseongEntries;
  final bool _choseongSearch;

  late final PatternScanner? _scanner =
      _entries.isEmpty ? null : PatternScanner(_entries);
  late final PatternScanner? _allowScanner =
      _allowEntries.isEmpty ? null : PatternScanner(_allowEntries);
  late final PatternScanner? _choseongScanner =
      _choseongEntries.isEmpty ? null : PatternScanner(_choseongEntries);

  bool contains(String text) => findAll(text).isNotEmpty;

  List<ProfanityMatch> findAll(String text) {
    if (text.isEmpty) return const <ProfanityMatch>[];
    return evaluateMatches(
      normalizeText(text),
      _scanner,
      _allowScanner,
      _choseongScanner,
      choseongSearch: _choseongSearch,
    );
  }

  String mask(String text, {String maskCharacter = '*'}) => maskMatches(
        text,
        findAll(text),
        maskCharacter: maskCharacter,
      );
}

void _validateDictionary(ProfanityDictionary dictionary) {
  final entries = _dictionaryEntries(dictionary, includeLenient: true)
      .map(_normalizeEntry)
      .toList();
  _rejectDuplicates(entries, 'dictionary');
  final metadata = bundledDictionaryData(dictionary);
  final allows = (metadata?.allowEntries ?? _customAllowEntries(dictionary))
      .map(_normalizeEntry)
      .toList();
  if (allows.map((entry) => entry.pattern).toSet().length != allows.length) {
    throw ArgumentError.value(allows, 'allowWords', 'normalized duplicate');
  }
  final choseong =
      (metadata?.choseongEntries ?? _customChoseongEntries(dictionary))
          .map(_normalizeEntry)
          .toList();
  _rejectDuplicates(choseong, 'choseongPatterns');
}

List<DictionaryEntry> _dictionaryEntries(
  ProfanityDictionary dictionary, {
  required bool includeLenient,
}) {
  final metadata = bundledDictionaryData(dictionary);
  if (metadata != null) {
    return <DictionaryEntry>[
      for (final entry in metadata.entries)
        if (entry.tier == ProfanityTier.strict || includeLenient) entry,
    ];
  }
  return <DictionaryEntry>[
    for (final word in dictionary.strictWords)
      DictionaryEntry(word, word, ProfanityTier.strict, MatchMode.substring),
    if (includeLenient)
      for (final word in dictionary.lenientWords)
        DictionaryEntry(
          word,
          word,
          ProfanityTier.lenient,
          MatchMode.substring,
        ),
  ];
}

List<DictionaryEntry> _customAllowEntries(ProfanityDictionary dictionary) =>
    <DictionaryEntry>[
      for (final word in dictionary.allowWords)
        DictionaryEntry(word, word, ProfanityTier.strict, MatchMode.substring),
    ];

List<DictionaryEntry> _customChoseongEntries(
  ProfanityDictionary dictionary,
) =>
    <DictionaryEntry>[
      for (final pattern in dictionary.choseongPatterns)
        DictionaryEntry(
          pattern,
          pattern,
          ProfanityTier.lenient,
          MatchMode.choseong,
        ),
    ];

DictionaryEntry _normalizeEntry(DictionaryEntry entry) => DictionaryEntry(
      _normalizeWord(entry.pattern),
      _normalizeWord(entry.canonical),
      entry.tier,
      entry.mode,
    );

String _normalizeWord(String word) {
  if (word.isEmpty || word.trim().isEmpty) {
    throw ArgumentError.value(word, 'word', 'must not be empty');
  }
  final normalized = normalizeText(word).canonical;
  if (normalized.isEmpty) {
    throw ArgumentError.value(word, 'word', 'must normalize to content');
  }
  return normalized;
}

void _rejectDuplicates(List<DictionaryEntry> entries, String name) {
  final seen = <String>{};
  for (final entry in entries) {
    if (!seen.add(entry.pattern)) {
      throw ArgumentError.value(entry.pattern, name, 'normalized duplicate');
    }
  }
}
