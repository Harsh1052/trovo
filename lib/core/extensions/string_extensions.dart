extension StringExtensions on String {
  /// "hello world" → "Hello World"
  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  /// "hello_world" → "Hello World"
  String get snakeCaseToTitle => replaceAll('_', ' ').titleCase;

  /// Trims and lowercases for answer comparison.
  String get normalised => trim().toLowerCase();

  /// Returns null if blank, otherwise the trimmed value.
  String? get nullIfEmpty => trim().isEmpty ? null : trim();

  /// Simple initials: "John Doe" → "JD", "Alice" → "A"
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Truncates to [maxLength] chars and adds "…" if needed.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}
