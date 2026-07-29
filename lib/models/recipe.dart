import 'package:flutter/material.dart';

enum Difficulty {
  facile('Facile', Color(0xFF2E9E5B)),
  moyen('Moyen', Color(0xFFE58A00)),
  difficile('Difficile', Color(0xFFD93025));

  const Difficulty(this.label, this.color);

  final String label;
  final Color color;
}

@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.prepMinutes,
    required this.difficulty,
    required this.rating,
    required this.calories,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.area,
  });

  final String id;
  final String name;

  final String description;
  final String imageUrl;

  final int prepMinutes;

  final Difficulty difficulty;

  final double rating;

  final int calories;

  final List<String> ingredients;

  final List<String> steps;

  final String category;

  final String area;

  String get prepLabel {
    if (prepMinutes < 60) return '$prepMinutes min';
    final hours = prepMinutes ~/ 60;
    final minutes = prepMinutes % 60;
    return minutes == 0 ? '$hours h' : '$hours h $minutes';
  }

  factory Recipe.fromMealDb(Map<String, dynamic> json) {
    final id = _string(json['idMeal']);
    final name = _string(json['strMeal']);
    final imageUrl = _string(json['strMealThumb']);

    if (id.isEmpty || name.isEmpty || imageUrl.isEmpty) {
      throw const FormatException('Recette TheMealDB incomplète.');
    }

    final steps = _readSteps(_string(json['strInstructions']));
    final ingredients = _readIngredients(json);
    final category = _string(json['strCategory']);
    final textLength = steps.fold<int>(0, (sum, step) => sum + step.length);

    return Recipe(
      id: id,
      name: name,
      description: summarize(steps, name),
      imageUrl: imageUrl,
      prepMinutes: _estimatePrepMinutes(ingredients.length, textLength),
      difficulty: _estimateDifficulty(ingredients.length, textLength),
      rating: _estimateRating(id),
      calories: _estimateCalories(category, id),
      ingredients: ingredients,
      steps: steps,
      category: frenchCategory(category),
      area: _string(json['strArea']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'prepMinutes': prepMinutes,
    'difficulty': difficulty.name,
    'rating': rating,
    'calories': calories,
    'ingredients': ingredients,
    'steps': steps,
    'category': category,
    'area': area,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Recette sérialisée sans identifiant.');
    }

    final name = _string(json['name']);
    final steps = _stringList(json['steps']);

    return Recipe(
      id: id,
      name: name,
      description: _string(json['description']).isEmpty
          ? summarize(steps, name)
          : _string(json['description']),
      imageUrl: _string(json['imageUrl']),
      prepMinutes: _int(json['prepMinutes'], 30),
      difficulty: Difficulty.values.firstWhere(
        (value) => value.name == _string(json['difficulty']),
        orElse: () => Difficulty.moyen,
      ),
      rating: _double(json['rating'], 4.5),
      calories: _int(json['calories'], 500),
      ingredients: _stringList(json['ingredients']),
      steps: steps,
      category: _string(json['category']),
      area: _string(json['area']),
    );
  }

  static List<String> _stringList(Object? value) => value is List
      ? List.unmodifiable(value.whereType<String>())
      : const <String>[];

  static int _int(Object? value, int fallback) =>
      value is num ? value.round() : fallback;

  static double _double(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  Recipe translated({
    required String name,
    required String area,
    required List<String> ingredients,
    required List<String> steps,
  }) {
    return Recipe(
      id: id,
      name: name,
      description: summarize(steps, name),
      imageUrl: imageUrl,
      prepMinutes: prepMinutes,
      difficulty: difficulty,
      rating: rating,
      calories: calories,
      ingredients: List.unmodifiable(ingredients),
      steps: List.unmodifiable(steps),
      category: category,
      area: area,
    );
  }

  static const _categoriesFr = {
    'Beef': 'Bœuf',
    'Breakfast': 'Petit-déjeuner',
    'Chicken': 'Poulet',
    'Dessert': 'Dessert',
    'Goat': 'Chèvre',
    'Lamb': 'Agneau',
    'Miscellaneous': 'Divers',
    'Pasta': 'Pâtes',
    'Pork': 'Porc',
    'Seafood': 'Fruits de mer',
    'Side': 'Accompagnement',
    'Starter': 'Entrée',
    'Vegan': 'Végétalien',
    'Vegetarian': 'Végétarien',
  };

  static String frenchCategory(String category) =>
      _categoriesFr[category] ?? category;

  static List<String> _readIngredients(Map<String, dynamic> json) {
    final result = <String>[];

    for (var i = 1; i <= 20; i++) {
      final ingredient = _string(json['strIngredient$i']);
      if (ingredient.isEmpty) continue;

      final measure = _string(json['strMeasure$i']);
      result.add(measure.isEmpty ? ingredient : '$measure $ingredient');
    }

    return List.unmodifiable(result);
  }

  static List<String> _readSteps(String instructions) {
    final steps = <String>[];

    for (final line in instructions.split(RegExp(r'[\r\n]+'))) {
      final clean = _cleanLine(line);

      if (clean.length < 3) continue;
      steps.add(clean);
    }

    return List.unmodifiable(steps);
  }

  static String _cleanLine(String line) => line
      .replaceAll(RegExp(r'[▢□■◦•·]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceFirst(
        RegExp(r'^(?:step|étape)\s*\d+\s*[:.)-]?\s*', caseSensitive: false),
        '',
      )
      .replaceFirst(
        RegExp(r'^(?:\d{1,2}\s*[:.)-]\s*|\d{1,2}\s+(?=[A-ZÀ-Þ]))'),
        '',
      )
      .trim();

  static String summarize(List<String> steps, String fallbackName) {
    final text = steps.join(' ').trim();
    if (text.isEmpty) return 'Une recette $fallbackName à découvrir.';
    if (text.length <= 160) return text;

    final cut = text.substring(0, 160);
    final lastStop = cut.lastIndexOf('. ');
    if (lastStop > 80) return cut.substring(0, lastStop + 1);

    final lastSpace = cut.lastIndexOf(' ');
    return '${cut.substring(0, lastSpace > 0 ? lastSpace : 160)}…';
  }

  static int _estimatePrepMinutes(int ingredientCount, int instructionLength) {
    final raw = 15 + ingredientCount * 4 + (instructionLength ~/ 150) * 5;
    final clamped = raw.clamp(10, 180);

    return (clamped / 5).round() * 5;
  }

  static Difficulty _estimateDifficulty(
    int ingredientCount,
    int instructionLength,
  ) {
    final score = ingredientCount + instructionLength ~/ 400;
    if (score <= 7) return Difficulty.facile;
    if (score <= 12) return Difficulty.moyen;
    return Difficulty.difficile;
  }

  static double _estimateRating(String id) {
    final value = 38 + _seed(id) % 13;
    return value / 10;
  }

  static const _caloriesByCategory = {
    'Dessert': 480,
    'Beef': 720,
    'Lamb': 700,
    'Pork': 690,
    'Pasta': 620,
    'Chicken': 540,
    'Seafood': 430,
    'Side': 300,
    'Starter': 320,
    'Breakfast': 450,
    'Vegetarian': 340,
    'Vegan': 310,
    'Goat': 600,
    'Miscellaneous': 500,
  };

  static int _estimateCalories(String category, String id) {
    final base = _caloriesByCategory[category] ?? 500;
    return base + _seed(id) % 120;
  }

  static int _seed(String id) =>
      id.codeUnits.fold(7, (acc, unit) => (acc * 31 + unit) & 0x7fffffff);

  static String _string(Object? value) => value is String ? value.trim() : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Recipe && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
