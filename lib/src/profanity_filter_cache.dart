import 'profanity_matcher.dart';

/// Isolate-local cache for the uncustomized bundled matcher.
///
/// Dart isolates do not share mutable memory, so each isolate lazily creates at
/// most one matcher. Every default filter in that isolate reuses that matcher.
final class DefaultMatcherCache {
  DefaultMatcherCache._();

  static int _acquisitionCount = 0;
  static int _buildCount = 0;

  static ProfanityMatcher acquire() {
    _acquisitionCount++;
    return _matcher;
  }

  static final ProfanityMatcher _matcher = _build();

  static ProfanityMatcher _build() {
    _buildCount++;
    return ProfanityMatcher();
  }
}

/// Internal observability for cache behavior tests.
///
/// This seam is intentionally absent from the package's public exports.
final class DefaultMatcherCacheTestSeam {
  DefaultMatcherCacheTestSeam._();

  static int get acquisitionCount => DefaultMatcherCache._acquisitionCount;
  static int get buildCount => DefaultMatcherCache._buildCount;
}
