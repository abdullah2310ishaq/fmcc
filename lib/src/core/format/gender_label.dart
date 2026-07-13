/// Normalizes API gender values to full display labels.
abstract final class GenderLabel {
  GenderLabel._();

  /// Returns `Male`, `Female`, the original trimmed value, or [fallback].
  static String format(String? gender, {String fallback = '—'}) {
    final raw = gender?.trim() ?? '';
    if (raw.isEmpty) return fallback;

    final g = raw.toLowerCase();
    if (g == 'male' || g == 'm') return 'Male';
    if (g == 'female' || g == 'f') return 'Female';
    if (g.startsWith('mal')) return 'Male';
    if (g.startsWith('fem')) return 'Female';

    return raw;
  }

  static bool isMale(String? gender) {
    final g = gender?.trim().toLowerCase() ?? '';
    return g == 'male' || g == 'm' || g.startsWith('mal');
  }

  static bool isFemale(String? gender) {
    final g = gender?.trim().toLowerCase() ?? '';
    return g == 'female' || g == 'f' || g.startsWith('fem');
  }
}
