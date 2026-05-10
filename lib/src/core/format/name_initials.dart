/// Builds two-letter display initials from names (aligned with profile first + last).
abstract final class NameInitials {
  NameInitials._();

  /// First character of the **first** word + first character of the **last** word.
  /// Example: `"Abdullah Khan"` → `"AK"`. One word → first two letters (`"Abdullah"` → `"AB"`).
  static String fromFullName(String raw) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final s = parts.single;
      if (s.length >= 2) {
        return s.substring(0, 2).toUpperCase();
      }
      return s.toUpperCase();
    }
    final first = parts.first;
    final last = parts.last;
    return '${first[0]}${last[0]}'.toUpperCase();
  }

  /// Uses API/profile fields directly when available (same rule as [fromFullName]).
  static String fromFirstLast(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '';
    if (l.isEmpty) return fromFullName(f);
    if (f.isEmpty) return fromFullName(l);
    return '${f[0]}${l[0]}'.toUpperCase();
  }
}
