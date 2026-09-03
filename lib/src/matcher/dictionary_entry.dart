import '../generated/dictionary_strict_data.g.dart';
import '../profanity_dictionary.dart';

enum MatchMode { substring, asciiWord, literal, choseong }

final class DictionaryEntry {
  const DictionaryEntry(this.pattern, this.canonical, this.tier, this.mode);

  final String pattern;
  final String canonical;
  final ProfanityTier tier;
  final MatchMode mode;
}

List<DictionaryEntry> bundledStrictEntries() => <DictionaryEntry>[
      ...entriesFromGenerated(
        generatedStrictSubstringWords,
        ProfanityTier.strict,
        MatchMode.substring,
      ),
      ...entriesFromGenerated(
        generatedStrictAsciiWordWords,
        ProfanityTier.strict,
        MatchMode.asciiWord,
      ),
      ...entriesFromGenerated(
        generatedStrictLiteralWords,
        ProfanityTier.strict,
        MatchMode.literal,
      ),
    ];

List<DictionaryEntry> bundledStrictChoseongEntries() => entriesFromGenerated(
      generatedStrictChoseongWords,
      ProfanityTier.strict,
      MatchMode.choseong,
    );

List<DictionaryEntry> bundledAllowEntries() => <DictionaryEntry>[
      ...entriesFromGenerated(
        generatedAllowSubstringWords,
        ProfanityTier.strict,
        MatchMode.substring,
      ),
      ...entriesFromGenerated(
        generatedAllowAsciiWordWords,
        ProfanityTier.strict,
        MatchMode.asciiWord,
      ),
      ...entriesFromGenerated(
        generatedAllowLiteralWords,
        ProfanityTier.strict,
        MatchMode.literal,
      ),
      ...entriesFromGenerated(
        generatedAllowChoseongWords,
        ProfanityTier.strict,
        MatchMode.choseong,
      ),
    ];

List<DictionaryEntry> entriesFromGenerated(
  Map<String, String> words,
  ProfanityTier tier,
  MatchMode mode,
) =>
    <DictionaryEntry>[
      for (final entry in words.entries)
        DictionaryEntry(entry.key, entry.value, tier, mode),
    ];
