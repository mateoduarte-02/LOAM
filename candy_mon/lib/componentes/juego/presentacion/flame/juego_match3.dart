import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart' show Sprite, Vector2;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/tablero_componente.dart';
import 'package:candy_mon/componentes/juego/dominio/logica_tablero.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/pieza_componente.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/efectos.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';

enum EstadoJuego { listo, jugando, pausado, terminado }

class _Espera {
  double restante;
  final bool hastaQuietas;
  final Completer<void> completer = Completer<void>();
  _Espera(this.restante, this.hastaQuietas);
}

/// JUEGO PRINCIPAL (Flame).
///
/// Se comunica con Flutter mediante [ValueNotifier]s: la UI (header,
/// botonera, overlays) escucha estos valores y llama a los metodos
/// publicos [iniciar], [pausar], [reanudar], [reiniciar], [nuevaPartida], etc.
/// Asi los controles quedan FUERA del juego, como pide la consigna.
class JuegoMatch3 extends FlameGame {
  static const List<String> _mensajesCombo = [
    '¡Súper efectivo!',
    '¡Golpe crítico!',
    '¡Combo salvaje!',
    '¡Nivel legendario!',
  ];

  final ValueNotifier<int> puntaje = ValueNotifier(0);
  final ValueNotifier<int> movimientos = ValueNotifier(ConstantesJuego.movimientosIniciales);
  final ValueNotifier<EstadoJuego> estado = ValueNotifier(EstadoJuego.listo);
  final ValueNotifier<String?> mensaje = ValueNotifier(null);


  late final TableroComponente tablero;
  final Random _rng = Random();
  final List<_Espera> _esperas = [];
  int _semilla = 0;
  int _generacion = 0; // cambia al reiniciar: corta animaciones viejas
  bool _ocupado = false;
  double _tiempoMensaje = 0;

  /// Fondo transparente: se ve el degradado de Flutter (modo claro/oscuro).
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await _cargarImagenesPiezas();
    tablero = TableroComponente();
    await add(tablero);
    nuevaPartida();
  }

  /// Carga assets/images/charizard.png, pikachu.png, venusaur.png,
  /// blastoise.png, gengar.png y snorlax.png.
  /// Si alguna falta, esa pieza se ve solo como una burbuja de color.
  Future<void> _cargarImagenesPiezas() async {
    // Lista de archivos que Flutter metio dentro de la app.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().where((a) => a.startsWith('assets/')).toList();
    debugPrint('📦 Imagenes dentro de la app: ${bundled.isEmpty ? "NINGUNA" : bundled.join(", ")}');

    for (var i = 0; i < PiezaComponente.sprites.length; i++) {
      final name = PiezaComponente.nombresPiezas[i];
      final path = 'assets/images/$name.png';
      if (!bundled.contains(path)) {
        PiezaComponente.sprites[i] = null;
        debugPrint('❌ Falta $path (se ve solo la burbuja de color)');
        continue;
      }
      try {
        PiezaComponente.sprites[i] = Sprite(await images.load('$name.png'));
        debugPrint('✅ Imagen cargada: $path');
      } catch (e) {
        PiezaComponente.sprites[i] = null;
        debugPrint('❌ $path existe pero no se pudo leer (¿es realmente PNG?) -> $e');
      }
    }
  }

  bool get _puedeJugar => estado.value == EstadoJuego.jugando && !_ocupado;

  // ================= CONTROLES (llamados desde la botonera) =================

  void iniciar() {
    if (estado.value == EstadoJuego.listo) estado.value = EstadoJuego.jugando;
  }

  void pausar() {
    if (estado.value != EstadoJuego.jugando) return;
    pauseEngine();
    estado.value = EstadoJuego.pausado;
  }

  void reanudar() {
    if (estado.value != EstadoJuego.pausado) return;
    resumeEngine();
    estado.value = EstadoJuego.jugando;
  }

  /// Reinicia la MISMA partida (mismo tablero inicial).
  void reiniciar() => _prepararPartida(_semilla);

  /// Partida nueva con un tablero distinto.
  void nuevaPartida() => _prepararPartida(_rng.nextInt(1 << 31));

  void _prepararPartida(int seed) {
    _generacion++;
    _ocupado = false;
    _esperas.clear();
    _semilla = seed;
    tablero.armarTablero(seed);
    puntaje.value = 0;
    movimientos.value = ConstantesJuego.movimientosIniciales;
    mensaje.value = null;
    estado.value = EstadoJuego.listo;
    if (paused) resumeEngine();
  }

  // ================= BOOSTERS (se pagan con diamantes) =================

  void sumarMovimientos(int cantidad) {
    movimientos.value += cantidad;
    if (estado.value == EstadoJuego.terminado) estado.value = EstadoJuego.jugando;
  }

  bool get puedeUsarBooster => _puedeJugar;

  /// Muestra un mensaje grande en el centro del tablero.
  void mostrarMensaje(String text) => _mostrarMensaje(text);

  // ================= ENTRADA =================

  void manejarToque(Celda? celda) {
    if (!_puedeJugar || celda == null) return;

    final actual = tablero.seleccionada;
    if (actual == null) {
      tablero.seleccionada = celda;
    } else if (actual == celda) {
      tablero.seleccionada = null;
    } else if (actual.esVecina(celda)) {
      tablero.seleccionada = null;
      _intentarIntercambio(actual, celda);
    } else {
      tablero.seleccionada = celda;
    }
  }

  void manejarDeslizamiento(Celda from, Celda to) {
    if (!_puedeJugar) return;
    tablero.seleccionada = null;
    _intentarIntercambio(from, to);
  }

  // ================= LOGICA DE TURNO =================

  Future<void> _intentarIntercambio(Celda a, Celda b) async {
    final gen = _generacion;
    _ocupado = true;

    ServicioSonido.instancia.reproducir('swap', volume: 0.5);
    tablero.intercambiarCeldas(a, b);
    await _esperar(0, hastaQuietas: true);
    if (gen != _generacion) return;

    final combinaciones = tablero.logica.buscarCombinaciones();
    if (combinaciones.isEmpty) {
      // Movimiento invalido: vuelve a su lugar.
      ServicioSonido.instancia.reproducir('fail', volume: 0.6);
      tablero.intercambiarCeldas(a, b);
      await _esperar(0, hastaQuietas: true);
      if (gen != _generacion) return;
      _ocupado = false;
      return;
    }

    movimientos.value--;
    await _cascada(combinaciones, gen);
  }

  /// Explota combinaciones, aplica gravedad y repite mientras se formen
  /// combinaciones nuevas (cascadas = combos que suman mas puntos).
  Future<void> _cascada(Set<Celda> initial, int gen) async {
    var combinaciones = initial;
    var combo = 0;

    while (combinaciones.isNotEmpty) {
      combo++;
      final puntos = combinaciones.length * 10 * combo;
      puntaje.value += puntos;
      if (combo >= 2) {
        _mostrarMensaje(_mensajesCombo[min(combo - 2, _mensajesCombo.length - 1)]);
      } else if (combinaciones.length >= 5) {
        _mostrarMensaje('¡Ataque especial!');
      } else if (combinaciones.length == 4) {
        _mostrarMensaje('¡Genial!');
      }

      ServicioSonido.instancia.reproducir(combo >= 2 ? 'combo' : 'pop');
      _crearEfectos(combinaciones, combo, puntos);
      tablero.explotarCeldas(combinaciones);
      await _esperar(0.2);
      if (gen != _generacion) return;

      tablero.aplicarGravedad();
      await _esperar(0.05, hastaQuietas: true);
      if (gen != _generacion) return;

      combinaciones = tablero.logica.buscarCombinaciones();
    }

    if (!tablero.logica.hayMovimientoPosible()) {
      tablero.mezclar();
      _mostrarMensaje('¡Sin movimientos, mezclando!');
    }

    _ocupado = false;
    // El sonido de fin (festejo o derrota) lo elige la pantalla de juego.
    if (movimientos.value <= 0) estado.value = EstadoJuego.terminado;
  }

  /// Luces, chispas y temblor segun el tamaño de la jugada.
  void _crearEfectos(Set<Celda> combinaciones, int combo, int puntos) {
    final big = combinaciones.length >= 5 || combo >= 3;
    final power = 1.0 + (combo - 1) * 0.35 + (combinaciones.length >= 5 ? 0.5 : 0);
    final centroJugada = Vector2.zero();

    for (final celda in combinaciones) {
      final tipo = tablero.logica.tipoEn(celda);
      final color = PiezaComponente.colores[(tipo < 0 ? 0 : tipo) % PiezaComponente.colores.length];
      final center = tablero.centroEnPantalla(celda);
      centroJugada.add(center);
      add(ExplosionChispas(center: center, color: color, count: big ? 16 : 10, power: power));
      add(AnilloLuz(
        center: center,
        maxRadius: tablero.tamCelda * 0.75,
        colors: [color, const Color(0xFFFFFFFF)],
        duration: 0.35,
      ));
    }
    centroJugada.scale(1 / combinaciones.length);

    // Puntos flotantes
    add(TextoFlotante(
      text: combo >= 2 ? '+$puntos  x$combo' : '+$puntos',
      position: centroJugada,
      color: combo >= 2 ? const Color(0xFFE3350D) : const Color(0xFF2A75BB),
      fontSize: 22 + min(combo, 4) * 4.0,
    ));

    // Jugadas grandes: arcoiris, temblor y destello del tablero
    if (combinaciones.length >= 4 || combo >= 2) {
      add(AnilloLuz.rainbow(centroJugada, tablero.tamCelda * (2 + combo * 0.6)));
      tablero.temblar(4.0 + combo * 3 + (combinaciones.length >= 5 ? 6 : 0));
    }
    if (big) {
      tablero.destellar(0.45);
      add(ExplosionChispas(
        center: centroJugada,
        color: const Color(0xFFFFE066),
        count: 30,
        power: 1.8,
        gravity: 260,
      ));
    }
  }

  void _mostrarMensaje(String text) {
    mensaje.value = text;
    _tiempoMensaje = 1.0;
  }

  /// Espera [segundos] de tiempo DE JUEGO (si se pausa, la espera se pausa)
  /// y opcionalmente hasta que todas las animaciones terminen.
  Future<void> _esperar(double segundos, {bool hastaQuietas = false}) {
    final w = _Espera(segundos, hastaQuietas);
    _esperas.add(w);
    return w.completer.future;
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final w in List.of(_esperas)) {
      w.restante -= dt;
      if (w.restante <= 0 && (!w.hastaQuietas || tablero.todasQuietas)) {
        _esperas.remove(w);
        w.completer.complete();
      }
    }

    if (_tiempoMensaje > 0) {
      _tiempoMensaje -= dt;
      if (_tiempoMensaje <= 0) mensaje.value = null;
    }
  }
}
