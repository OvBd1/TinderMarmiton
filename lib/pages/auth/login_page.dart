import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/auth_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import 'auth_shell.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthScope.of(
        context,
      ).signIn(email: _email.text, password: _password.text);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Bon retour !',
      subtitle: 'Connecte-toi pour retrouver tes recettes favorites.',
      children: [
        if (_error case final message?) AuthErrorBanner(message: message),
        Form(
          key: _formKey,
          child: Column(
            children: [
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
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _submit(),
                    enabled: !_busy,
                    autofillHints: const [AutofillHints.password],
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Se connecter',
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Pas encore de compte ?',
              style: TextStyle(color: Color(0xFF8A7B75), fontSize: 14.5),
            ),
            TextButton(
              onPressed: _busy ? null : _openSignUp,
              child: const Text(
                'Créer un compte',
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
