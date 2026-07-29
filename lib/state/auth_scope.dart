import 'package:flutter/widgets.dart';

import '../services/auth_service.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.auth, required super.child});

  final AuthService auth;

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'Aucun AuthScope trouvé au-dessus de ce widget.');
    return scope!.auth;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => auth != oldWidget.auth;
}
