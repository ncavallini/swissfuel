// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'SwissFuel';

  @override
  String get navMap => 'Mappa';

  @override
  String get navNearby => 'Vicino a te';

  @override
  String get navFavorites => 'Preferiti';

  @override
  String get searchHint => 'Cerca luogo o stazione';

  @override
  String get filters => 'Filtri';

  @override
  String get fuelType => 'Carburante';

  @override
  String get brand => 'Marca';

  @override
  String get maxDistance => 'Distanza max.';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get sortDistance => 'Distanza';

  @override
  String get sortPrice => 'Più economico';

  @override
  String get sortName => 'Nome';

  @override
  String get anyBrand => 'Tutte le marche';

  @override
  String get applyFilters => 'Applica';

  @override
  String get resetFilters => 'Reimposta';

  @override
  String get fuelPetrol95 => 'Benzina 95';

  @override
  String get fuelPetrol98 => 'Benzina 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelLpg => 'GPL';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String get directions => 'Indicazioni';

  @override
  String get addFavorite => 'Aggiungi ai preferiti';

  @override
  String get removeFavorite => 'Rimuovi dai preferiti';

  @override
  String get noFavorites => 'Nessuna stazione preferita';

  @override
  String get noStations => 'Nessuna stazione trovata in questa zona';

  @override
  String get loadingStations => 'Caricamento stazioni…';

  @override
  String get openingHours => 'Orari di apertura';

  @override
  String get pricesComingSoon => 'Prezzi della community in arrivo';

  @override
  String get locationDenied =>
      'Permesso di localizzazione negato. Zona predefinita mostrata.';

  @override
  String get locationDisabled =>
      'I servizi di localizzazione sono disattivati.';

  @override
  String get recenter => 'Ricentra';

  @override
  String get retry => 'Riprova';

  @override
  String get unnamedStation => 'Stazione di servizio';
}
