import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onDark = false,
  });

  final IconData icon;
  final String label;

  final Color? color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = onDark ? Colors.white : palette.ink;
    final iconColor = color ?? (onDark ? Colors.white : AppColors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.22) : palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.35)
              : palette.border,
        ),
        boxShadow: onDark
            ? null
            : [
                BoxShadow(
                  color: palette.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
