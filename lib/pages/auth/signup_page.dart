import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/auth_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import 'auth_shell.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirme ton mot de passe.';
    if (value != _password.text) return 'Les mots de passe ne correspondent pas.';
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthScope.of(context).signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Créer un compte',
      subtitle: 'Tes favoris seront sauvegardés et te suivront partout.',
      children: [
        if (_error case final message?) AuthErrorBanner(message: message),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: 'Nom',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: Validators.name,
                enabled: !_busy,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Adresse e-mail',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                enabled: !_busy,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 14),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  AppTextField(
                    controller: _password,
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    enabled: !_busy,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: const Color(0xFF9A8177),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirm,
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_reset_outlined,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _submit(),
                enabled: !_busy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Créer mon compte',
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Déjà inscrit ?',
              style: TextStyle(color: Color(0xFF8A7B75), fontSize: 14.5),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Se connecter',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
