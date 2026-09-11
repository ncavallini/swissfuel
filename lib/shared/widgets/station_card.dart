import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../features/stations/models/station.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import 'fuel_chips.dart';

/// A list tile summarising a station: name, brand, distance and fuels, with a
/// favorite toggle.
class StationCard extends ConsumerWidget {
  const StationCard({
    super.key,
    required this.station,
    this.distanceKm,
    this.onTap,
  });

  final Station station;
  final double? distanceKm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFavorite =
        ref.watch(favoritesProvider.select((f) => f.any((s) => s.id == station.id)));
    final title = station.displayName.isEmpty
        ? l10n.unnamedStation
        : station.displayName;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (station.address != null) ...[
                      const SizedBox(height: 2),
                      Text(station.address!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    FuelChips(fuels: station.fuels),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border),
                    color: isFavorite ? theme.colorScheme.primary : null,
                    tooltip: isFavorite
                        ? l10n.removeFavorite
                        : l10n.addFavorite,
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(station),
                  ),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        formatDistance(l10n, distanceKm!),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
