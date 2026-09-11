import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/station_card.dart';
import '../station_detail/station_detail_sheet.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final user = ref.watch(userLatLngProvider);

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(l10n.noFavorites, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final sorted = [...favorites]..sort((a, b) =>
        distanceKmTo(user, a).compareTo(distanceKmTo(user, b)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final station = sorted[index];
        return StationCard(
          station: station,
          distanceKm: distanceKmTo(user, station),
          onTap: () => showStationDetail(context, station),
        );
      },
    );
  }
}
