import 'matcher/dictionary_entry.dart';
import 'profanity_dictionary.dart';

final Expando<BundledDictionaryData> _bundledData =
    Expando<BundledDictionaryData>('bundled profanity metadata');

final class BundledDictionaryData {
  BundledDictionaryData({
    required Iterable<DictionaryEntry> entries,
    required Iterable<DictionaryEntry> allowEntries,
    required Iterable<DictionaryEntry> choseongEntries,
  })  : entries = List.unmodifiable(entries),
        allowEntries = List.unmodifiable(allowEntries),
        choseongEntries = List.unmodifiable(choseongEntries);

  final List<DictionaryEntry> entries;
  final List<DictionaryEntry> allowEntries;
  final List<DictionaryEntry> choseongEntries;
}

ProfanityDictionary createBundledProfanityDictionary({
  required Iterable<DictionaryEntry> entries,
  required Iterable<DictionaryEntry> allowEntries,
  required Iterable<DictionaryEntry> choseongEntries,
}) {
  final data = BundledDictionaryData(
    entries: entries,
    allowEntries: allowEntries,
    choseongEntries: choseongEntries,
  );
  final dictionary = ProfanityDictionary(
    strictWords: data.entries
        .where((entry) => entry.tier == ProfanityTier.strict)
        .map((entry) => entry.pattern),
    lenientWords: data.entries
        .where((entry) => entry.tier == ProfanityTier.lenient)
        .map((entry) => entry.pattern),
    allowWords: data.allowEntries.map((entry) => entry.pattern),
    choseongPatterns: data.choseongEntries.map((entry) => entry.pattern),
  );
  _bundledData[dictionary] = data;
  return dictionary;
}

BundledDictionaryData? bundledDictionaryData(
  ProfanityDictionary dictionary,
) =>
    _bundledData[dictionary];
