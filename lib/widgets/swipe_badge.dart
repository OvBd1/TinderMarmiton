import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SwipeBadge extends StatelessWidget {
  const SwipeBadge.favorite({super.key, required this.progress})
    : _isFavorite = true;

  const SwipeBadge.pass({super.key, required this.progress})
    : _isFavorite = false;

  final double progress;
  final bool _isFavorite;

  @override
  Widget build(BuildContext context) {
    final opacity = progress.clamp(0.0, 1.0);
    if (opacity == 0) return const SizedBox.shrink();

    final color = _isFavorite ? AppColors.like : AppColors.nope;
    final label = _isFavorite ? 'FAVORI' : 'PASSER';
    final icon = _isFavorite ? Icons.favorite : Icons.close;

    final scale = 0.75 + 0.25 * opacity;

    final angle = (_isFavorite ? -0.28 : 0.28) * (1.6 - 0.6 * opacity);

    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 34),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
