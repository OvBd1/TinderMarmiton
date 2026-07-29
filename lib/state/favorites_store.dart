import 'package:flutter/widgets.dart';

import '../models/recipe.dart';
import '../services/favorites_repository.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore({required this.repository});

  final FavoritesRepository repository;

  final List<FavoriteEntry> _entries = [];

  String? _uid;
  bool _loading = false;
  String? _syncError;

  List<Recipe> get favorites =>
      List.unmodifiable(_entries.map((entry) => entry.recipe));

  int get count => _entries.length;

  bool get isLoading => _loading;

  String? get syncError => _syncError;

  bool isFavorite(Recipe recipe) =>
      _entries.any((entry) => entry.recipe.id == recipe.id);

  Future<void> bindUser(String? uid) async {
    if (uid == _uid) return;

    _uid = uid;
    _entries.clear();

    if (uid == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _syncError = null;
    notifyListeners();

    var loaded = const <FavoriteEntry>[];
    String? error;

    try {
      loaded = await repository.load(uid);
    } on FavoritesSyncException catch (failure) {
      loaded = failure.localEntries;
      error = failure.message;
    } on Object catch (failure) {
      error = failure.toString();
      debugPrint('Favoris : chargement impossible — $failure');
    }

    if (_uid != uid) return;

    _entries
      ..clear()
      ..addAll(loaded);
    _syncError = error;
    _loading = false;
    notifyListeners();
  }

  void add(Recipe recipe) {
    final uid = _uid;
    if (uid == null || isFavorite(recipe)) return;

    final entry = FavoriteEntry(recipe, DateTime.now().millisecondsSinceEpoch);
    _entries.insert(0, entry);
    notifyListeners();

    repository.add(uid, entry, List.of(_entries));
  }

  void remove(Recipe recipe) {
    final uid = _uid;
    if (uid == null) return;

    final index = _entries.indexWhere((entry) => entry.recipe.id == recipe.id);
    if (index == -1) return;

    _entries.removeAt(index);
    notifyListeners();

    repository.remove(uid, recipe.id, List.of(_entries));
  }

  void insertAt(int index, Recipe recipe) {
    final uid = _uid;
    if (uid == null || isFavorite(recipe)) return;

    final entry = FavoriteEntry(recipe, DateTime.now().millisecondsSinceEpoch);
    _entries.insert(index.clamp(0, _entries.length), entry);
    notifyListeners();

    repository.add(uid, entry, List.of(_entries));
  }

  int indexOf(Recipe recipe) =>
      _entries.indexWhere((entry) => entry.recipe.id == recipe.id);

  void toggle(Recipe recipe) =>
      isFavorite(recipe) ? remove(recipe) : add(recipe);
}

class FavoritesScope extends InheritedNotifier<FavoritesStore> {
  const FavoritesScope({
    super.key,
    required FavoritesStore store,
    required super.child,
  }) : super(notifier: store);

  static FavoritesStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(
      scope != null,
      'Aucun FavoritesScope trouvé au-dessus de ce widget.',
    );
    return scope!.notifier!;
  }

  static FavoritesStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<FavoritesScope>();
    assert(
      scope != null,
      'Aucun FavoritesScope trouvé au-dessus de ce widget.',
    );
    return scope!.notifier!;
  }
}
