import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../state/auth_scope.dart';
import '../../state/favorites_store.dart';
import '../../theme/app_theme.dart';
import '../home_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;

  bool _resolved = false;

  String? _boundUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription != null) return;

    final auth = AuthScope.of(context);

    final favorites = FavoritesScope.read(context);

    _subscription = auth.authStateChanges().listen((user) {
      if (!mounted) return;

      setState(() {
        _user = user;
        _resolved = true;
      });

      if (user?.uid != _boundUid) {
        _boundUid = user?.uid;
        favorites.bindUser(user?.uid);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) return const _Splash();
    return _user == null ? const LoginPage() : const HomePage();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 64,
              color: AppColors.orange,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}
