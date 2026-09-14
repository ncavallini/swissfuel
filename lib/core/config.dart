/// Build-time configuration, supplied via `--dart-define` so secrets stay out
/// of source control.
///
/// Example:
/// ```
/// flutter run --dart-define=TOMTOM_API_KEY=your_key_here
/// ```
class AppConfig {
  const AppConfig._();

  /// TomTom Search API key. When empty the app falls back to the free
  /// OpenStreetMap Overpass source for station locations.
  static const String tomTomApiKey =
      String.fromEnvironment('TOMTOM_API_KEY');

  static bool get hasTomTom => tomTomApiKey.isNotEmpty;
}
