class AppSettings {
  const AppSettings({
    required this.isDarkMode,
    this.lastOpenedAt,
  });

  final bool isDarkMode;
  final DateTime? lastOpenedAt;

  AppSettings copyWith({
    bool? isDarkMode,
    DateTime? lastOpenedAt,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
