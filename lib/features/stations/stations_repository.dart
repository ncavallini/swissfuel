import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'models/station.dart';

/// Fetches fuel stations from the OpenStreetMap Overpass API, with a simple
/// in-memory TTL cache to respect Overpass rate limits while panning the map.
class StationsRepository {
  StationsRepository({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        _endpoint = endpoint ??
            Uri.parse('https://overpass-api.de/api/interpreter');

  final http.Client _client;
  final Uri _endpoint;

  static const Duration _ttl = Duration(minutes: 5);

  /// When fetching we expand the requested box by this fraction on each side so
  /// small pans are served from cache.
  static const double _expand = 0.35;

  final List<_CachedRegion> _cache = [];

  /// Returns stations whose position falls within [bounds].
  ///
  /// Reuses a cached region if a fresh one fully contains [bounds]; otherwise
  /// fetches an expanded area from Overpass and caches it.
  Future<List<Station>> fetchInBounds(LatLngBounds bounds) async {
    _pruneExpired();

    for (final region in _cache) {
      if (region.contains(bounds)) {
        return region.stationsWithin(bounds);
      }
    }

    final expanded = _expandBounds(bounds, _expand);
    final stations = await _queryOverpass(expanded);
    _cache.add(_CachedRegion(
      bounds: expanded,
      stations: stations,
      fetchedAt: DateTime.now(),
    ));
    // Keep the cache small.
    if (_cache.length > 12) _cache.removeAt(0);

    return _CachedRegion(bounds: expanded, stations: stations, fetchedAt: DateTime.now())
        .stationsWithin(bounds);
  }

  Future<List<Station>> _queryOverpass(LatLngBounds b) async {
    final s = b.south, w = b.west, n = b.north, e = b.east;
    final query = '[out:json][timeout:25];'
        '(node["amenity"="fuel"]($s,$w,$n,$e);'
        'way["amenity"="fuel"]($s,$w,$n,$e);'
        'relation["amenity"="fuel"]($s,$w,$n,$e););'
        'out center;';

    final response = await _client.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        // Overpass rejects requests without an identifying User-Agent (HTTP 406).
        'User-Agent': 'SwissFuel/1.0 (community fuel price app)',
      },
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw StationsException('Overpass error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List?) ?? const [];
    final stations = <String, Station>{};
    for (final element in elements) {
      if (element is Map<String, dynamic>) {
        final station = Station.fromOverpass(element);
        if (station != null) stations[station.id] = station;
      }
    }
    return stations.values.toList(growable: false);
  }

  void _pruneExpired() {
    final now = DateTime.now();
    _cache.removeWhere((r) => now.difference(r.fetchedAt) > _ttl);
  }

  LatLngBounds _expandBounds(LatLngBounds b, double fraction) {
    final latPad = (b.north - b.south) * fraction;
    final lonPad = (b.east - b.west) * fraction;
    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lonPad),
      LatLng(b.north + latPad, b.east + lonPad),
    );
  }

  void dispose() => _client.close();
}

class StationsException implements Exception {
  StationsException(this.message);
  final String message;
  @override
  String toString() => 'StationsException: $message';
}

class _CachedRegion {
  _CachedRegion({
    required this.bounds,
    required this.stations,
    required this.fetchedAt,
  });

  final LatLngBounds bounds;
  final List<Station> stations;
  final DateTime fetchedAt;

  bool contains(LatLngBounds other) =>
      bounds.south <= other.south &&
      bounds.north >= other.north &&
      bounds.west <= other.west &&
      bounds.east >= other.east;

  List<Station> stationsWithin(LatLngBounds b) => stations
      .where((s) =>
          s.position.latitude >= b.south &&
          s.position.latitude <= b.north &&
          s.position.longitude >= b.west &&
          s.position.longitude <= b.east)
      .toList(growable: false);
}
