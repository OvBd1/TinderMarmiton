import 'package:bouncy_button/bouncy_button.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Habillage possible d'un [AppButton].
enum AppButtonVariant {
  /// Action principale : dégradé chaud orange → rouge, libellé blanc.
  gradient,

  /// Action importante mais secondaire : rouge plein, libellé blanc.
  solid,

  /// Action discrète : fond blanc, bordure et libellé rouges.
  outlined,
}

/// Bouton d'action de l'application.
///
/// S'appuie sur [BouncyButton] pour l'effet de relief 3D et l'animation
/// d'enfoncement, habillé aux couleurs de la charte : coins à 18, hauteur 54,
/// dégradé chaud ou rouge de la marque, libellé 16 en gras.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.gradient,
    this.icon,
    this.busy = false,
    this.width,
  });

  static const _height = 54.0;
  static const _elevation = 6.0;
  static const _disabled = Color(0xFFE0D3CD);

  /// Hauteur totale occupée : la face du bouton plus son relief.
  static const totalHeight = _height + _elevation;

  final String label;

  /// `null` désactive le bouton, comme sur les boutons Material.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;

  /// Remplace le contenu par un indicateur de chargement et bloque l'appui.
  final bool busy;

  /// Largeur fixe. Obligatoire quand le parent ne contraint pas la largeur
  /// (une ligne d'actions de dialogue, par exemple).
  final double? width;

  bool get _enabled => onPressed != null && !busy;

  Color get _foreground {
    if (variant != AppButtonVariant.outlined) {
      return Colors.white;
    }
    return _enabled ? AppColors.red : _disabled;
  }

  BouncyButtonStyle _style() {
    const radius = BorderRadius.all(Radius.circular(18));

    return switch (variant) {
      AppButtonVariant.gradient => BouncyButtonStyle(
        height: _height,
        width: width,
        elevation: _elevation,
        gradient: AppColors.warmGradient,
        disabledGradient: const LinearGradient(
          colors: [_disabled, _disabled],
        ),
        borderRadius: radius,
        shadowDarkness: 0.16,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      AppButtonVariant.solid => BouncyButtonStyle(
        height: _height,
        width: width,
        elevation: _elevation,
        backgroundColor: AppColors.red,
        disabledColor: _disabled,
        borderRadius: radius,
        shadowDarkness: 0.16,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      AppButtonVariant.outlined => BouncyButtonStyle(
        height: _height,
        width: width,
        elevation: _elevation,
        backgroundColor: Colors.white,
        disabledColor: Colors.white,
        border: Border.all(
          color: _enabled ? AppColors.red : _disabled,
          width: 1.4,
        ),
        borderRadius: radius,
        shadowColor: const Color(0xFFF2CFCB),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onPressed: _enabled ? onPressed : null,
      style: _style(),
      animation: const BouncyButtonAnimation(
        duration: Duration(milliseconds: 90),
        curve: Curves.easeOut,
      ),
      semanticLabel: label,
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: _foreground,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: _foreground),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Bouton rond de la barre d'action : face blanche, icône colorée et relief
/// teinté de la même couleur que l'icône.
class AppRoundButton extends StatelessWidget {
  const AppRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.size = 62,
  });

  final IconData icon;
  final Color color;
  final String tooltip;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  /// Diamètre de la face du bouton, relief non compris.
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final elevation = size * 0.09;

    return Tooltip(
      message: tooltip,
      child: BouncyButton(
        onPressed: onPressed,
        style: BouncyButtonStyle(
          height: size,
          width: size,
          elevation: elevation,
          shape: BoxShape.circle,
          backgroundColor: Colors.white,
          disabledColor: Colors.white,
          shadowColor: Color.lerp(color, Colors.white, 0.62),
          padding: EdgeInsets.zero,
        ),
        animation: const BouncyButtonAnimation(
          duration: Duration(milliseconds: 90),
          curve: Curves.easeOut,
        ),
        semanticLabel: tooltip,
        child: Icon(
          icon,
          size: size * 0.46,
          color: enabled ? color : color.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
