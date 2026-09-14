import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:swissfuel/core/providers.dart';
import 'package:swissfuel/features/stations/models/fuel_type.dart';
import 'package:swissfuel/features/stations/models/station.dart';

void main() {
  group('Station.fromOverpass', () {
    test('parses a node element with fuel tags', () {
      final station = Station.fromOverpass({
        'type': 'node',
        'id': 123,
        'lat': 47.37,
        'lon': 8.54,
        'tags': {
          'amenity': 'fuel',
          'name': 'Migrol Zürich',
          'brand': 'Migrol',
          'fuel:diesel': 'yes',
          'fuel:octane_95': 'yes',
          'fuel:lpg': 'no',
          'addr:street': 'Bahnhofstrasse',
          'addr:housenumber': '1',
          'addr:postcode': '8001',
          'addr:city': 'Zürich',
        },
      });

      expect(station, isNotNull);
      expect(station!.id, 'node/123');
      expect(station.name, 'Migrol Zürich');
      expect(station.brand, 'Migrol');
      expect(station.fuels, {FuelType.diesel, FuelType.petrol95});
      expect(station.fuels.contains(FuelType.lpg), isFalse);
      expect(station.address, 'Bahnhofstrasse 1, 8001 Zürich');
    });

    test('parses a way element using center coordinates', () {
      final station = Station.fromOverpass({
        'type': 'way',
        'id': 987,
        'center': {'lat': 46.2, 'lon': 6.14},
        'tags': {'amenity': 'fuel'},
      });

      expect(station, isNotNull);
      expect(station!.id, 'way/987');
      expect(station.position.latitude, 46.2);
      expect(station.fuels, isEmpty);
    });

    test('returns null when coordinates are missing', () {
      final station = Station.fromOverpass({
        'type': 'way',
        'id': 5,
        'tags': {'amenity': 'fuel'},
      });
      expect(station, isNull);
    });

    test('round-trips through JSON', () {
      final original = Station.fromOverpass({
        'type': 'node',
        'id': 1,
        'lat': 47.0,
        'lon': 8.0,
        'tags': {'name': 'Test', 'fuel:diesel': 'yes'},
      })!;
      final restored = Station.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.fuels, original.fuels);
      expect(restored.position.latitude, original.position.latitude);
    });
  });

  group('Station.fromTomTom', () {
    test('parses a result with poi, brand and address', () {
      final station = Station.fromTomTom({
        'id': 'CH/POI/p0/12345',
        'poi': {
          'name': 'Coop Pronto Bern',
          'brands': [
            {'name': 'Coop'}
          ],
        },
        'address': {'freeformAddress': 'Bahnhofplatz 1, 3011 Bern'},
        'position': {'lat': 46.948, 'lon': 7.447},
      });

      expect(station, isNotNull);
      expect(station!.id, 'tomtom/CH/POI/p0/12345');
      expect(station.name, 'Coop Pronto Bern');
      expect(station.brand, 'Coop');
      expect(station.address, 'Bahnhofplatz 1, 3011 Bern');
      // TomTom Search carries no per-fuel availability.
      expect(station.fuels, isEmpty);
    });

    test('composes an address from parts when no freeform is given', () {
      final station = Station.fromTomTom({
        'id': 'x',
        'position': {'lat': 47.0, 'lon': 8.0},
        'address': {
          'streetName': 'Seestrasse',
          'streetNumber': '5',
          'postalCode': '8002',
          'municipality': 'Zürich',
        },
      });
      expect(station!.address, 'Seestrasse 5, 8002 Zürich');
    });

    test('returns null when position is missing', () {
      final station = Station.fromTomTom({'id': 'x', 'poi': {}});
      expect(station, isNull);
    });
  });

  group('Station.enrichedWith', () {
    test('adds OSM fuel tags and fills missing fields', () {
      final tomtom = Station.fromTomTom({
        'id': 'x',
        'poi': {
          'brands': [
            {'name': 'Migrol'}
          ]
        },
        'position': {'lat': 47.0, 'lon': 8.0},
      })!;
      final osm = Station.fromOverpass({
        'type': 'node',
        'id': 1,
        'lat': 47.0,
        'lon': 8.0,
        'tags': {
          'name': 'Migrol Service',
          'fuel:diesel': 'yes',
          'fuel:octane_95': 'yes',
          'opening_hours': '24/7',
        },
      })!;

      final merged = tomtom.enrichedWith(osm);
      expect(merged.brand, 'Migrol'); // kept from TomTom
      expect(merged.name, 'Migrol Service'); // filled from OSM
      expect(merged.openingHours, '24/7');
      expect(merged.fuels, {FuelType.diesel, FuelType.petrol95});
    });
  });

  group('distanceKmTo', () {
    test('computes a plausible distance', () {
      final station = Station(
        id: 'node/1',
        position: const LatLng(47.3769, 8.5417), // Zürich
      );
      // Bern is roughly 95 km from Zürich.
      final km = distanceKmTo(const LatLng(46.9480, 7.4474), station);
      expect(km, greaterThan(80));
      expect(km, lessThan(110));
    });
  });
}
