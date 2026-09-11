import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../favorites/favorites_screen.dart';
import '../map/map_screen.dart';
import '../nearby/nearby_screen.dart';

/// Root scaffold with bottom navigation between Map, Nearby and Favorites.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: IndexedStack(
        index: _index,
        children: const [
          MapScreen(),
          NearbyScreen(),
          FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_outlined),
            selectedIcon: const Icon(Icons.list),
            label: l10n.navNearby,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.navFavorites,
          ),
        ],
      ),
    );
  }
}
