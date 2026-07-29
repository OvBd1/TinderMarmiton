import 'package:flutter/material.dart';

import '../state/favorites_store.dart';
import 'discover_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [DiscoverPage(), FavoritesPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final favoritesCount = FavoritesScope.of(context).count;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              selectedIcon: Icon(Icons.local_fire_department),
              label: 'Découvrir',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: favoritesCount > 0,
                label: Text('$favoritesCount'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: Badge(
                isLabelVisible: favoritesCount > 0,
                label: Text('$favoritesCount'),
                child: const Icon(Icons.favorite),
              ),
              label: 'Favoris',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
