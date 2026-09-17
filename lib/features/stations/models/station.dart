import 'package:latlong2/latlong.dart';

import 'fuel_type.dart';

/// A fuel station sourced from OpenStreetMap (`amenity=fuel`).
class Station {
  const Station({
    required this.id,
    required this.position,
    this.name,
    this.brand,
    this.operator,
    this.openingHours,
    this.address,
    this.fuels = const {},
    this.tags = const {},
  });

  /// Stable OSM identity, e.g. `node/123456` or `way/987654`.
  final String id;
  final LatLng position;
  final String? name;
  final String? brand;
  final String? operator;
  final String? openingHours;
  final String? address;

  /// Fuel types the station is tagged as offering.
  final Set<FuelType> fuels;

  /// Raw OSM tags, kept for the detail view and future use.
  final Map<String, String> tags;

  /// Best available human label for the station.
  String get displayName => name ?? brand ?? operator ?? '';

  Station copyWith({
    String? name,
    String? brand,
    String? operator,
    String? openingHours,
    String? address,
    Set<FuelType>? fuels,
    Map<String, String>? tags,
  }) {
    return Station(
      id: id,
      position: position,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      operator: operator ?? this.operator,
      openingHours: openingHours ?? this.openingHours,
      address: address ?? this.address,
      fuels: fuels ?? this.fuels,
      tags: tags ?? this.tags,
    );
  }

  /// Returns a copy enriched from a nearby [other] station: this station's own
  /// values win, and any missing name/brand/operator/opening-hours/address
  /// fields are filled from [other]; fuel sets are unioned. Used to combine an
  /// OSM station (per-fuel tags) with its TomTom match (cleaner brand/name).
  Station enrichedWith(Station other) {
    return copyWith(
      name: name ?? other.name,
      brand: brand ?? other.brand,
      operator: operator ?? other.operator,
      openingHours: openingHours ?? other.openingHours,
      address: address ?? other.address,
      fuels: {...fuels, ...other.fuels},
    );
  }

  /// Builds a [Station] from a TomTom Search API result element.
  ///
  /// TomTom is the authoritative source for station locations and brands; it
  /// does not expose per-fuel availability, so [fuels] is left empty here and
  /// enriched from OpenStreetMap where a nearby match exists.
  static Station? fromTomTom(Map<String, dynamic> element) {
    final id = element['id'];
    final position = element['position'];
    if (id == null || position is! Map) return null;
    final lat = (position['lat'] as num?)?.toDouble();
    final lon = (position['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final poi = (element['poi'] as Map?) ?? const {};
    final brands = (poi['brands'] as List?) ?? const [];
    final brand = brands.isNotEmpty && brands.first is Map
        ? (brands.first as Map)['name']?.toString()
        : null;

    return Station(
      id: 'tomtom/$id',
      position: LatLng(lat, lon),
      name: poi['name']?.toString(),
      brand: brand,
      openingHours: _tomTomOpeningHours(poi['openingHours']),
      address: _tomTomAddress(element['address']),
    );
  }

  static String? _tomTomOpeningHours(Object? openingHours) {
    if (openingHours is Map) {
      final text = openingHours['text'];
      if (text != null) return text.toString();
    }
    return null;
  }

  static String? _tomTomAddress(Object? address) {
    if (address is! Map) return null;
    final freeform = address['freeformAddress'];
    if (freeform != null) return freeform.toString();
    final street = address['streetName']?.toString();
    final number = address['streetNumber']?.toString();
    final postcode = address['postalCode']?.toString();
    final city = address['municipality']?.toString();
    final line1 = [street, number].where((e) => e != null).join(' ').trim();
    final line2 = [postcode, city].where((e) => e != null).join(' ').trim();
    final parts = [line1, line2].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Builds a [Station] from an Overpass API element.
  ///
  /// Handles both `node` elements (with `lat`/`lon`) and `way`/`relation`
  /// elements (which carry a `center` object when queried with `out center`).
  static Station? fromOverpass(Map<String, dynamic> element) {
    final type = element['type'] as String?;
    final osmId = element['id'];
    if (type == null || osmId == null) return null;

    double? lat = (element['lat'] as num?)?.toDouble();
    double? lon = (element['lon'] as num?)?.toDouble();
    final center = element['center'];
    if ((lat == null || lon == null) && center is Map) {
      lat = (center['lat'] as num?)?.toDouble();
      lon = (center['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final rawTags = (element['tags'] as Map?) ?? const {};
    final tags = <String, String>{
      for (final entry in rawTags.entries)
        entry.key.toString(): entry.value.toString(),
    };

    final fuels = <FuelType>{
      for (final type in FuelType.values)
        if (_isYes(tags[type.osmTag])) type,
    };

    return Station(
      id: '$type/$osmId',
      position: LatLng(lat, lon),
      name: tags['name'],
      brand: tags['brand'],
      operator: tags['operator'],
      openingHours: tags['opening_hours'],
      address: _composeAddress(tags),
      fuels: fuels,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lon': position.longitude,
        if (name != null) 'name': name,
        if (brand != null) 'brand': brand,
        if (operator != null) 'operator': operator,
        if (openingHours != null) 'opening_hours': openingHours,
        if (address != null) 'address': address,
        'fuels': fuels.map((f) => f.name).toList(),
        'tags': tags,
      };

  static Station fromJson(Map<String, dynamic> json) {
    final fuelNames = (json['fuels'] as List?)?.cast<String>() ?? const [];
    return Station(
      id: json['id'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lon'] as num).toDouble(),
      ),
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      operator: json['operator'] as String?,
      openingHours: json['opening_hours'] as String?,
      address: json['address'] as String?,
      fuels: {
        for (final f in FuelType.values)
          if (fuelNames.contains(f.name)) f,
      },
      tags: (json['tags'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
    );
  }

  static bool _isYes(String? value) {
    if (value == null) return false;
    final v = value.toLowerCase();
    return v == 'yes' || v == 'true' || v == '1';
  }

  static String? _composeAddress(Map<String, String> tags) {
    final street = tags['addr:street'];
    final number = tags['addr:housenumber'];
    final postcode = tags['addr:postcode'];
    final city = tags['addr:city'];
    final line1 = [street, number].where((e) => e != null).join(' ').trim();
    final line2 = [postcode, city].where((e) => e != null).join(' ').trim();
    final parts = [line1, line2].where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
