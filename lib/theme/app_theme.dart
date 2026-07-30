import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFFFF5A3C);

  static const orange = Color(0xFFFF8A3D);
  static const red = Color(0xFFE23744);
  static const like = Color(0xFF2E9E5B);
  static const nope = Color(0xFFE23744);

  /// Fond de l'application en thème clair. Le thème sombre a le sien :
  /// passer par `AppPalette.of(context).background` pour suivre les deux.
  static const background = Color(0xFFFFF9F6);

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, red],
  );

  static const photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x66000000), Color(0xE6000000)],
    stops: [0.35, 0.62, 1],
  );
}

abstract final class AppRadius {
  static const card = 28.0;
  static const sheet = 32.0;
  static const chip = 14.0;
}

/// Couleurs de la charte qui changent entre thème clair et thème sombre.
///
/// Les teintes de marque (orange, rouge, vert « favori ») restent les mêmes
/// dans les deux thèmes : seuls les fonds, bordures et niveaux de texte
/// basculent. Récupération via [AppPalette.of].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.divider,
    required this.ink,
    required this.inkBody,
    required this.inkMuted,
    required this.inkFaint,
    required this.inkGhost,
    required this.inkIcon,
    required this.brand,
    required this.star,
    required this.buttonDisabled,
    required this.outlinedShadow,
    required this.warningSurface,
    required this.warningIcon,
    required this.warningText,
    required this.tagSurface,
    required this.tagText,
    required this.cardShadow,
  });

  final Brightness brightness;

  /// Fond des écrans.
  final Color background;

  /// Fond des cartes et tuiles posées sur [background].
  final Color surface;

  /// Fond neutre des zones en attente (photo en cours de chargement).
  final Color surfaceMuted;

  /// Contour des cartes et des champs de saisie.
  final Color border;

  /// Filet de séparation entre deux lignes d'une même carte.
  final Color divider;

  /// Texte et icônes principaux posés sur [surface].
  final Color ink;

  /// Paragraphes et lignes d'informations secondaires.
  final Color inkBody;

  /// Sous-titres d'écran.
  final Color inkMuted;

  /// Petits libellés de section.
  final Color inkFaint;

  /// Mentions de pied de page.
  final Color inkGhost;

  /// Icônes décoratives (chevrons, illustrations d'attente).
  final Color inkIcon;

  /// Rouge de la marque ajusté pour rester lisible en texte sur [surface].
  final Color brand;

  /// Jaune des étoiles de notation.
  final Color star;

  /// Face d'un bouton désactivé.
  final Color buttonDisabled;

  /// Relief d'un bouton à fond clair.
  final Color outlinedShadow;

  final Color warningSurface;
  final Color warningIcon;
  final Color warningText;

  /// Étiquettes techniques de la page À propos.
  final Color tagSurface;
  final Color tagText;

  /// Ombre portée sous les cartes de statistiques.
  final Color cardShadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: Colors.white,
    surfaceMuted: Color(0xFFF2E6E0),
    border: Color(0xFFF0E4DE),
    divider: Color(0xFFF5EBE6),
    ink: Color(0xFF3D3330),
    inkBody: Color(0xFF554A45),
    inkMuted: Color(0xFF8A7B75),
    inkFaint: Color(0xFF9A8177),
    inkGhost: Color(0xFFA89791),
    inkIcon: Color(0xFFBFA79D),
    brand: AppColors.red,
    star: Color(0xFFF5B301),
    buttonDisabled: Color(0xFFE0D3CD),
    outlinedShadow: Color(0xFFF2CFCB),
    warningSurface: Color(0xFFFFF4E5),
    warningIcon: Color(0xFFB4690E),
    warningText: Color(0xFF8A5A00),
    tagSurface: Color(0x1AFF5A3C),
    tagText: Color(0xFFB5432F),
    cardShadow: Color(0x0A000000),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF17120F),
    surface: Color(0xFF231D1B),
    surfaceMuted: Color(0xFF2E2724),
    border: Color(0xFF3B322E),
    divider: Color(0xFF322A27),
    ink: Color(0xFFF3EDEB),
    inkBody: Color(0xFFD3C9C4),
    inkMuted: Color(0xFFA79A94),
    inkFaint: Color(0xFF9C8F89),
    inkGhost: Color(0xFF8A7D77),
    inkIcon: Color(0xFF7A6D67),
    brand: Color(0xFFFF7D6E),
    star: Color(0xFFF5B301),
    buttonDisabled: Color(0xFF463B37),
    outlinedShadow: Color(0xFF52302C),
    warningSurface: Color(0xFF3A2A12),
    warningIcon: Color(0xFFE9A94A),
    warningText: Color(0xFFE8CB9B),
    tagSurface: Color(0x33FF5A3C),
    tagText: Color(0xFFFFA593),
    cardShadow: Color(0x40000000),
  );

  static AppPalette of(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>();
    assert(palette != null, 'Aucune AppPalette dans le thème courant.');
    return palette ?? light;
  }

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? divider,
    Color? ink,
    Color? inkBody,
    Color? inkMuted,
    Color? inkFaint,
    Color? inkGhost,
    Color? inkIcon,
    Color? brand,
    Color? star,
    Color? buttonDisabled,
    Color? outlinedShadow,
    Color? warningSurface,
    Color? warningIcon,
    Color? warningText,
    Color? tagSurface,
    Color? tagText,
    Color? cardShadow,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      inkBody: inkBody ?? this.inkBody,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      inkGhost: inkGhost ?? this.inkGhost,
      inkIcon: inkIcon ?? this.inkIcon,
      brand: brand ?? this.brand,
      star: star ?? this.star,
      buttonDisabled: buttonDisabled ?? this.buttonDisabled,
      outlinedShadow: outlinedShadow ?? this.outlinedShadow,
      warningSurface: warningSurface ?? this.warningSurface,
      warningIcon: warningIcon ?? this.warningIcon,
      warningText: warningText ?? this.warningText,
      tagSurface: tagSurface ?? this.tagSurface,
      tagText: tagText ?? this.tagText,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;

    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      ink: mix(ink, other.ink),
      inkBody: mix(inkBody, other.inkBody),
      inkMuted: mix(inkMuted, other.inkMuted),
      inkFaint: mix(inkFaint, other.inkFaint),
      inkGhost: mix(inkGhost, other.inkGhost),
      inkIcon: mix(inkIcon, other.inkIcon),
      brand: mix(brand, other.brand),
      star: mix(star, other.star),
      buttonDisabled: mix(buttonDisabled, other.buttonDisabled),
      outlinedShadow: mix(outlinedShadow, other.outlinedShadow),
      warningSurface: mix(warningSurface, other.warningSurface),
      warningIcon: mix(warningIcon, other.warningIcon),
      warningText: mix(warningText, other.warningText),
      tagSurface: mix(tagSurface, other.tagSurface),
      tagText: mix(tagText, other.tagText),
      cardShadow: mix(cardShadow, other.cardShadow),
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);

  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: palette.brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.isDark ? palette.ink : const Color(0xFF1D1B1A),
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
