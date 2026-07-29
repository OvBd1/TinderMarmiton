import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,

      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final expected = progress.expectedTotalBytes;
        return ColoredBox(
          color: const Color(0xFFF2E6E0),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.orange,
              value: expected == null
                  ? null
                  : progress.cumulativeBytesLoaded / expected,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight.isFinite && constraints.maxHeight < 130;

          return ColoredBox(
            color: const Color(0xFFF2E6E0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: compact ? 26 : 44,
                    color: const Color(0xFFBFA79D),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Image indisponible',
                      style: TextStyle(color: Color(0xFF9A8177), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
