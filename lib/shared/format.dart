import '../l10n/app_localizations.dart';

/// Formats a distance in kilometers into a localized, human-friendly string.
String formatDistance(AppLocalizations l10n, double km) {
  if (km < 1) {
    return l10n.distanceM((km * 1000).round().toString());
  }
  return l10n.distanceKm(km.toStringAsFixed(km < 10 ? 1 : 0));
}
