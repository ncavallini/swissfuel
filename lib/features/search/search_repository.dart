import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A geocoded place returned from a search query.
class PlaceResult {
  const PlaceResult({required this.label, required this.position});
  final String label;
  final LatLng position;
}

/// Geocodes free-text place queries via the OpenStreetMap Nominatim service.
///
/// Biased toward Switzerland for the v1 region.
class SearchRepository {
  SearchRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '6',
      'countrycodes': 'ch',
      'addressdetails': '0',
    });

    final response = await _client.get(uri, headers: {
      // Nominatim requires an identifying User-Agent.
      'User-Agent': 'SwissFuel/1.0 (community fuel price app)',
    });
    if (response.statusCode != 200) return const [];

    final list = jsonDecode(response.body) as List;
    return list.whereType<Map<String, dynamic>>().map((item) {
      return PlaceResult(
        label: (item['display_name'] as String?) ?? '',
        position: LatLng(
          double.parse(item['lat'] as String),
          double.parse(item['lon'] as String),
        ),
      );
    }).toList(growable: false);
  }

  void dispose() => _client.close();
}
