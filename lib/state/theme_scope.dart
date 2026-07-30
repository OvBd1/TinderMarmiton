import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Choix de thème de l'utilisateur, conservé d'une session à l'autre.
///
/// Tant que rien n'a été choisi, l'application suit le réglage du système
/// ([ThemeMode.system]). Le premier appui sur l'interrupteur des paramètres
/// fixe un thème explicite, mémorisé dans les préférences locales.
class ThemeController extends ChangeNotifier {
  ThemeController([this._mode = ThemeMode.system]);

  static const _key = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// `true` quand aucun thème n'a été choisi : c'est le système qui décide.
  bool get followsSystem => _mode == ThemeMode.system;

  /// Relit le thème enregistré. Sans valeur stockée, on reste sur le système.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final mode = switch (prefs.getString(_key)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };

    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Fixe un thème explicite et l'enregistre.
  Future<void> setDark(bool dark) async {
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    if (mode != _mode) {
      _mode = mode;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dark ? 'dark' : 'light');
  }

  /// Rend la main au réglage du système et oublie le choix enregistré.
  Future<void> useSystem() async {
    if (_mode != ThemeMode.system) {
      _mode = ThemeMode.system;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Thème sombre actuellement à l'écran, réglage système compris.
  ///
  /// [platformBrightness] sert d'arbitre quand on suit le système.
  bool isDark(Brightness platformBrightness) => switch (_mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformBrightness == Brightness.dark,
  };
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'Aucun ThemeScope trouvé au-dessus de ce widget.');
    return scope!.notifier!;
  }
}
