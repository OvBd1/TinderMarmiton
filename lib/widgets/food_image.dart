import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Image.network(
      url,
      fit: fit,

      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final expected = progress.expectedTotalBytes;
        return ColoredBox(
          color: palette.surfaceMuted,
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
            color: palette.surfaceMuted,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: compact ? 26 : 44,
                    color: palette.inkIcon,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Image indisponible',
                      style: TextStyle(color: palette.inkFaint, fontSize: 13),
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
