import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../stations/models/station.dart';

/// Persists favorite stations locally as JSON snapshots so the favorites list
/// works even before the surrounding area has been loaded from OSM.
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  static const _key = 'favorites_v1';
  final SharedPreferences _prefs;

  List<Station> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    final stations = <Station>[];
    for (final entry in raw) {
      try {
        stations.add(
          Station.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return stations;
  }

  Future<void> _save(List<Station> stations) async {
    await _prefs.setStringList(
      _key,
      stations.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<List<Station>> toggle(Station station) async {
    final stations = load();
    final index = stations.indexWhere((s) => s.id == station.id);
    if (index >= 0) {
      stations.removeAt(index);
    } else {
      stations.add(station);
    }
    await _save(stations);
    return stations;
  }

  bool isFavorite(String id) =>
      (_prefs.getStringList(_key) ?? const []).any((entry) {
        try {
          return (jsonDecode(entry) as Map<String, dynamic>)['id'] == id;
        } catch (_) {
          return false;
        }
      });
}
