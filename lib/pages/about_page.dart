import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Version affichée dans l'application, alignée sur `pubspec.yaml`.
const appVersion = '0.1.0';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _team = [
    _Member(name: 'Raphael Touzet', initials: 'RT'),
    _Member(name: 'Yanis Bontrond', initials: 'YB'),
    _Member(name: 'Sébastien Gerard', initials: 'SG'),
  ];

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$value copié.'),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _AppHeader(),
          const SizedBox(height: 26),
          const _SectionLabel('Le principe'),
          const SizedBox(height: 10),
          _Card(
            child: Text(
              'On swipe à droite ce qui donne envie, à gauche ce qui ne donne '
              'pas. Les recettes likées atterrissent dans les favoris, '
              'synchronisés entre l\'appareil et le compte : elles restent '
              'accessibles hors ligne et se retrouvent à la prochaine '
              'connexion, même sur un autre téléphone.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: palette.inkBody,
              ),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Fonctionnalités'),
          const SizedBox(height: 10),
          const _Card(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _FeatureRow(
                  icon: Icons.local_fire_department,
                  color: AppColors.orange,
                  title: 'Découvrir',
                  detail: 'Pile de cartes swipables, rechargée à la volée.',
                ),
                _FeatureRow(
                  icon: Icons.favorite,
                  color: AppColors.red,
                  title: 'Favoris',
                  detail: 'Enregistrés localement et sur le compte.',
                ),
                _FeatureRow(
                  icon: Icons.receipt_long,
                  color: Color(0xFF7A5AF8),
                  title: 'Fiche recette',
                  detail: 'Ingrédients, étapes, temps, note et calories.',
                ),
                _FeatureRow(
                  icon: Icons.translate,
                  color: AppColors.like,
                  title: 'Traduction automatique',
                  detail: 'Les recettes anglaises passent en français.',
                ),
                _FeatureRow(
                  icon: Icons.cloud_off,
                  color: Color(0xFF3D8BFF),
                  title: 'Mode dégradé',
                  detail: 'Utilisable même sans réseau, resync au retour.',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('L\'équipe'),
          const SizedBox(height: 10),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                for (final member in _team)
                  _MemberRow(
                    member: member,
                    isLast: member == _team.last,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Sous le capot'),
          const SizedBox(height: 10),
          const _Card(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag('Flutter 3.44'),
                _Tag('Dart 3.12'),
                _Tag('Material 3'),
                _Tag('Firebase Auth'),
                _Tag('Cloud Firestore'),
                _Tag('SharedPreferences'),
                _Tag('TheMealDB'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Text(
              'État applicatif géré uniquement avec le framework '
              '(ChangeNotifier + InheritedNotifier), sans package externe. '
              'Le temps de préparation, la difficulté, la note et les calories '
              'ne sont pas fournis par TheMealDB : ils sont estimés à partir de '
              'la recette et n\'ont aucune valeur nutritionnelle réelle.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: palette.inkBody,
              ),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Liens'),
          const SizedBox(height: 10),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.code,
                  label: 'Code source',
                  value: 'github.com/OvBd1/TinderMarmiton',
                  onTap: () => _copy(
                    context,
                    'https://github.com/OvBd1/TinderMarmiton',
                  ),
                ),
                _LinkRow(
                  icon: Icons.restaurant_menu,
                  label: 'Données des recettes',
                  value: 'themealdb.com',
                  onTap: () => _copy(context, 'https://www.themealdb.com'),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Projet réalisé dans le cadre du cours Dart / Flutter — IPSSI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: palette.inkGhost),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Tinder Marmiton · version $appVersion',
              style: TextStyle(fontSize: 12.5, color: palette.inkGhost),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.red,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tinder Marmiton',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'version $appVersion',
                      style: TextStyle(color: Colors.white70, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Trouver quoi cuisiner ce soir, un swipe à la fois.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Member {
  const _Member({required this.name, required this.initials});

  final String name;
  final String initials;
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isLast});

  final _Member member;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              member.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Développement Dart / Flutter',
                  style: TextStyle(fontSize: 13, color: palette.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: palette.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: palette.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.link, size: 20, color: palette.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: palette.inkFaint),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 18, color: palette.inkIcon),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.tagSurface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: palette.tagText,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: AppPalette.of(context).inkFaint,
      ),
    );
  }
}
