import 'package:flutter/material.dart';

import '../../features/stations/models/fuel_type.dart';
import '../../l10n/app_localizations.dart';

/// A compact row of chips showing which fuels a station offers.
class FuelChips extends StatelessWidget {
  const FuelChips({super.key, required this.fuels});

  final Set<FuelType> fuels;

  @override
  Widget build(BuildContext context) {
    if (fuels.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final fuel in FuelType.values)
          if (fuels.contains(fuel))
            Chip(
              label: Text(fuel.label(l10n)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
      ],
    );
  }
}
