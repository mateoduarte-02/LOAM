import 'package:flutter/material.dart';

/// Paleta inspirada en el mundo Pokémon: rojo, amarillo y azul,
/// con colores saturados porque el publico son chicos.
class ColoresApp {
  // Principales
  static const rojo = Color(0xFFE3350D);
  static const rojoOscuro = Color(0xFFA81C0A);
  static const amarillo = Color(0xFFFFCB05);
  static const azul = Color(0xFF2A75BB);
  static const azulOscuro = Color(0xFF1D3C78);
  static const verde = Color(0xFF43B649);

  // Secundarios
  static const naranja = Color(0xFFFF9F1C);
  static const violeta = Color(0xFF8B5CF6);
  static const rosa = Color(0xFFFF5FA2);
  static const turquesa = Color(0xFF2EC4B6);
  static const dorado = Color(0xFFFFB703);
  static const diamante = Color(0xFF00B4D8);

  // Fondos con degradado
  static const fondoClaro = [Color(0xFFFFF4C9), Color(0xFFD7E9FF)];
  static const fondoOscuro = [Color(0xFF0F1B3D), Color(0xFF2B0D1A)];
}

class TemaApp {
  static ThemeData get claro => _build(Brightness.light);
  static ThemeData get oscuro => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ColoresApp.rojo,
      brightness: brightness,
      primary: ColoresApp.rojo,
      secondary: ColoresApp.azul,
      tertiary: ColoresApp.amarillo,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColoresApp.rojo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
