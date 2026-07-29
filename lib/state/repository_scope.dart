import 'package:flutter/widgets.dart';

import '../services/recipe_repository.dart';

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final RecipeRepository repository;

  static RecipeRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(
      scope != null,
      'Aucun RepositoryScope trouvé au-dessus de ce widget.',
    );
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
