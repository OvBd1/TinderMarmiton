import 'package:flutter/material.dart';

import '../state/theme_scope.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = ThemeScope.of(context);
    final isDark = palette.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('Apparence'),
          const SizedBox(height: 10),
          _Group(
            children: [
              _SwitchRow(
                icon: isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
                label: 'Thème sombre',
                detail: isDark
                    ? 'Fonds sombres, plus reposants le soir.'
                    : 'Passe l\'application en fonds sombres.',
                value: isDark,
                onChanged: theme.setDark,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            theme.followsSystem
                ? 'Le thème suit pour l\'instant le réglage de ton appareil.'
                : 'Ton choix est enregistré sur cet appareil.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: palette.inkGhost,
            ),
          ),
        ],
      ),
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

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: palette.ink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: palette.ink),
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.red,
            ),
          ],
        ),
      ),
    );
  }
}
