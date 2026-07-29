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
    final foreground = onDark ? Colors.white : const Color(0xFF3D3330);
    final iconColor = color ?? (onDark ? Colors.white : AppColors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.22) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : Border.all(color: const Color(0xFFEFE2DC)),
        boxShadow: onDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
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
