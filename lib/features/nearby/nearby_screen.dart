import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/station_card.dart';
import '../search/filters_sheet.dart';
import '../station_detail/station_detail_sheet.dart';

class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stationsAsync = ref.watch(stationsProvider);
    final filtered = ref.watch(filteredStationsProvider);
    final user = ref.watch(userLatLngProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: l10n.searchHint,
                  leading: const Icon(Icons.search),
                  onChanged: (v) =>
                      ref.read(stationQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: ref.watch(filtersProvider).isActive,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.tune),
                  onPressed: () => showFiltersSheet(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: stationsAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.loadingStations),
                ],
              ),
            ),
            error: (_, _) => _Message(
              icon: Icons.error_outline,
              text: l10n.noStations,
              action: FilledButton(
                onPressed: () => ref.invalidate(stationsProvider),
                child: Text(l10n.retry),
              ),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return _Message(
                    icon: Icons.location_off_outlined, text: l10n.noStations);
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final station = filtered[index];
                  return StationCard(
                    station: station,
                    distanceKm: distanceKmTo(user, station),
                    onTap: () => showStationDetail(context, station),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
