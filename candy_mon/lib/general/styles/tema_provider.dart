import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maneja el modo claro / oscuro y lo recuerda entre sesiones.
class TemaProvider extends ChangeNotifier {
  static const _kDark = 'darkMode';
  SharedPreferences? _prefs;
  ThemeMode _mode = ThemeMode.dark; // por defecto: modo oscuro

  ThemeMode get modoTema => _mode;
  bool get esOscuro => _mode == ThemeMode.dark;

  Future<void> cargar() async {
    _prefs = await SharedPreferences.getInstance();
    _mode = (_prefs!.getBool(_kDark) ?? true) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void alternar() {
    _mode = esOscuro ? ThemeMode.light : ThemeMode.dark;
    _prefs?.setBool(_kDark, esOscuro);
    notifyListeners();
  }
}