import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/fuel_chips.dart';
import '../stations/models/station.dart';

/// Shows the station detail as a modal bottom sheet.
Future<void> showStationDetail(BuildContext context, Station station) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _StationDetailSheet(station: station),
  );
}

class _StationDetailSheet extends ConsumerWidget {
  const _StationDetailSheet({required this.station});

  final Station station;

  Future<void> _openDirections() async {
    final lat = station.position.latitude;
    final lon = station.position.longitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFavorite = ref.watch(
        favoritesProvider.select((f) => f.any((s) => s.id == station.id)));
    final title =
        station.displayName.isEmpty ? l10n.unnamedStation : station.displayName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                IconButton.filledTonal(
                  icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border),
                  tooltip:
                      isFavorite ? l10n.removeFavorite : l10n.addFavorite,
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(station),
                ),
              ],
            ),
            if (station.brand != null && station.brand != station.displayName)
              Text(station.brand!, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (station.address != null)
              _InfoRow(icon: Icons.place_outlined, text: station.address!),
            if (station.openingHours != null)
              _InfoRow(
                icon: Icons.schedule_outlined,
                text: '${l10n.openingHours}: ${station.openingHours!}',
              ),
            const SizedBox(height: 12),
            FuelChips(fuels: station.fuels),
            const SizedBox(height: 8),
            // Phase 2: community prices will render here.
            Text(l10n.pricesComingSoon,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.directions_outlined),
                label: Text(l10n.directions),
                onPressed: _openDirections,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
