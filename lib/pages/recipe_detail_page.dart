import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../state/favorites_store.dart';
import '../theme/app_theme.dart';
import '../widgets/food_image.dart';
import '../widgets/info_chip.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipe, this.heroTag});

  final Recipe recipe;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final isFavorite = favorites.isFavorite(recipe);

    Widget image = FoodImage(url: recipe.imageUrl);
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: const _CircleBackButton(),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CircleIconButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.red : const Color(0xFF3D3330),
                  tooltip: isFavorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () {
                    favorites.toggle(recipe);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? '${recipe.name} retirée des favoris'
                                : '${recipe.name} ajoutée aux favoris',
                          ),
                        ),
                      );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x40000000), Colors.transparent],
                        stops: [0, 0.4],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF5B301),
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (recipe.category.isNotEmpty || recipe.area.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (recipe.category.isNotEmpty)
                          InfoChip(
                            icon: Icons.category_outlined,
                            label: recipe.category,
                          ),
                        if (recipe.area.isNotEmpty)
                          InfoChip(icon: Icons.public, label: recipe.area),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.5,
                      color: Color(0xFF5C4F4A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatTile(
                        icon: Icons.schedule,
                        value: recipe.prepLabel,
                        label: 'Temps',
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        icon: Icons.local_fire_department,
                        value: recipe.difficulty.label,
                        label: 'Difficulté',
                        color: recipe.difficulty.color,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        icon: Icons.bolt,
                        value: '${recipe.calories}',
                        label: 'kcal / pers.',
                        color: AppColors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Ingrédients',
                    count: recipe.ingredients.length,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0E4DE)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < recipe.ingredients.length; i++)
                          _IngredientRow(
                            label: recipe.ingredients[i],
                            isLast: i == recipe.ingredients.length - 1,
                          ),
                      ],
                    ),
                  ),
                  if (recipe.steps.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _SectionTitle(
                      title: 'Préparation',
                      count: recipe.steps.length,
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < recipe.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StepCard(number: i + 1, text: recipe.steps[i]),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E4DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF3D3330),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0E4DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF9A8177)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.label, required this.isLast});

  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF5EBE6))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF3D3330)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      icon: Icons.arrow_back,
      color: const Color(0xFF3D3330),
      tooltip: 'Retour',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 22,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }
}
