# Tinder Marmiton

Application Flutter de découverte de recettes façon Tinder : on swipe à droite ce
qui donne envie, à gauche ce qui ne donne pas. Les recettes viennent de
[TheMealDB](https://www.themealdb.com/api.php), sont traduites en français à la
volée, et les favoris sont synchronisés entre l'appareil et Firestore.

Projet réalisé dans le cadre du cours Dart/Flutter (IPSSI).

## Fonctionnalités

- **Découvrir** — pile de cartes swipables. Droite = favori, gauche = passer. Un
  tap ouvre la fiche détaillée. Les recettes sont chargées par lot de 8 et la
  pile se recharge automatiquement quand il n'en reste que 3.
- **Fiche recette** — photo, catégorie, origine, temps de préparation, difficulté,
  note, calories, liste d'ingrédients avec quantités et étapes de préparation.
- **Favoris** — liste des recettes likées, suppression avec possibilité d'annuler,
  compteur sur la barre de navigation.
- **Comptes** — inscription et connexion par e-mail / mot de passe, modification
  du nom, de l'adresse e-mail et du mot de passe.
- **Traduction automatique** — nom, origine, ingrédients et étapes sont traduits
  de l'anglais vers le français. En cas d'échec du service, le texte anglais
  d'origine est conservé plutôt que d'afficher une erreur.
- **Mode dégradé** — l'application reste utilisable si Firestore est injoignable :
  les favoris sont lus et écrits localement, puis resynchronisés au retour du
  réseau.

## Stack

| Élément | Version |
|---|---|
| Flutter | 3.44.8 (stable) |
| Dart SDK | `^3.12.2` |
| `firebase_core` | `^4.12.1` |
| `firebase_auth` | `^6.5.6` |
| `cloud_firestore` | `^6.7.1` |
| `http` | `^1.6.0` |
| `shared_preferences` | `^2.5.5` |
| `bouncy_button` | `^1.0.4` |

Interface en Material 3. La gestion d'état repose uniquement sur le framework
(`ChangeNotifier` + `InheritedNotifier`), sans package externe.

Les boutons d'action utilisent [`bouncy_button`](https://pub.dev/packages/bouncy_button)
pour leur relief 3D et leur animation d'enfoncement. Ils passent tous par
[lib/widgets/app_button.dart](lib/widgets/app_button.dart), qui applique la
charte graphique (dégradé orange → rouge ou rouge plein, coins à 18, hauteur 54)
au lieu de configurer le package page par page.

## Architecture

```
lib/
├── main.dart                  Point d'entrée : init Firebase, injection des services
├── firebase_options.dart      Généré par FlutterFire (android, ios, macos, web, windows)
├── models/
│   ├── recipe.dart            Recette + parsing TheMealDB + (dé)sérialisation JSON
│   └── app_user.dart          Utilisateur applicatif, découplé de firebase_auth
├── services/
│   ├── meal_api.dart          Client HTTP TheMealDB
│   ├── translation_service.dart  Traduction EN → FR avec cache mémoire
│   ├── recipe_repository.dart Compose l'API et la traduction
│   ├── auth_service.dart      Interface AuthService + implémentation Firebase
│   └── favorites_repository.dart  Favoris : SharedPreferences + Firestore
├── state/
│   ├── auth_scope.dart        Expose AuthService dans l'arbre de widgets
│   ├── repository_scope.dart  Expose RecipeRepository
│   └── favorites_store.dart   État des favoris (ChangeNotifier) + FavoritesScope
├── pages/
│   ├── auth/                  AuthGate, connexion, inscription
│   ├── home_page.dart         Navigation à 3 onglets
│   ├── discover_page.dart     Pile de cartes swipables
│   ├── favorites_page.dart    Liste des favoris
│   ├── recipe_detail_page.dart
│   ├── profile_page.dart
│   ├── edit_profile_page.dart
│   └── about_page.dart        Présentation de l'app, stack et équipe
├── widgets/                   Composants réutilisables (boutons, carte, chips…)
└── theme/app_theme.dart       Thème Material 3
```

Les services sont définis derrière des interfaces (`AuthService`,
`RemoteFavorites`) et injectés depuis `main.dart`. C'est ce qui permet aux tests
de substituer des implémentations en mémoire sans jamais toucher au réseau ni à
Firebase.

### Comment fonctionnent les favoris

Chaque favori existe à deux endroits : dans `SharedPreferences` et dans
`users/{uid}/favorites/{recipeId}` sur Firestore. Au chargement, les deux
sources sont fusionnées en gardant la version la plus récente (champ `addedAt`).

Une suppression effectuée hors ligne est enregistrée localement comme une
« pierre tombale » horodatée, pour qu'elle ne soit pas ressuscitée par la copie
distante lors de la fusion suivante. Elle est rejouée sur Firestore dès que le
réseau revient.

### À propos des données affichées

TheMealDB ne fournit ni temps de préparation, ni difficulté, ni note, ni
calories. Ces quatre valeurs sont **estimées** dans `Recipe.fromMealDb` à partir
du nombre d'ingrédients, de la longueur des instructions et de la catégorie.
Elles sont déterministes (même recette → même valeur) mais elles n'ont aucune
valeur nutritionnelle réelle.

## Installation

```bash
git clone https://github.com/OvBd1/TinderMarmiton.git
cd TinderMarmiton
flutter pub get
```

### Configuration Firebase

Le fichier `android/app/google-services.json` **n'est pas versionné**. Sans lui,
la compilation Android échoue. Deux options :

```bash
# Option 1 — regénérer toute la configuration (nécessite la CLI flutterfire)
dart pub global activate flutterfire_cli
flutterfire configure --project=tinder-marmiton

# Option 2 — télécharger le fichier depuis la console Firebase
# Paramètres du projet → Vos applications → Android → google-services.json
# puis le placer dans android/app/
```

Le projet Firebase doit avoir :

- l'authentification **E-mail/Mot de passe** activée ;
- **Cloud Firestore** activé, avec les règles de [firestore.rules](firestore.rules)
  déployées (`firebase deploy --only firestore:rules`).

Ces règles restreignent chaque utilisateur à ses propres favoris :

```
match /users/{userId}/favorites/{recipeId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Lancer l'application

```bash
flutter run                 # appareil connecté ou émulateur
flutter run -d chrome       # web
flutter run -d windows      # bureau Windows
```

Plateformes configurées côté Firebase : Android, iOS, macOS, Web et Windows.
**Linux n'est pas supporté** — `DefaultFirebaseOptions` lève une
`UnsupportedError` sur cette plateforme.

## Tests

```bash
flutter test
```

40 tests dans [test/app_test.dart](test/app_test.dart), couvrant :

- le parsing TheMealDB (ingrédients, découpage des étapes, nettoyage des puces
  et numéros, stabilité des estimations, rejet des recettes incomplètes) ;
- le client HTTP et le service de traduction, y compris leurs modes de repli ;
- la fusion local/distant des favoris, le cloisonnement par utilisateur et les
  suppressions hors ligne ;
- les parcours d'interface : connexion, inscription, swipe, ajout et retrait de
  favori, déconnexion, édition du profil, page À propos.

Aucun test n'appelle le réseau : `http` est remplacé par un `MockClient`,
Firestore par une implémentation en mémoire et `SharedPreferences` par son mock.

## Équipe

- Yanis Bontrond
- Sébastien Gerard
- Raphael Touzet
