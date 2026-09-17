# SwissFuel

A cross-platform (Android + iOS) app to find nearby fuel stations in Switzerland,
inspired by Italy's *PrezziBenzina*. Station locations come from **OpenStreetMap**;
community-contributed fuel prices are planned for Phase 2.

Built with **Flutter** (Material 3), **Riverpod**, **flutter_map** (OSM tiles),
and **Supabase** (auth + database, used in Phase 2).

## Features (v1)

- Map centered on your location with OSM fuel-station markers.
- Distance-sorted "Nearby" list.
- Search a place (Nominatim geocoding) and filter by fuel type, brand, and
  max distance; sort by distance / name (price sort is a Phase 2 placeholder).
- Save favorites (persisted locally) and open directions in your maps app.
- Localized in German, French, Italian, and English.

## Getting started

```bash
flutter pub get
flutter gen-l10n        # regenerate localizations after editing lib/l10n/*.arb
flutter run             # on a connected device or emulator
flutter test            # unit + widget tests
flutter analyze
```

## Architecture

Feature-first layout under `lib/`:

- `core/` — theme, location service, and all Riverpod providers (`providers.dart`).
- `features/stations/` — `Station` model + `StationsRepository` sources with a
  shared in-memory TTL/bounds cache: `OsmStationsRepository` (Overpass, free),
  `TomTomStationsRepository` (TomTom Category Search, key required), and
  `HybridStationsRepository` — OSM as the exhaustive base (Overpass enumerates
  every station in the viewport with no cap), enriched with brand/name from a
  nearby TomTom match. (TomTom Search is relevance-ranked and capped at 100
  results, so it enriches rather than drives the map.)
- `features/map/` — `flutter_map` view, markers, search bar, recenter.
- `features/nearby/` — filtered, distance-sorted station list.
- `features/search/` — Nominatim geocoding + filter/sort bottom sheet.
- `features/favorites/` — local persistence via `shared_preferences`.
- `features/station_detail/` — detail bottom sheet + directions.
- `features/home/` — bottom-navigation shell.
- `l10n/` — generated `AppLocalizations` from `app_*.arb`.

Data flow: the map pushes its visible bounds (debounced) into `mapBoundsProvider`
→ `stationsProvider` fetches from the active source → `filteredStationsProvider`
applies filters/query/sort and drives both the markers and the list.

### Station data source

Station coverage always comes from the free OpenStreetMap Overpass source
(exhaustive per viewport). Supplying a [TomTom Search API](https://developer.tomtom.com/)
key additionally enriches those stations with cleaner brand/name data from a
nearby TomTom match:

```
flutter run --dart-define=TOMTOM_API_KEY=your_key_here
```

The key is read in `lib/core/config.dart` and must be kept out of git. TomTom's
**Fuel Prices** API (per-station prices) is a separate, paid enterprise product
and is **not** used; community-submitted prices remain the plan for Phase 2.

## Known limitations / next steps

- **Map tiles:** currently uses the public OSM tile server, which is **not
  permitted for production** apps. Switch `TileLayer.urlTemplate` in
  `lib/features/map/map_screen.dart` to a provider with an API key
  (e.g. MapTiler or Stadia Maps) before release.
- **Clustering:** `flutter_map_marker_cluster` is incompatible with
  `flutter_map` v8, so markers are currently unclustered.
- **Phase 2 — community prices:** Supabase schema (`stations`, `prices`),
  anonymous auth, price submission UI, aggregation, and true cheapest-first
  sorting. The `supabase_flutter` dependency and detail-sheet placeholder are
  already in place.
