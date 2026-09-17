import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_service.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../search/filters_sheet.dart';
import '../station_detail/station_detail_sheet.dart';
import '../stations/models/station.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  Timer? _boundsDebounce;
  bool _centeredOnUser = false;

  @override
  void dispose() {
    _boundsDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _pushBounds() {
    // Debounce so panning doesn't hammer the Overpass API.
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(mapBoundsProvider.notifier).state =
          _mapController.camera.visibleBounds;
    });
  }

  void _recenter(LatLng target) {
    _mapController.move(target, 14);
    _pushBounds();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text;
    if (query.trim().isEmpty) return;
    final results =
        await ref.read(searchRepositoryProvider).search(query);
    if (!mounted || results.isEmpty) return;
    _recenter(results.first.position);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userLatLng = ref.watch(userLatLngProvider);
    final stations = ref.watch(filteredStationsProvider);
    final hasError = ref.watch(stationsProvider).hasError;

    // Center on the user the first time their location resolves.
    ref.listen(userLocationProvider, (_, next) {
      next.whenData((result) {
        if (!_centeredOnUser && result.status == LocationStatus.ok) {
          _centeredOnUser = true;
          _recenter(result.position);
        }
      });
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 13,
            minZoom: 4,
            maxZoom: 19,
            onMapReady: _pushBounds,
            onPositionChanged: (_, _) => _pushBounds(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ch.swissfuel',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: userLatLng,
                  width: 22,
                  height: 22,
                  child: const _UserDot(),
                ),
                for (final station in stations)
                  Marker(
                    point: station.position,
                    width: 40,
                    height: 40,
                    child: _StationMarker(
                      station: station,
                      onTap: () => showStationDetail(context, station),
                    ),
                  ),
              ],
            ),
          ],
        ),
        _SearchBar(
          controller: _searchController,
          hint: l10n.searchHint,
          onSubmitted: (_) => _runSearch(),
          onFilters: () => showFiltersSheet(context),
          filtersActive: ref.watch(filtersProvider).isActive,
        ),
        if (hasError)
          _ErrorBanner(
            message: l10n.stationsLoadError,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(stationsProvider),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            tooltip: l10n.recenter,
            onPressed: () => _recenter(ref.read(userLatLngProvider)),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.onFilters,
    required this.filtersActive,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilters;
  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: SearchBar(
                controller: controller,
                hintText: hint,
                leading: const Icon(Icons.search),
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            Badge(
              isLabelVisible: filtersActive,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.tune),
                onPressed: onFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      // Sit above the recenter FAB, clear of the search bar at the top.
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 88, 16),
          child: Material(
            color: scheme.errorContainer,
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 20, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(retryLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.onPrimary, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: Icon(
          Icons.local_gas_station,
          size: 22,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}
