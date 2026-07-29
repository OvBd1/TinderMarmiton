import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class MealApiException implements Exception {
  const MealApiException(this.message);

  final String message;

  @override
  String toString() => 'MealApiException: $message';
}

class MealApi {
  MealApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  static const Duration _timeout = Duration(seconds: 12);

  Future<Recipe> fetchRandom() async {
    final uri = Uri.parse('$baseUrl/random.php');

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const MealApiException('Le serveur met trop de temps à répondre.');
    } on Object {
      throw const MealApiException('Impossible de joindre TheMealDB.');
    }

    if (response.statusCode != 200) {
      throw MealApiException('TheMealDB a répondu ${response.statusCode}.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const MealApiException('Réponse illisible de TheMealDB.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const MealApiException('Réponse inattendue de TheMealDB.');
    }

    final meals = decoded['meals'];
    if (meals is! List || meals.isEmpty) {
      throw const MealApiException('Aucune recette reçue.');
    }

    final first = meals.first;
    if (first is! Map<String, dynamic>) {
      throw const MealApiException('Recette illisible.');
    }

    try {
      return Recipe.fromMealDb(first);
    } on FormatException catch (error) {
      throw MealApiException(error.message);
    }
  }

  Future<List<Recipe>> fetchRandomBatch(
    int count, {
    Set<String> exclude = const {},
  }) async {
    if (count <= 0) return const [];

    final collected = <String, Recipe>{};
    Object? lastError;

    for (var round = 0; round < 2 && collected.length < count; round++) {
      final missing = count - collected.length;
      final results = await Future.wait(
        List.generate(
          missing,
          (_) => fetchRandom().then<Recipe?>(
            (recipe) => recipe,
            onError: (Object error) {
              lastError = error;
              return null;
            },
          ),
        ),
      );

      for (final recipe in results) {
        if (recipe == null) continue;
        if (exclude.contains(recipe.id)) continue;
        collected[recipe.id] = recipe;
      }
    }

    if (collected.isEmpty) {
      final error = lastError;
      throw error is MealApiException
          ? error
          : const MealApiException('Aucune recette n\'a pu être chargée.');
    }

    return List.unmodifiable(collected.values);
  }

  void dispose() => _client.close();
}
