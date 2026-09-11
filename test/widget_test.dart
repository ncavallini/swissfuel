import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swissfuel/core/providers.dart';
import 'package:swissfuel/features/stations/models/fuel_type.dart';
import 'package:swissfuel/features/stations/models/station.dart';
import 'package:swissfuel/l10n/app_localizations.dart';
import 'package:swissfuel/shared/widgets/station_card.dart';

void main() {
  testWidgets('StationCard shows name, fuel chip and distance',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const station = Station(
      id: 'node/1',
      position: LatLng(47.3769, 8.5417),
      name: 'Migrol Test',
      fuels: {FuelType.diesel},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StationCard(station: station, distanceKm: 2.5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Migrol Test'), findsOneWidget);
    expect(find.text('Diesel'), findsOneWidget);
    expect(find.text('2.5 km'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
