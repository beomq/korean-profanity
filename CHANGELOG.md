## 0.1.0

- Added immutable synchronous APIs for profanity detection, detailed matches,
  masking, and constructor-only dictionary customization.
- Added conservative Korean evasion handling with exact UTF-16 source spans,
  ASCII word boundaries, occurrence-scoped allowlists, and deterministic
  overlap ordering.
- Added a small strict bundled dictionary and a separately imported lenient
  dictionary, generated deterministically from reviewed source records.
- Added explicit third-party data provenance and licensing notices. Some
  reviewed candidate material has unknown upstream license and provenance;
  see `THIRD_PARTY_NOTICES.md` before redistribution.
