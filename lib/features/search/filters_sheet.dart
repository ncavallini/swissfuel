import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../stations/models/fuel_type.dart';

/// Shows the station filter & sort controls as a modal bottom sheet.
Future<void> showFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _FiltersSheet(),
  );
}

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filters = ref.watch(filtersProvider);
    final notifier = ref.read(filtersProvider.notifier);
    final brands = ref.watch(availableBrandsProvider);
    final maxDistance = filters.maxDistanceKm ?? 20.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filters, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(l10n.fuelType, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final fuel in FuelType.values)
                  FilterChip(
                    label: Text(fuel.label(l10n)),
                    selected: filters.fuels.contains(fuel),
                    onSelected: (_) => notifier.toggleFuel(fuel),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.brand, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: filters.brand,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.anyBrand),
                ),
                for (final brand in brands)
                  DropdownMenuItem<String?>(value: brand, child: Text(brand)),
              ],
              onChanged: notifier.setBrand,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.maxDistance, style: theme.textTheme.titleMedium),
                Text('${maxDistance.round()} km'),
              ],
            ),
            Slider(
              value: maxDistance.clamp(1, 50),
              min: 1,
              max: 50,
              divisions: 49,
              label: '${maxDistance.round()} km',
              onChanged: (v) => notifier.setMaxDistance(v),
            ),
            const SizedBox(height: 8),
            Text(l10n.sortBy, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<StationSort>(
              segments: [
                ButtonSegment(
                    value: StationSort.distance, label: Text(l10n.sortDistance)),
                ButtonSegment(
                    value: StationSort.price, label: Text(l10n.sortPrice)),
                ButtonSegment(
                    value: StationSort.name, label: Text(l10n.sortName)),
              ],
              selected: {filters.sort},
              onSelectionChanged: (s) => notifier.setSort(s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      notifier.reset();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.resetFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.applyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
