import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinder_marmiton/main.dart';
import 'package:tinder_marmiton/models/app_user.dart';
import 'package:tinder_marmiton/models/recipe.dart';
import 'package:tinder_marmiton/pages/auth/login_page.dart';
import 'package:tinder_marmiton/pages/auth/signup_page.dart';
import 'package:tinder_marmiton/pages/edit_profile_page.dart';
import 'package:tinder_marmiton/pages/recipe_detail_page.dart';
import 'package:tinder_marmiton/services/auth_service.dart';
import 'package:tinder_marmiton/services/favorites_repository.dart';
import 'package:tinder_marmiton/services/meal_api.dart';
import 'package:tinder_marmiton/services/recipe_repository.dart';
import 'package:tinder_marmiton/services/translation_service.dart';
import 'package:tinder_marmiton/widgets/swipeable_card.dart';

Map<String, dynamic> rawMeal(String id, String name) {
  final meal = <String, dynamic>{
    'idMeal': id,
    'strMeal': name,
    'strCategory': 'Pasta',
    'strArea': 'Italian',
    'strInstructions':
        'STEP 1 Boil the water.\n'
        'STEP 2 Cook the pasta.\n'
        'STEP 3 Serve hot.',
    'strMealThumb': 'https://example.test/$id.jpg',
    'strSource': null,
  };

  for (var i = 1; i <= 20; i++) {
    meal['strIngredient$i'] = i <= 3 ? 'Ingredient $i' : '';
    meal['strMeasure$i'] = i <= 3 ? '${i * 100} g' : '';
  }
  return meal;
}

http.Response _jsonResponse(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

MealApi fakeApi() {
  var call = 0;
  return MealApi(
    client: MockClient((request) async {
      final index = call++;
      return _jsonResponse({
        'meals': [rawMeal('${1000 + index}', 'Recette ${index + 1}')],
      }, 200);
    }),
  );
}

MealApi failingApi() => MealApi(
  client: MockClient((request) async => _jsonResponse({'meals': null}, 500)),
);

TranslationService fakeTranslator() => TranslationService(
  client: MockClient((request) async {
    final source = request.bodyFields['q'] ?? '';
    final translated = source.split('\n').map((line) => 'FR $line').join('\n');
    return _jsonResponse([
      [
        [translated, source, null, null, 3],
      ],
      null,
      'en',
    ], 200);
  }),
);

TranslationService failingTranslator() => TranslationService(
  client: MockClient((request) async => http.Response('', 500)),
);

TranslationService offTranslator() => TranslationService(
  client: MockClient((request) async => http.Response('', 200)),
  enabled: false,
);

RecipeRepository fakeRepository({TranslationService? translator}) =>
    RecipeRepository(api: fakeApi(), translator: translator ?? offTranslator());

class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initial}) : _current = initial {
    if (initial != null) {
      _accounts[initial.email] = _Account(
        'motdepasse',
        initial.displayName,
        uid: initial.uid,
      );
    }
  }

  final _accounts = <String, _Account>{};
  final _controller = StreamController<AppUser?>.broadcast();

  AppUser? _current;
  int _uidCounter = 0;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  void _emit() => _controller.add(_current);

  @override
  Future<void> signIn({required String email, required String password}) async {
    final account = _accounts[email.trim()];
    if (account == null || account.password != password) {
      throw const AuthException('E-mail ou mot de passe incorrect.');
    }
    _current = AppUser(
      uid: account.uid,
      email: email.trim(),
      displayName: account.displayName,
    );
    _emit();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = email.trim();
    if (_accounts.containsKey(key)) {
      throw const AuthException('Un compte existe déjà avec cette adresse.');
    }
    if (password.length < 6) {
      throw const AuthException(
        'Mot de passe trop faible (6 caractères minimum).',
      );
    }

    final account = _Account(
      password,
      displayName.trim(),
      uid: 'uid-${++_uidCounter}',
    );
    _accounts[key] = account;
    _current = AppUser(
      uid: account.uid,
      email: key,
      displayName: account.displayName,
    );
    _emit();
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _emit();
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? email,
  }) async {
    final user = _current;
    if (user == null) throw const AuthException('Aucun utilisateur connecté.');

    final account = _accounts.remove(user.email)!;
    final newEmail = (email?.trim().isNotEmpty ?? false)
        ? email!.trim()
        : user.email;

    _accounts[newEmail] = _Account(
      account.password,
      displayName.trim(),
      uid: account.uid,
    );
    _current = AppUser(
      uid: user.uid,
      email: newEmail,
      displayName: displayName.trim(),
    );
    _emit();
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _current;
    if (user == null) throw const AuthException('Aucun utilisateur connecté.');

    final account = _accounts[user.email]!;
    if (account.password != currentPassword) {
      throw const AuthException('E-mail ou mot de passe incorrect.');
    }
    _accounts[user.email] = _Account(
      newPassword,
      account.displayName,
      uid: account.uid,
    );
  }

  void dispose() => _controller.close();
}

class _Account {
  _Account(this.password, this.displayName, {String? uid})
    : uid = uid ?? 'uid-0';

  final String password;
  final String? displayName;
  final String uid;
}

class InMemoryFavorites implements RemoteFavorites {
  final Map<String, Map<String, FavoriteEntry>> store = {};

  bool offline = false;

  @override
  Future<List<FavoriteEntry>> load(String uid) async {
    if (offline) throw Exception('hors ligne');
    return (store[uid] ?? {}).values.toList();
  }

  @override
  Future<void> add(String uid, FavoriteEntry entry) async {
    if (offline) throw Exception('hors ligne');
    (store[uid] ??= {})[entry.recipe.id] = entry;
  }

  @override
  Future<void> remove(String uid, String recipeId) async {
    if (offline) throw Exception('hors ligne');
    store[uid]?.remove(recipeId);
  }
}

const signedInUser = AppUser(
  uid: 'uid-1',
  email: 'yann@example.com',
  displayName: 'Yann Bontrond',
);

TinderMarmitonApp buildApp({
  AuthService? auth,
  MealApi? api,
  TranslationService? translator,
  RemoteFavorites? remote,
}) => TinderMarmitonApp(
  auth: auth ?? FakeAuthService(initial: signedInUser),
  recipes: RecipeRepository(
    api: api ?? fakeApi(),
    translator: translator ?? offTranslator(),
  ),
  favorites: FavoritesRepository(
    local: LocalFavorites(),
    remote: remote ?? InMemoryFavorites(),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Recipe.fromMealDb', () {
    test(
      'associe mesure et ingrédient, en ignorant les emplacements vides',
      () {
        final recipe = Recipe.fromMealDb(rawMeal('52772', 'Lasagne'));

        expect(recipe.id, '52772');
        expect(recipe.name, 'Lasagne');

        expect(recipe.category, 'Pâtes');
        expect(recipe.area, 'Italian');
        expect(recipe.ingredients, [
          '100 g Ingredient 1',
          '200 g Ingredient 2',
          '300 g Ingredient 3',
        ]);
      },
    );

    test('découpe les instructions en étapes numérotées', () {
      final recipe = Recipe.fromMealDb(rawMeal('52772', 'Lasagne'));

      expect(recipe.steps, [
        'Boil the water.',
        'Cook the pasta.',
        'Serve hot.',
      ]);
      expect(recipe.description, 'Boil the water. Cook the pasta. Serve hot.');
    });

    test('nettoie les puces et numéros d\'étape', () {
      final bulleted = rawMeal('1', 'Tarte')
        ..['strInstructions'] =
            '▢ STEP 1 Préchauffer le four.\n'
            '▢ 2. Mélanger la farine.\n'
            '3 Enfourner.';

      expect(Recipe.fromMealDb(bulleted).steps, [
        'Préchauffer le four.',
        'Mélanger la farine.',
        'Enfourner.',
      ]);
    });

    test('ne rogne pas une quantité en tête d\'étape', () {
      final quantity = rawMeal('3', 'Pain')
        ..['strInstructions'] = '2 cups of flour go into the bowl first.';

      expect(
        Recipe.fromMealDb(quantity).steps.single,
        startsWith('2 cups of flour'),
      );
    });

    test('se rabat sur un texte générique sans instructions', () {
      final empty = rawMeal('4', 'Mystère')..['strInstructions'] = '';

      expect(Recipe.fromMealDb(empty).steps, isEmpty);
      expect(Recipe.fromMealDb(empty).description, contains('Mystère'));
    });

    test('produit des estimations stables pour un même identifiant', () {
      final first = Recipe.fromMealDb(rawMeal('52772', 'Lasagne'));
      final second = Recipe.fromMealDb(rawMeal('52772', 'Lasagne'));

      expect(first.rating, second.rating);
      expect(first.calories, second.calories);
      expect(first.rating, inInclusiveRange(3.8, 5.0));
      expect(first.prepMinutes, inInclusiveRange(10, 180));
      expect(first.prepMinutes % 5, 0);
    });

    test('rejette une recette sans identifiant, nom ou photo', () {
      final incomplete = rawMeal('52772', 'Lasagne')..['strMealThumb'] = '';

      expect(
        () => Recipe.fromMealDb(incomplete),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MealApi', () {
    test('fetchRandomBatch renvoie des recettes distinctes', () async {
      final recipes = await fakeApi().fetchRandomBatch(5);

      expect(recipes, hasLength(5));
      expect(recipes.map((r) => r.id).toSet(), hasLength(5));
    });

    test('fetchRandomBatch écarte les identifiants déjà connus', () async {
      final recipes = await fakeApi().fetchRandomBatch(
        3,
        exclude: {'1000', '1001'},
      );

      expect(recipes.map((r) => r.id), isNot(contains('1000')));
      expect(recipes.map((r) => r.id), isNot(contains('1001')));
    });

    test('remonte une MealApiException sur erreur serveur', () {
      expect(failingApi().fetchRandom(), throwsA(isA<MealApiException>()));
    });
  });

  group('TranslationService', () {
    test('traduit une liste en préservant l\'ordre', () async {
      final result = await fakeTranslator().translateAll([
        'Chicken breast',
        'Olive oil',
        'Sea salt',
      ]);

      expect(result, ['FR Chicken breast', 'FR Olive oil', 'FR Sea salt']);
    });

    test('rend l\'anglais si le service échoue', () async {
      final source = ['Chicken breast', 'Olive oil'];
      expect(await failingTranslator().translateAll(source), source);
    });

    test('rend l\'anglais si le découpage ne correspond pas', () async {
      final broken = TranslationService(
        client: MockClient(
          (request) async => _jsonResponse([
            [
              ['Une seule ligne', 'x', null, null, 3],
            ],
            null,
            'en',
          ], 200),
        ),
      );

      final source = ['Chicken breast', 'Olive oil'];
      expect(await broken.translateAll(source), source);
    });

    test('ne fait aucun appel quand elle est désactivée', () async {
      final source = ['Chicken breast'];
      expect(await offTranslator().translateAll(source), source);
    });
  });

  group('RecipeRepository', () {
    test('traduit nom, ingrédients et étapes', () async {
      final recipes = await fakeRepository(
        translator: fakeTranslator(),
      ).fetchRandomBatch(1);
      final recipe = recipes.single;

      expect(recipe.name, 'FR Recette 1');

      expect(recipe.category, 'Pâtes');
      expect(recipe.ingredients.first, 'FR 100 g Ingredient 1');
      expect(recipe.steps.first, 'FR Boil the water.');

      expect(recipe.rating, Recipe.fromMealDb(rawMeal('1000', 'x')).rating);
    });

    test('garde l\'anglais si la traduction échoue', () async {
      final recipes = await fakeRepository(
        translator: failingTranslator(),
      ).fetchRandomBatch(1);

      expect(recipes.single.name, 'Recette 1');
      expect(recipes.single.steps.first, 'Boil the water.');
    });
  });

  group('FavoritesRepository', () {
    final recipe = Recipe.fromMealDb(rawMeal('900', 'Tarte'));
    final other = Recipe.fromMealDb(rawMeal('901', 'Soupe'));

    test('fusionne le cache local et la copie distante', () async {
      final local = LocalFavorites();
      final remote = InMemoryFavorites();
      final repository = FavoritesRepository(local: local, remote: remote);

      await local.save('u1', [FavoriteEntry(recipe, 100)]);
      await remote.add('u1', FavoriteEntry(other, 200));

      final merged = await repository.load('u1');

      expect(merged.map((e) => e.recipe.id), ['901', '900']);

      expect(remote.store['u1'], contains('900'));
    });

    test('signale l\'échec distant en rendant le cache local', () async {
      final local = LocalFavorites();
      final remote = InMemoryFavorites()..offline = true;
      final repository = FavoritesRepository(local: local, remote: remote);

      await local.save('u1', [FavoriteEntry(recipe, 100)]);

      await expectLater(
        repository.load('u1'),
        throwsA(
          isA<FavoritesSyncException>().having(
            (e) => e.localEntries.single.recipe.id,
            'favori local conservé',
            '900',
          ),
        ),
      );
    });

    test(
      'une suppression hors ligne n\'est pas annulée par la fusion',
      () async {
        final local = LocalFavorites();
        final remote = InMemoryFavorites();
        final repository = FavoritesRepository(local: local, remote: remote);

        await repository.add('u1', FavoriteEntry(recipe, 100), [
          FavoriteEntry(recipe, 100),
        ]);
        expect(remote.store['u1'], contains('900'));

        remote.offline = true;
        await repository.remove('u1', '900', const []);
        remote.offline = false;

        expect(await repository.load('u1'), isEmpty);
        expect(remote.store['u1'], isNot(contains('900')));
      },
    );

    test('les favoris sont cloisonnés par utilisateur', () async {
      final local = LocalFavorites();
      final repository = FavoritesRepository(
        local: local,
        remote: InMemoryFavorites(),
      );

      await local.save('u1', [FavoriteEntry(recipe, 100)]);

      expect(await repository.load('u1'), hasLength(1));
      expect(await repository.load('u2'), isEmpty);
    });
  });

  group('Comptes', () {
    testWidgets('affiche la connexion quand personne n\'est connecté', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(auth: FakeAuthService()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Se connecter'), findsWidgets);
      expect(find.byType(SwipeableCard), findsNothing);
    });

    testWidgets('refuse un mot de passe incorrect', (tester) async {
      await tester.pumpWidget(
        buildApp(auth: FakeAuthService(initial: signedInUser)..signOut()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'yann@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'mauvais',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('connecte avec les bons identifiants', (tester) async {
      await tester.pumpWidget(
        buildApp(auth: FakeAuthService(initial: signedInUser)..signOut()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'yann@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'motdepasse',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('crée un compte puis entre dans l\'application', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(auth: FakeAuthService()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Camille',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'camille@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'secret123',
      );

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Créer mon compte'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();

      expect(find.byType(SwipeableCard), findsOneWidget);

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('camille@example.com'), findsOneWidget);
    });

    testWidgets('refuse deux mots de passe différents', (tester) async {
      await tester.pumpWidget(buildApp(auth: FakeAuthService()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Camille',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'camille@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
        'autre123',
      );

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Créer mon compte'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
      expect(find.byType(SignUpPage), findsOneWidget);
    });

    testWidgets('la déconnexion ramène à l\'écran de connexion', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Déconnexion'), 200);
      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      expect(find.text('Se déconnecter ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('la modification du profil met à jour l\'affichage', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfilePage), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Yann B.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Yann B.'), findsOneWidget);
    });
  });

  group('Persistance des favoris', () {
    testWidgets('un favori survit à une déconnexion/reconnexion', (
      tester,
    ) async {
      final auth = FakeAuthService(initial: signedInUser);
      final remote = InMemoryFavorites();

      await tester.pumpWidget(buildApp(auth: auth, remote: remote));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableCard), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(remote.store['uid-1'], contains('1000'));

      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      await auth.signIn(email: 'yann@example.com', password: 'motdepasse');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Recette 1'), findsOneWidget);
    });

    testWidgets('les favoris se rechargent depuis Firestore sur un appareil '
        'vierge', (tester) async {
      final remote = InMemoryFavorites();
      final recipe = Recipe.fromMealDb(rawMeal('900', 'Tarte au citron'));
      await remote.add('uid-1', FavoriteEntry(recipe, 500));

      await tester.pumpWidget(buildApp(remote: remote));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();

      expect(find.text('Tarte au citron'), findsOneWidget);
    });

    testWidgets('un Firestore injoignable n\'enferme pas dans le chargement', (
      tester,
    ) async {
      final remote = InMemoryFavorites()..offline = true;

      await tester.pumpWidget(buildApp(remote: remote));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.textContaining('Sauvegarde en ligne indisponible'),
        findsOneWidget,
      );
      expect(find.text('Aucun favori pour l\'instant'), findsOneWidget);
    });

    testWidgets('ajouter un favori marche même sans réseau', (tester) async {
      final remote = InMemoryFavorites()..offline = true;

      await tester.pumpWidget(buildApp(remote: remote));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableCard), const Offset(400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Recette 1'), findsOneWidget);
    });
  });

  group('Application', () {
    testWidgets('la page Découvrir affiche la première recette chargée', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Swipe à droite ce qui te fait envie'), findsOneWidget);
      expect(find.text('Recette 1'), findsOneWidget);
    });

    testWidgets('affiche les recettes traduites quand la traduction marche', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(translator: fakeTranslator()));
      await tester.pumpAndSettle();

      expect(find.text('FR Recette 1'), findsOneWidget);
    });

    testWidgets('affiche un écran d\'erreur si l\'API est injoignable', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(api: failingApi()));
      await tester.pumpAndSettle();

      expect(find.text('Service indisponible'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byType(SwipeableCard), findsNothing);
    });

    testWidgets('un swipe à droite ajoute aux favoris et passe à la suivante', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableCard), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Recette 2'), findsOneWidget);

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Recette 1'), findsOneWidget);
    });

    testWidgets('un swipe à gauche passe la recette sans la mettre en favori', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableCard), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Recette 2'), findsOneWidget);

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun favori pour l\'instant'), findsOneWidget);
    });

    testWidgets('la fiche détail affiche ingrédients et étapes', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwipeableCard));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.text('Ingrédients'), findsOneWidget);
      expect(find.text('100 g Ingredient 1'), findsOneWidget);
      expect(find.text('Préparation'), findsOneWidget);
      expect(find.text('Boil the water.'), findsOneWidget);
      expect(find.text('Serve hot.'), findsOneWidget);

      expect(find.textContaining('Marmiton'), findsNothing);
    });

    testWidgets('les boutons ronds déclenchent le swipe', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pumpAndSettle();

      expect(find.text('Recette 2'), findsOneWidget);

      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Favori'), findsOneWidget);
    });

    testWidgets('on peut retirer une recette des favoris', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SwipeableCard), const Offset(400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Recette 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pumpAndSettle();

      expect(find.text('Recette 1'), findsNothing);
      expect(find.text('Aucun favori pour l\'instant'), findsOneWidget);
    });
  });
}
