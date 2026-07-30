import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../state/auth_scope.dart';
import '../state/favorites_store.dart';
import '../theme/app_theme.dart';
import 'about_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription != null) return;

    final auth = AuthScope.of(context);
    _user = auth.currentUser;

    _subscription = auth.authStateChanges().listen((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _notImplemented(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('« $action » n\'est pas encore disponible.'),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = AuthScope.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tes favoris restent enregistrés sur ton compte, tu les '
          'retrouveras à la prochaine connexion.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await auth.signOut();
  }

  void _openAbout(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AboutPage()));
  }

  void _openEditProfile(BuildContext context, AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditProfilePage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final favorites = FavoritesScope.of(context).favorites;

    final averageRating = favorites.isEmpty
        ? null
        : favorites.map((r) => r.rating).reduce((a, b) => a + b) /
              favorites.length;
    final averagePrep = favorites.isEmpty
        ? null
        : favorites.map((r) => r.prepMinutes).reduce((a, b) => a + b) ~/
              favorites.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),
          if (user != null) _ProfileHeader(user: user),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatCard(
                value: '${favorites.length}',
                label: favorites.length > 1 ? 'Favoris' : 'Favori',
                icon: Icons.favorite,
                color: AppColors.red,
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: averagePrep == null ? '—' : '$averagePrep min',
                label: 'Temps moy.',
                icon: Icons.schedule,
                color: AppColors.orange,
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: averageRating == null
                    ? '—'
                    : averageRating.toStringAsFixed(1),
                label: 'Note moy.',
                icon: Icons.star_rounded,
                color: const Color(0xFFF5B301),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('Compte'),
          const SizedBox(height: 10),
          _ActionGroup(
            children: [
              _ActionRow(
                icon: Icons.edit_outlined,
                label: 'Modifier le profil',
                onTap: user == null
                    ? () {}
                    : () => _openEditProfile(context, user),
              ),
              _ActionRow(
                icon: Icons.settings_outlined,
                label: 'Paramètres',
                onTap: () => _notImplemented(context, 'Paramètres'),
              ),
              _ActionRow(
                icon: Icons.info_outline,
                label: 'À propos',
                onTap: () => _openAbout(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ActionGroup(
            children: [
              _ActionRow(
                icon: Icons.logout,
                label: 'Déconnexion',
                color: AppColors.red,
                onTap: () => _confirmSignOut(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Tinder Marmiton · version 0.1.0',
              style: TextStyle(fontSize: 12.5, color: Color(0xFFA89791)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Gourmand confirmé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E4DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9A8177)),
            ),
          ],
        ),
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Color(0xFF9A8177),
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E4DE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? const Color(0xFF3D3330);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF5EBE6))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: foreground),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 22, color: Color(0xFFBFA79D)),
          ],
        ),
      ),
    );
  }
}
