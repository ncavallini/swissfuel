// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SwissFuel';

  @override
  String get navMap => 'Carte';

  @override
  String get navNearby => 'À proximité';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get searchHint => 'Rechercher un lieu ou une station';

  @override
  String get filters => 'Filtres';

  @override
  String get fuelType => 'Carburant';

  @override
  String get brand => 'Marque';

  @override
  String get maxDistance => 'Distance max.';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortPrice => 'Moins cher';

  @override
  String get sortName => 'Nom';

  @override
  String get anyBrand => 'Toutes les marques';

  @override
  String get applyFilters => 'Appliquer';

  @override
  String get resetFilters => 'Réinitialiser';

  @override
  String get fuelPetrol95 => 'Essence 95';

  @override
  String get fuelPetrol98 => 'Essence 98';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelLpg => 'GPL';

  @override
  String get fuelCng => 'GNC';

  @override
  String get fuelAdblue => 'AdBlue';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String get directions => 'Itinéraire';

  @override
  String get addFavorite => 'Ajouter aux favoris';

  @override
  String get removeFavorite => 'Retirer des favoris';

  @override
  String get noFavorites => 'Aucune station favorite';

  @override
  String get noStations => 'Aucune station trouvée dans cette zone';

  @override
  String get loadingStations => 'Chargement des stations…';

  @override
  String get openingHours => 'Heures d\'ouverture';

  @override
  String get pricesComingSoon => 'Prix communautaires bientôt disponibles';

  @override
  String get locationDenied =>
      'Autorisation de localisation refusée. Zone par défaut affichée.';

  @override
  String get locationDisabled =>
      'Les services de localisation sont désactivés.';

  @override
  String get recenter => 'Recentrer';

  @override
  String get retry => 'Réessayer';

  @override
  String get unnamedStation => 'Station-service';
}
