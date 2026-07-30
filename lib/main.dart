import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/favorites_repository.dart';
import 'services/meal_api.dart';
import 'services/recipe_repository.dart';
import 'services/translation_service.dart';
import 'state/auth_scope.dart';
import 'state/favorites_store.dart';
import 'state/repository_scope.dart';
import 'state/theme_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      webExperimentalAutoDetectLongPolling: true,
    );
  }

  runApp(
    TinderMarmitonApp(
      auth: FirebaseAuthService(),
      recipes: RecipeRepository(
        api: MealApi(),
        translator: TranslationService(),
      ),
      favorites: FavoritesRepository(
        local: LocalFavorites(),
        remote: FirestoreFavorites(),
      ),
    ),
  );
}

class TinderMarmitonApp extends StatefulWidget {
  const TinderMarmitonApp({
    super.key,
    required this.auth,
    required this.recipes,
    required this.favorites,
  });

  final AuthService auth;
  final RecipeRepository recipes;
  final FavoritesRepository favorites;

  @override
  State<TinderMarmitonApp> createState() => _TinderMarmitonAppState();
}

class _TinderMarmitonAppState extends State<TinderMarmitonApp> {
  late final FavoritesStore _store = FavoritesStore(
    repository: widget.favorites,
  );

  final ThemeController _theme = ThemeController();

  @override
  void initState() {
    super.initState();
    _theme.load();
  }

  @override
  void dispose() {
    _store.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: widget.auth,
      child: RepositoryScope(
        repository: widget.recipes,
        child: FavoritesScope(
          store: _store,
          child: ThemeScope(
            controller: _theme,
            child: Builder(
              builder: (context) => MaterialApp(
                title: 'Tinder Marmiton',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: ThemeScope.of(context).mode,
                home: const AuthGate(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
