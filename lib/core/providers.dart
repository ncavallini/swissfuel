import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/favorites/favorites_repository.dart';
import '../features/search/search_repository.dart';
import '../features/stations/models/fuel_type.dart';
import '../features/stations/models/station.dart';
import '../features/stations/stations_repository.dart';
import 'config.dart';
import 'location/location_service.dart';

/// Overridden in `main()` once SharedPreferences has been initialised.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final stationsRepositoryProvider = Provider<StationsRepository>((ref) {
  // With a TomTom key, use TomTom for coverage enriched with OSM fuel tags;
  // otherwise fall back to the free OpenStreetMap Overpass source.
  final StationsRepository repo = AppConfig.hasTomTom
      ? HybridStationsRepository(apiKey: AppConfig.tomTomApiKey)
      : OsmStationsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final repo = SearchRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(sharedPreferencesProvider)),
);

// ---------------------------------------------------------------------------
// User location
// ---------------------------------------------------------------------------

class UserLocationNotifier extends AsyncNotifier<LocationResult> {
  @override
  Future<LocationResult> build() =>
      ref.read(locationServiceProvider).current();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(locationServiceProvider).current(),
    );
  }
}

final userLocationProvider =
    AsyncNotifierProvider<UserLocationNotifier, LocationResult>(
  UserLocationNotifier.new,
);

/// Convenience accessor: the current user position, or the fallback center.
final userLatLngProvider = Provider<LatLng>((ref) {
  return ref.watch(userLocationProvider).maybeWhen(
        data: (r) => r.position,
        orElse: () => kSwitzerlandFallback,
      );
});

// ---------------------------------------------------------------------------
// Map bounds → stations
// ---------------------------------------------------------------------------

/// The current visible map bounds, pushed by the map screen on idle.
final mapBoundsProvider = StateProvider<LatLngBounds?>((ref) => null);

/// Stations for the current [mapBoundsProvider].
final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final bounds = ref.watch(mapBoundsProvider);
  if (bounds == null) return const [];
  return ref.watch(stationsRepositoryProvider).fetchInBounds(bounds);
});

// ---------------------------------------------------------------------------
// Filters & sorting
// ---------------------------------------------------------------------------

enum StationSort { distance, price, name }

class StationFilters {
  const StationFilters({
    this.fuels = const {},
    this.brand,
    this.maxDistanceKm,
    this.sort = StationSort.distance,
  });

  final Set<FuelType> fuels;
  final String? brand;
  final double? maxDistanceKm;
  final StationSort sort;

  StationFilters copyWith({
    Set<FuelType>? fuels,
    String? brand,
    bool clearBrand = false,
    double? maxDistanceKm,
    bool clearDistance = false,
    StationSort? sort,
  }) {
    return StationFilters(
      fuels: fuels ?? this.fuels,
      brand: clearBrand ? null : (brand ?? this.brand),
      maxDistanceKm: clearDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      sort: sort ?? this.sort,
    );
  }

  bool get isActive =>
      fuels.isNotEmpty || brand != null || maxDistanceKm != null;
}

class FiltersNotifier extends Notifier<StationFilters> {
  @override
  StationFilters build() => const StationFilters();

  void toggleFuel(FuelType fuel) {
    final next = {...state.fuels};
    if (!next.add(fuel)) next.remove(fuel);
    state = state.copyWith(fuels: next);
  }

  void setBrand(String? brand) => state = (brand == null || brand.isEmpty)
      ? state.copyWith(clearBrand: true)
      : state.copyWith(brand: brand);

  void setMaxDistance(double? km) => state = km == null
      ? state.copyWith(clearDistance: true)
      : state.copyWith(maxDistanceKm: km);

  void setSort(StationSort sort) => state = state.copyWith(sort: sort);

  void reset() => state = const StationFilters();
}

final filtersProvider =
    NotifierProvider<FiltersNotifier, StationFilters>(FiltersNotifier.new);

/// Free-text query applied to station name/brand in the nearby list.
final stationQueryProvider = StateProvider<String>((ref) => '');

const _distance = Distance();

/// Distance in km from the user to [station].
double distanceKmTo(LatLng from, Station station) =>
    _distance.as(LengthUnit.Kilometer, from, station.position);

/// Distinct brands present in the currently loaded stations, for the filter UI.
final availableBrandsProvider = Provider<List<String>>((ref) {
  final stations = ref.watch(stationsProvider).valueOrNull ?? const [];
  final brands = <String>{
    for (final s in stations)
      if (s.brand != null && s.brand!.isNotEmpty) s.brand!,
  };
  final sorted = brands.toList()..sort();
  return sorted;
});

/// Loaded stations after applying filters, query and sort — used by the list
/// and to drive markers.
final filteredStationsProvider = Provider<List<Station>>((ref) {
  final stations = ref.watch(stationsProvider).valueOrNull ?? const [];
  final filters = ref.watch(filtersProvider);
  final query = ref.watch(stationQueryProvider).trim().toLowerCase();
  final user = ref.watch(userLatLngProvider);

  Iterable<Station> result = stations;

  if (filters.fuels.isNotEmpty) {
    // Many stations have no fuel tags at all; treat unknown as a possible match
    // rather than hiding them, so filtering narrows the map instead of emptying
    // it. Stations with known fuels must contain all selected ones.
    result = result.where(
        (s) => s.fuels.isEmpty || filters.fuels.every(s.fuels.contains));
  }
  if (filters.brand != null) {
    result = result.where((s) => s.brand == filters.brand);
  }
  if (query.isNotEmpty) {
    result = result.where((s) =>
        s.displayName.toLowerCase().contains(query) ||
        (s.brand ?? '').toLowerCase().contains(query));
  }
  if (filters.maxDistanceKm != null) {
    result =
        result.where((s) => distanceKmTo(user, s) <= filters.maxDistanceKm!);
  }

  final list = result.toList();
  switch (filters.sort) {
    // Price sorting is a placeholder until community prices land (Phase 2);
    // it currently falls back to distance ordering.
    case StationSort.distance:
    case StationSort.price:
      list.sort(
          (a, b) => distanceKmTo(user, a).compareTo(distanceKmTo(user, b)));
      break;
    case StationSort.name:
      list.sort((a, b) => a.displayName
          .toLowerCase()
          .compareTo(b.displayName.toLowerCase()));
      break;
  }
  return list;
});

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

class FavoritesNotifier extends Notifier<List<Station>> {
  @override
  List<Station> build() => ref.read(favoritesRepositoryProvider).load();

  Future<void> toggle(Station station) async {
    state = await ref.read(favoritesRepositoryProvider).toggle(station);
  }

  bool isFavorite(String id) => state.any((s) => s.id == id);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<Station>>(FavoritesNotifier.new);
