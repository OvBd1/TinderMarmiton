import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

class FavoritesSyncException implements Exception {
  const FavoritesSyncException(this.message, this.localEntries);

  final String message;
  final List<FavoriteEntry> localEntries;

  @override
  String toString() => message;
}

class FavoriteEntry {
  const FavoriteEntry(this.recipe, this.addedAt);

  final Recipe recipe;
  final int addedAt;

  Map<String, dynamic> toJson() => {...recipe.toJson(), 'addedAt': addedAt};

  static FavoriteEntry fromJson(Map<String, dynamic> json) => FavoriteEntry(
    Recipe.fromJson(json),
    json['addedAt'] is num ? (json['addedAt'] as num).toInt() : 0,
  );
}

class LocalFavorites {
  static String _key(String uid) => 'favorites_$uid';

  static String _deletedKey(String uid) => 'favorites_deleted_$uid';

  Future<List<FavoriteEntry>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FavoriteEntry.fromJson)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> save(String uid, List<FavoriteEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid),
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<Map<String, int>> loadDeleted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deletedKey(uid));
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } on Object {
      return {};
    }
  }

  Future<void> saveDeleted(String uid, Map<String, int> deleted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deletedKey(uid), jsonEncode(deleted));
  }
}

abstract interface class RemoteFavorites {
  Future<List<FavoriteEntry>> load(String uid);

  Future<void> add(String uid, FavoriteEntry entry);

  Future<void> remove(String uid, String recipeId);
}

class FirestoreFavorites implements RemoteFavorites {
  FirestoreFavorites({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  @override
  Future<List<FavoriteEntry>> load(String uid) async {
    final snapshot = await _collection(uid).get();

    final entries = <FavoriteEntry>[];
    for (final doc in snapshot.docs) {
      try {
        entries.add(FavoriteEntry.fromJson(doc.data()));
      } on FormatException {
        continue;
      }
    }
    return entries;
  }

  @override
  Future<void> add(String uid, FavoriteEntry entry) =>
      _collection(uid).doc(entry.recipe.id).set(entry.toJson());

  @override
  Future<void> remove(String uid, String recipeId) =>
      _collection(uid).doc(recipeId).delete();
}

class FavoritesRepository {
  FavoritesRepository({required this.local, required this.remote});

  final LocalFavorites local;
  final RemoteFavorites remote;

  static const Duration _remoteTimeout = Duration(seconds: 10);

  Future<List<FavoriteEntry>> load(String uid) async {
    final localEntries = await local.load(uid);
    final deleted = await local.loadDeleted(uid);

    final List<FavoriteEntry> remoteEntries;
    try {
      remoteEntries = await remote.load(uid).timeout(_remoteTimeout);
    } on Object catch (error) {
      debugPrint('Favoris : Firestore injoignable — $error');
      throw FavoritesSyncException(error.toString(), _sorted(localEntries));
    }

    final merged = <String, FavoriteEntry>{};
    for (final entry in [...remoteEntries, ...localEntries]) {
      final id = entry.recipe.id;

      final deletedAt = deleted[id];
      if (deletedAt != null && deletedAt >= entry.addedAt) continue;

      final existing = merged[id];
      if (existing == null || entry.addedAt > existing.addedAt) {
        merged[id] = entry;
      }
    }

    final result = _sorted(merged.values.toList());
    await _flushPending(uid, result, remoteEntries, deleted);
    await local.save(uid, result);

    return result;
  }

  Future<void> _flushPending(
    String uid,
    List<FavoriteEntry> merged,
    List<FavoriteEntry> remoteEntries,
    Map<String, int> deleted,
  ) async {
    final remoteIds = remoteEntries.map((entry) => entry.recipe.id).toSet();

    for (final entry in merged) {
      if (remoteIds.contains(entry.recipe.id)) continue;
      try {
        await remote.add(uid, entry);
      } on Object {
        continue;
      }
    }

    if (deleted.isEmpty) return;

    final remaining = Map<String, int>.from(deleted);
    for (final id in deleted.keys) {
      try {
        if (remoteIds.contains(id)) await remote.remove(uid, id);
        remaining.remove(id);
      } on Object {
        continue;
      }
    }
    await local.saveDeleted(uid, remaining);
  }

  Future<void> add(
    String uid,
    FavoriteEntry entry,
    List<FavoriteEntry> all,
  ) async {
    await local.save(uid, _sorted(all));

    final deleted = await local.loadDeleted(uid);
    if (deleted.remove(entry.recipe.id) != null) {
      await local.saveDeleted(uid, deleted);
    }

    try {
      await remote.add(uid, entry).timeout(_remoteTimeout);
    } on Object catch (error) {
      debugPrint('Favoris : ajout distant impossible — $error');
    }
  }

  Future<void> remove(
    String uid,
    String recipeId,
    List<FavoriteEntry> all,
  ) async {
    await local.save(uid, _sorted(all));

    try {
      await remote.remove(uid, recipeId).timeout(_remoteTimeout);
    } on Object catch (error) {
      debugPrint('Favoris : suppression distante impossible — $error');
      final deleted = await local.loadDeleted(uid);
      deleted[recipeId] = DateTime.now().millisecondsSinceEpoch;
      await local.saveDeleted(uid, deleted);
    }
  }

  static List<FavoriteEntry> _sorted(List<FavoriteEntry> entries) =>
      [...entries]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
}
