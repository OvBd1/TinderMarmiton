import '../models/recipe.dart';
import 'meal_api.dart';
import 'translation_service.dart';

class RecipeRepository {
  RecipeRepository({required this.api, required this.translator});

  final MealApi api;
  final TranslationService translator;

  static const int _concurrency = 3;

  Future<List<Recipe>> fetchRandomBatch(
    int count, {
    Set<String> exclude = const {},
  }) async {
    final recipes = await api.fetchRandomBatch(count, exclude: exclude);

    final translated = <Recipe>[];
    for (var i = 0; i < recipes.length; i += _concurrency) {
      final slice = recipes.skip(i).take(_concurrency).map(_translate);
      translated.addAll(await Future.wait(slice));
    }
    return translated;
  }

  Future<Recipe> _translate(Recipe recipe) async {
    final payload = <String>[
      recipe.name,
      recipe.area,
      ...recipe.ingredients,
      ...recipe.steps,
    ];

    final result = await translator.translateAll(payload);
    if (result.length != payload.length) return recipe;

    var cursor = 2;
    final ingredients = result.sublist(
      cursor,
      cursor + recipe.ingredients.length,
    );
    cursor += recipe.ingredients.length;
    final steps = result.sublist(cursor, cursor + recipe.steps.length);

    return recipe.translated(
      name: result[0],
      area: result[1],
      ingredients: ingredients,
      steps: steps,
    );
  }

  void dispose() {
    api.dispose();
    translator.dispose();
  }
}
