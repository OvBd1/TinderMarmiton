import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService({http.Client? client, this.enabled = true})
    : _client = client ?? http.Client();

  final http.Client _client;

  final bool enabled;

  static const String _endpoint =
      'https://translate.googleapis.com/translate_a/single';

  static const Duration _timeout = Duration(seconds: 15);

  static const int _chunkBudget = 4000;

  final Map<String, String> _cache = {};

  Future<List<String>> translateAll(List<String> texts) async {
    if (!enabled || texts.isEmpty) return texts;

    final normalized = texts
        .map((t) => t.replaceAll(RegExp(r'\s+'), ' ').trim())
        .toList();

    final result = List<String>.from(normalized);
    final pending = <int>[];

    for (var i = 0; i < normalized.length; i++) {
      final text = normalized[i];
      if (text.isEmpty) continue;

      final cached = _cache[text];
      if (cached != null) {
        result[i] = cached;
      } else {
        pending.add(i);
      }
    }

    if (pending.isEmpty) return result;

    for (final chunk in _chunk(pending, normalized)) {
      final sources = chunk.map((i) => normalized[i]).toList();
      final translated = await _translateChunk(sources);
      if (translated == null) continue;

      for (var j = 0; j < chunk.length; j++) {
        result[chunk[j]] = translated[j];
        _cache[sources[j]] = translated[j];
      }
    }

    return result;
  }

  static List<List<int>> _chunk(List<int> indexes, List<String> texts) {
    final chunks = <List<int>>[];
    var current = <int>[];
    var size = 0;

    for (final index in indexes) {
      final length = texts[index].length;

      if (current.isNotEmpty && size + length > _chunkBudget) {
        chunks.add(current);
        current = <int>[];
        size = 0;
      }

      current.add(index);
      size += length + 1;
    }

    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  Future<List<String>?> _translateChunk(List<String> sources) async {
    final uri = Uri.parse('$_endpoint?client=gtx&sl=en&tl=fr&dt=t');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: {'q': sources.join('\n')},
            encoding: utf8,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List || decoded.isEmpty) return null;

      final segments = decoded.first;
      if (segments is! List) return null;

      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty && segment.first is String) {
          buffer.write(segment.first as String);
        }
      }

      final parts = buffer.toString().split('\n');

      if (parts.length != sources.length) return null;

      return parts.map((p) => p.trim()).toList();
    } on Object {
      return null;
    }
  }

  void dispose() => _client.close();
}
