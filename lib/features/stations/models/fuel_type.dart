import '../../../l10n/app_localizations.dart';

/// Fuel types relevant for the Swiss market, mapped to their OpenStreetMap
/// `fuel:*` tag keys used on `amenity=fuel` nodes.
enum FuelType {
  petrol95('fuel:octane_95'),
  petrol98('fuel:octane_98'),
  diesel('fuel:diesel'),
  lpg('fuel:lpg'),
  cng('fuel:cng'),
  adblue('fuel:adblue');

  const FuelType(this.osmTag);

  /// The OSM tag key indicating the station offers this fuel (value "yes").
  final String osmTag;

  String label(AppLocalizations l10n) {
    switch (this) {
      case FuelType.petrol95:
        return l10n.fuelPetrol95;
      case FuelType.petrol98:
        return l10n.fuelPetrol98;
      case FuelType.diesel:
        return l10n.fuelDiesel;
      case FuelType.lpg:
        return l10n.fuelLpg;
      case FuelType.cng:
        return l10n.fuelCng;
      case FuelType.adblue:
        return l10n.fuelAdblue;
    }
  }
}
