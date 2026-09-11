import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Default map center used when location is unavailable: Zürich, Switzerland.
const LatLng kSwitzerlandFallback = LatLng(47.3769, 8.5417);

enum LocationStatus { ok, denied, disabled }

class LocationResult {
  const LocationResult(this.status, this.position);
  final LocationStatus status;

  /// The user position when [status] is [LocationStatus.ok], otherwise the
  /// Switzerland fallback so the map always has somewhere to start.
  final LatLng position;
}

/// Thin wrapper around geolocator handling permission and service checks,
/// always resolving to a usable position for the map.
class LocationService {
  Future<LocationResult> current() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(LocationStatus.disabled, kSwitzerlandFallback);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationStatus.denied, kSwitzerlandFallback);
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(
        LocationStatus.ok,
        LatLng(pos.latitude, pos.longitude),
      );
    } catch (_) {
      // Timeout or transient failure — fall back gracefully.
      return const LocationResult(LocationStatus.denied, kSwitzerlandFallback);
    }
  }
}
