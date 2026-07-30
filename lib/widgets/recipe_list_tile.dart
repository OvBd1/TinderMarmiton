import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_theme.dart';
import 'food_image.dart';

class RecipeListTile extends StatelessWidget {
  const RecipeListTile({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onRemove,
    this.heroTag,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Widget thumbnail = SizedBox(
      width: 104,
      height: 104,
      child: FoodImage(url: recipe.imageUrl),
    );
    if (heroTag != null) {
      thumbnail = Hero(tag: heroTag!, child: thumbnail);
    }

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: thumbnail,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 15,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.prepLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.inkBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_fire_department,
                          size: 15,
                          color: recipe.difficulty.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.difficulty.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: recipe.difficulty.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: palette.star),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.rating.toStringAsFixed(1)} · ${recipe.calories} kcal',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.inkBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Retirer des favoris',
                icon: const Icon(Icons.favorite, color: AppColors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
