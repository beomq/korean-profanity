/// Optional strict-plus-lenient dictionary for Korean profanity filtering.
///
/// Import this library when context-sensitive lenient terms or bundled
/// choseong patterns are needed. It also exports the complete strict API.
library;

import 'src/bundled_dictionary.dart';
import 'src/generated/dictionary_lenient_data.g.dart';
import 'src/matcher/dictionary_entry.dart';
import 'src/profanity_dictionary.dart';

export 'korean_profanity.dart';

/// Cached bundled dictionary containing both strict and lenient entries.
///
/// Pass this value to `KoreanProfanityFilter.dictionary` with
/// [ProfanityTier.lenient] as the minimum tier. Set `choseongSearch` on the
/// filter separately when initial-consonant matching is wanted.
final ProfanityDictionary koreanLenientDictionary =
    createBundledProfanityDictionary(
  entries: <DictionaryEntry>[
    ...bundledStrictEntries(),
    ...entriesFromGenerated(
      generatedLenientSubstringWords,
      ProfanityTier.lenient,
      MatchMode.substring,
    ),
    ...entriesFromGenerated(
      generatedLenientAsciiWordWords,
      ProfanityTier.lenient,
      MatchMode.asciiWord,
    ),
    ...entriesFromGenerated(
      generatedLenientLiteralWords,
      ProfanityTier.lenient,
      MatchMode.literal,
    ),
  ],
  allowEntries: bundledAllowEntries(),
  choseongEntries: <DictionaryEntry>[
    ...bundledStrictChoseongEntries(),
    ...entriesFromGenerated(
      generatedLenientChoseongWords,
      ProfanityTier.lenient,
      MatchMode.choseong,
    ),
  ],
);
