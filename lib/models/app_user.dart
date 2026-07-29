import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  String get name {
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get initials {
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.uid == uid &&
          other.email == email &&
          other.displayName == displayName);

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}
