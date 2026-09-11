// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'SwissFuel';

  @override
  String get navMap => 'Karte';

  @override
  String get navNearby => 'In der Nähe';

  @override
  String get navFavorites => 'Favoriten';

  @override
  String get searchHint => 'Ort oder Tankstelle suchen';

  @override
  String get filters => 'Filter';

  @override
  String get fuelType => 'Kraftstoff';

  @override
  String get brand => 'Marke';

  @override
  String get maxDistance => 'Max. Distanz';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortDistance => 'Distanz';

  @override
  String get sortPrice => 'Günstigste';

  @override
  String get sortName => 'Name';

  @override
  String get anyBrand => 'Alle Marken';

  @override
  String get applyFilters => 'Anwenden';

  @override
  String get resetFilters => 'Zurücksetzen';

  @override
  String get fuelPetrol95 => 'Benzin 95';

  @override
  String get fuelPetrol98 => 'Benzin 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelLpg => 'Autogas';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String get directions => 'Route';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get noFavorites => 'Noch keine Favoriten';

  @override
  String get noStations => 'Keine Tankstellen in diesem Gebiet gefunden';

  @override
  String get loadingStations => 'Tankstellen werden geladen…';

  @override
  String get openingHours => 'Öffnungszeiten';

  @override
  String get pricesComingSoon => 'Community-Preise folgen bald';

  @override
  String get locationDenied =>
      'Standortberechtigung verweigert. Standardgebiet wird angezeigt.';

  @override
  String get locationDisabled => 'Standortdienste sind deaktiviert.';

  @override
  String get recenter => 'Zentrieren';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get unnamedStation => 'Tankstelle';
}
