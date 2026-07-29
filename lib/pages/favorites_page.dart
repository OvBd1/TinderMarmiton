import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../state/favorites_store.dart';
import '../theme/app_theme.dart';
import '../widgets/recipe_list_tile.dart';
import 'recipe_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  void _openDetail(BuildContext context, Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecipeDetailPage(recipe: recipe, heroTag: 'favorites-${recipe.id}'),
      ),
    );
  }

  void _remove(BuildContext context, Recipe recipe) {
    final store = FavoritesScope.of(context);
    final previousIndex = store.indexOf(recipe);
    store.remove(recipe);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${recipe.name} retirée des favoris'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => store.insertAt(previousIndex, recipe),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = FavoritesScope.of(context);
    final favorites = store.favorites;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                const Text(
                  'Favoris',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(width: 10),
                if (favorites.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favorites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Glisse une recette vers la gauche pour la retirer',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A7B75)),
            ),
          ),
          if (store.syncError case final message?)
            _SyncErrorBanner(message: message),
          const SizedBox(height: 16),
          Expanded(
            child: store.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  )
                : favorites.isEmpty
                ? const _EmptyFavorites()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recipe = favorites[index];
                      return Dismissible(
                        key: ValueKey('fav-${recipe.id}'),
                        direction: DismissDirection.endToStart,
                        background: const _DismissBackground(),
                        onDismissed: (_) => _remove(context, recipe),
                        child: RecipeListTile(
                          recipe: recipe,
                          heroTag: 'favorites-${recipe.id}',
                          onTap: () => _openDetail(context, recipe),
                          onRemove: () => _remove(context, recipe),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Synchronisation impossible'),
              content: SingleChildScrollView(child: SelectableText(message)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 20,
                  color: Color(0xFFB4690E),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sauvegarde en ligne indisponible. Tes favoris sont '
                    'enregistrés sur cet appareil.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A5A00),
                      height: 1.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFFB4690E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 26),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.heart_broken, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Retirer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 52,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun favori pour l\'instant',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'File dans l\'onglet Découvrir et swipe à droite '
              'les plats qui te tentent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF8A7B75),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
