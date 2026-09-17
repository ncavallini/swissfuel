import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'models/station.dart';

/// Source of fuel-station locations for a visible map area.
///
/// Implementations share a simple in-memory TTL cache (see [fetchInBounds]) so
/// small pans are served without re-querying the network; subclasses only need
/// to implement [queryRegion].
abstract class StationsRepository {
  static const Duration _ttl = Duration(minutes: 5);

  /// When fetching we expand the requested box by this fraction on each side so
  /// small pans are served from cache.
  static const double _expand = 0.35;

  final List<_CachedRegion> _cache = [];

  /// Returns stations whose position falls within [bounds].
  ///
  /// Reuses a cached region if a fresh one fully contains [bounds]; otherwise
  /// fetches an expanded area and caches it.
  Future<List<Station>> fetchInBounds(LatLngBounds bounds) async {
    _pruneExpired();

    for (final region in _cache) {
      if (region.contains(bounds)) {
        return region.stationsWithin(bounds);
      }
    }

    final expanded = expandBounds(bounds, _expand);
    final stations = await queryRegion(expanded);
    final region = _CachedRegion(
      bounds: expanded,
      stations: stations,
      fetchedAt: DateTime.now(),
    );
    _cache.add(region);
    // Keep the cache small.
    if (_cache.length > 12) _cache.removeAt(0);

    return region.stationsWithin(bounds);
  }

  /// Fetches every station within [bounds] from the underlying source.
  Future<List<Station>> queryRegion(LatLngBounds bounds);

  void dispose();

  void _pruneExpired() {
    final now = DateTime.now();
    _cache.removeWhere((r) => now.difference(r.fetchedAt) > _ttl);
  }

  static LatLngBounds expandBounds(LatLngBounds b, double fraction) {
    final latPad = (b.north - b.south) * fraction;
    final lonPad = (b.east - b.west) * fraction;
    return LatLngBounds(
      LatLng(b.south - latPad, b.west - lonPad),
      LatLng(b.north + latPad, b.east + lonPad),
    );
  }
}

/// Fetches stations from the OpenStreetMap Overpass API (free, no key).
class OsmStationsRepository extends StationsRepository {
  OsmStationsRepository({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        _endpoint = endpoint ??
            Uri.parse('https://overpass-api.de/api/interpreter');

  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<List<Station>> queryRegion(LatLngBounds b) async {
    final s = b.south, w = b.west, n = b.north, e = b.east;
    final query = '[out:json][timeout:25];'
        '(node["amenity"="fuel"]($s,$w,$n,$e);'
        'way["amenity"="fuel"]($s,$w,$n,$e);'
        'relation["amenity"="fuel"]($s,$w,$n,$e););'
        'out center;';

    final response = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            // Overpass rejects requests without an identifying User-Agent (406).
            'User-Agent': 'SwissFuel/1.0 (community fuel price app)',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 25));

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

  @override
  void dispose() => _client.close();
}

/// Fetches stations from the TomTom Search API (Category Search, category
/// `7311` = petrol station). Authoritative for locations and brands, but does
/// not expose per-fuel availability.
class TomTomStationsRepository extends StationsRepository {
  TomTomStationsRepository({
    required String apiKey,
    http.Client? client,
    String host = 'api.tomtom.com',
  })  : _apiKey = apiKey,
        _host = host,
        _client = client ?? http.Client();

  final String _apiKey;
  final String _host;
  final http.Client _client;

  /// TomTom POI category id for petrol/gas stations.
  static const String _petrolStationCategory = '7311';

  @override
  Future<List<Station>> queryRegion(LatLngBounds b) async {
    // Category Search takes a top-left / bottom-right box (lat,lon each).
    final uri = Uri.https(_host, '/search/2/categorySearch/fuel.json', {
      'key': _apiKey,
      'categorySet': _petrolStationCategory,
      'countrySet': 'CH',
      'limit': '100',
      'topLeft': '${b.north},${b.west}',
      'btmRight': '${b.south},${b.east}',
      'view': 'Unified',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': 'SwissFuel/1.0 (community fuel price app)',
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StationsException('TomTom error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (decoded['results'] as List?) ?? const [];
    final stations = <String, Station>{};
    for (final result in results) {
      if (result is Map<String, dynamic>) {
        final station = Station.fromTomTom(result);
        if (station != null) stations[station.id] = station;
      }
    }
    return stations.values.toList(growable: false);
  }

  @override
  void dispose() => _client.close();
}

/// Uses OpenStreetMap (Overpass) as the exhaustive base — it enumerates *every*
/// station in the viewport with no result cap — and enriches each with a nearby
/// TomTom match for cleaner brand/name data. TomTom's Search API is
/// relevance-ranked and capped at 100 results, so it is unsuitable as the base
/// for a pannable map but fine as an enrichment layer. TomTom-only stations
/// (missing from OSM) are appended so the union stays at least as complete as
/// either source alone.
class HybridStationsRepository extends StationsRepository {
  HybridStationsRepository({required String apiKey, http.Client? client})
      : _tomtom = TomTomStationsRepository(apiKey: apiKey, client: client),
        _osm = OsmStationsRepository(client: client);

  final TomTomStationsRepository _tomtom;
  final OsmStationsRepository _osm;

  /// Two stations within this many metres are treated as the same one.
  static const double _matchMeters = 80;
  static const Distance _distance = Distance();

  /// OSM is the primary/exhaustive source, so it gets the longer budget. TomTom
  /// only supplies brand/name enrichment, so it is kept short — a slow TomTom
  /// must never stall the map or drop the OSM results.
  static const Duration _osmTimeout = Duration(seconds: 12);
  static const Duration _tomtomTimeout = Duration(seconds: 6);

  @override
  Future<List<Station>> queryRegion(LatLngBounds b) async {
    // Query both concurrently. Each is guarded independently: a failure of one
    // source must not discard the other. `null` means that source errored or
    // timed out (distinct from a successful empty result).
    final results = await Future.wait([
      _tryQuery(_osm.queryRegion(b), _osmTimeout),
      _tryQuery(_tomtom.queryRegion(b), _tomtomTimeout),
    ]);
    final osm = results[0];
    final tomtom = results[1];

    // Only surface an error when both sources fail, so the UI can offer a retry
    // instead of a misleading "no stations here".
    if (osm == null && tomtom == null) {
      throw StationsException('All station sources failed');
    }

    final osmStations = osm ?? const <Station>[];
    final tomtomStations = tomtom ?? const <Station>[];

    // OSM unavailable: fall back to whatever TomTom returned (capped, but better
    // than an empty map).
    if (osmStations.isEmpty) return tomtomStations;
    return _merge(osmStations, tomtomStations);
  }

  static Future<List<Station>?> _tryQuery(
      Future<List<Station>> query, Duration timeout) async {
    try {
      return await query.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  /// OSM is the base; each station is enriched (missing brand/name/etc. filled)
  /// from its nearest TomTom match. TomTom stations with no OSM counterpart are
  /// appended.
  List<Station> _merge(List<Station> osm, List<Station> tomtom) {
    final merged = <Station>[];
    final usedTomtom = <int>{};

    for (final station in osm) {
      int? nearestIdx;
      double nearest = _matchMeters;
      for (var i = 0; i < tomtom.length; i++) {
        if (usedTomtom.contains(i)) continue;
        final d = _distance.as(
            LengthUnit.Meter, station.position, tomtom[i].position);
        if (d <= nearest) {
          nearest = d;
          nearestIdx = i;
        }
      }
      if (nearestIdx != null) {
        usedTomtom.add(nearestIdx);
        merged.add(station.enrichedWith(tomtom[nearestIdx]));
      } else {
        merged.add(station);
      }
    }

    // TomTom-only stations OSM didn't return.
    for (var i = 0; i < tomtom.length; i++) {
      if (!usedTomtom.contains(i)) merged.add(tomtom[i]);
    }

    return merged;
  }

  @override
  void dispose() {
    _tomtom.dispose();
    _osm.dispose();
  }
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
