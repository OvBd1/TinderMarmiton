import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../state/favorites_store.dart';
import '../theme/app_theme.dart';
import 'discover_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';

ValueKey<String> navTabKey(int index) => ValueKey('nav-tab-$index');

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [DiscoverPage(), FavoritesPage(), ProfilePage()];

  Widget _icon(IconData icon, IconData selectedIcon, int index, String label) {
    final selected = _index == index;
    return Semantics(
      key: navTabKey(index),
      label: label,
      selected: selected,
      button: true,
      child: Icon(
        selected ? selectedIcon : icon,
        size: 27,
        color: selected ? Colors.white : AppPalette.of(context).inkMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final favoritesCount = FavoritesScope.of(context).count;
    final favoritesSelected = _index == 1;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: ColoredBox(
        color: palette.surface,
        child: SafeArea(
          top: false,
          child: CurvedNavigationBar(
            index: _index,
            height: 68,
            color: palette.surface,
            buttonBackgroundColor: AppColors.red,
            backgroundColor: palette.background,
            animationCurve: Curves.easeOutCubic,
            animationDuration: const Duration(milliseconds: 350),
            onTap: (value) => setState(() => _index = value),
            items: [
              _icon(
                Icons.local_fire_department_outlined,
                Icons.local_fire_department,
                0,
                'Découvrir',
              ),
              Badge(
                isLabelVisible: favoritesCount > 0,
                backgroundColor: favoritesSelected
                    ? Colors.white
                    : AppColors.red,
                textColor: favoritesSelected ? AppColors.red : Colors.white,
                label: Text('$favoritesCount'),
                child: _icon(
                  Icons.favorite_border,
                  Icons.favorite,
                  1,
                  'Favoris',
                ),
              ),
              _icon(Icons.person_outline, Icons.person, 2, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
