import 'package:flutter/material.dart';

/// Material 3 theme for SwissFuel, built from a single seed color.
class AppTheme {
  static const _seed = Color(0xFFD52B1E); // Swiss red

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
