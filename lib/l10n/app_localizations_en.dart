// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SwissFuel';

  @override
  String get navMap => 'Map';

  @override
  String get navNearby => 'Nearby';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get searchHint => 'Search place or station';

  @override
  String get filters => 'Filters';

  @override
  String get fuelType => 'Fuel type';

  @override
  String get brand => 'Brand';

  @override
  String get maxDistance => 'Max distance';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortPrice => 'Cheapest';

  @override
  String get sortName => 'Name';

  @override
  String get anyBrand => 'Any brand';

  @override
  String get applyFilters => 'Apply';

  @override
  String get resetFilters => 'Reset';

  @override
  String get fuelPetrol95 => 'Petrol 95';

  @override
  String get fuelPetrol98 => 'Petrol 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelLpg => 'LPG';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String get directions => 'Directions';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get noFavorites => 'No favorite stations yet';

  @override
  String get noStations => 'No stations found in this area';

  @override
  String get loadingStations => 'Loading stations…';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get pricesComingSoon => 'Community prices coming soon';

  @override
  String get locationDenied =>
      'Location permission denied. Showing default area.';

  @override
  String get locationDisabled => 'Location services are disabled.';

  @override
  String get recenter => 'Recenter';

  @override
  String get retry => 'Retry';

  @override
  String get unnamedStation => 'Fuel station';
}
