import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

abstract interface class AuthService {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<void> updateProfile({required String displayName, String? email});

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth})
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  static AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());

      await credential.user?.reload();
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateProfile({
    required String displayName,
    String? email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Aucun utilisateur connecté.');
    }

    await _guard(() async {
      await user.updateDisplayName(displayName.trim());

      final target = email?.trim();
      if (target != null && target.isNotEmpty && target != user.email) {
        await user.verifyBeforeUpdateEmail(target);
      }

      await user.reload();
    });
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException('Aucun utilisateur connecté.');
    }

    await _guard(() async {
      await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        ),
      );
      await user.updatePassword(newPassword);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    }
  }

  static String _messageFor(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'requires-recent-login':
        return 'Reconnecte-toi avant de modifier cette information.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion réseau.';
      case 'operation-not-allowed':
        return 'La connexion par e-mail n\'est pas activée sur le projet.';
      default:
        return error.message ?? 'Échec de l\'authentification.';
    }
  }
}
