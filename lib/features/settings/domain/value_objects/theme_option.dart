class ThemeOption {
  final String value;

  const ThemeOption._(this.value);

  static const List<String> supportedValues = ['light', 'dark', 'system'];

  static const ThemeOption light = ThemeOption._('light');
  static const ThemeOption dark = ThemeOption._('dark');
  static const ThemeOption system = ThemeOption._('system');

  static ThemeOption? fromString(String input) {
    final normalized = input.trim().toLowerCase();
    if (!supportedValues.contains(normalized)) return null;
    return ThemeOption._(normalized);
  }

  static bool isValid(String input) {
    return supportedValues.contains(input.trim().toLowerCase());
  }

  bool get isLight => value == 'light';
  bool get isDark => value == 'dark';
  bool get isSystem => value == 'system';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ThemeOption && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ThemeOption($value)';
}
