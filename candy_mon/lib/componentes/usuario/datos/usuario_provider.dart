import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:candy_mon/componentes/usuario/dominio/usuario.dart';

/// Estado global del jugador: nombre, tipo de cuenta, diamantes y puntajes.
/// Todo se guarda en el telefono con SharedPreferences (funciona offline).
class UsuarioProvider extends ChangeNotifier {
  static const _kDiamantes = 'diamantes';
  static const _kEsPro = 'esPro';
  static const _kRecord = 'record';
  static const int diamantesIniciales = 30;

  // Usuario "logueado" simulado. Cambia el nombre por el tuyo.
  final Usuario usuario = const Usuario(nombre: 'Mateo', email: 'entrenador@candymon.app');

  SharedPreferences? _prefs;
  int _diamantes = diamantesIniciales;
  bool _esPro = false;
  int _record = 0;
  int _puntaje = 0;

  int get diamantes => _diamantes;
  bool get esPro => _esPro;
  String get tipoCuenta => _esPro ? 'PRO' : 'BASIC';
  int get record => _record;
  int get puntaje => _puntaje;

  Future<void> cargar() async {
    _prefs = await SharedPreferences.getInstance();
    _diamantes = _prefs!.getInt(_kDiamantes) ?? diamantesIniciales;
    _esPro = _prefs!.getBool(_kEsPro) ?? false;
    _record = _prefs!.getInt(_kRecord) ?? 0;
    notifyListeners();
  }

  /// Intenta gastar diamantes. Devuelve false si no alcanzan.
  bool gastarDiamantes(int cantidad) {
    if (_diamantes < cantidad) return false;
    _diamantes -= cantidad;
    _prefs?.setInt(_kDiamantes, _diamantes);
    notifyListeners();
    return true;
  }

  void sumarDiamantes(int cantidad) {
    _diamantes += cantidad;
    _prefs?.setInt(_kDiamantes, _diamantes);
    notifyListeners();
  }

  void cambiarPro(bool valor) {
    _esPro = valor;
    _prefs?.setBool(_kEsPro, valor);
    notifyListeners();
  }

  void actualizarPuntaje(int puntaje) {
    _puntaje = puntaje;
    if (puntaje > _record) {
      _record = puntaje;
      _prefs?.setInt(_kRecord, puntaje);
    }
    notifyListeners();
  }
}
