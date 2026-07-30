import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.user.displayName ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email,
  );

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  void _notify(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.red : AppColors.like,
        ),
      );
  }

  Future<void> _saveProfile() async {
    if (_savingProfile || !_profileKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    final emailChanged = _email.text.trim() != widget.user.email;

    try {
      await AuthScope.of(
        context,
      ).updateProfile(displayName: _name.text, email: _email.text);
      if (!mounted) return;

      _notify(
        emailChanged
            ? 'Profil enregistré. Confirme le lien envoyé à ta nouvelle adresse.'
            : 'Profil enregistré.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _notify(error.message, error: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (_savingPassword || !_passwordKey.currentState!.validate()) return;

    setState(() => _savingPassword = true);

    try {
      await AuthScope.of(context).updatePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;

      _currentPassword.clear();
      _newPassword.clear();
      _notify('Mot de passe mis à jour.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _notify(error.message, error: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('Informations'),
          const SizedBox(height: 12),
          Form(
            key: _profileKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  enabled: !_savingProfile,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _email,
                  label: 'Adresse e-mail',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  enabled: !_savingProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Enregistrer',
            icon: Icons.check,
            variant: AppButtonVariant.solid,
            busy: _savingProfile,
            onPressed: _saveProfile,
          ),
          const SizedBox(height: 34),
          const _SectionLabel('Mot de passe'),
          const SizedBox(height: 12),
          Form(
            key: _passwordKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _currentPassword,
                  label: 'Mot de passe actuel',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').isEmpty
                      ? 'Renseigne ton mot de passe actuel.'
                      : null,
                  enabled: !_savingPassword,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _newPassword,
                  label: 'Nouveau mot de passe',
                  icon: Icons.lock_reset_outlined,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _savePassword(),
                  enabled: !_savingPassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Changer le mot de passe',
            icon: Icons.key_outlined,
            variant: AppButtonVariant.outlined,
            busy: _savingPassword,
            onPressed: _savePassword,
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
