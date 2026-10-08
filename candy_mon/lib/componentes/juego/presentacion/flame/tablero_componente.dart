import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'package:candy_mon/componentes/juego/dominio/logica_tablero.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/pieza_componente.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/efectos.dart';
import 'package:candy_mon/componentes/juego/presentacion/flame/juego_match3.dart';

/// Tablero visual: dibuja el fondo de la grilla, contiene los caramelos
/// y recibe los toques / deslizamientos del jugador.
class TableroComponente extends PositionComponent
    with HasGameReference<JuegoMatch3>, TapCallbacks, DragCallbacks {
  late LogicaTablero logica;
  List<List<PiezaComponente?>> celdas = [];
  double tamCelda = 40;

  Celda? _seleccionada;
  Celda? _inicioArrastre;
  final Vector2 _arrastreAcumulado = Vector2.zero();
  bool _arrastreUsado = false;

  // Efectos de pantalla
  double _temblor = 0; // intensidad del temblor (pixeles)
  double _destello = 0; // destello blanco sobre el tablero (0..1)
  double _tiempoBrillo = 0;
  final Random _rng = Random();

  /// Hace temblar el tablero (combos grandes).
  void temblar(double intensidad) => _temblor = max(_temblor, intensidad);

  /// Destello blanco sobre todo el tablero.
  void destellar([double cantidad = 0.5]) => _destello = max(_destello, cantidad);

  /// Centro de una celda en coordenadas de pantalla (para los efectos).
  Vector2 centroEnPantalla(Celda c) => position + centroCelda(c.fila, c.columna);

  Celda? get seleccionada => _seleccionada;
  set seleccionada(Celda? value) {
    if (_seleccionada != null) celdas[_seleccionada!.fila][_seleccionada!.columna]?.seleccionada = false;
    _seleccionada = value;
    if (value != null) celdas[value.fila][value.columna]?.seleccionada = true;
  }

  Vector2 centroCelda(int row, int col) =>
      Vector2((col + 0.5) * tamCelda, (row + 0.5) * tamCelda);

  // ---------- Armado y layout ----------

  void armarTablero(int seed) {
    for (final c in children.whereType<PiezaComponente>().toList()) {
      c.removeFromParent();
    }
    _seleccionada = null;
    logica = LogicaTablero(seed: seed);
    celdas = List.generate(logica.filas, (_) => List.filled(logica.columnas, null));
    for (var r = 0; r < logica.filas; r++) {
      for (var c = 0; c < logica.columnas; c++) {
        final pieza = PiezaComponente(
          tipo: logica.grilla[r][c],
          position: centroCelda(r, c),
          tamCelda: tamCelda,
        );
        celdas[r][c] = pieza;
        add(pieza);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final side = min(size.x, size.y) - 12;
    tamCelda = side / 8;
    this.size = Vector2.all(side);
    position = (size - this.size) / 2;

    // Reubica los caramelos al nuevo tamaño.
    for (var r = 0; r < celdas.length; r++) {
      for (var c = 0; c < celdas[r].length; c++) {
        final pieza = celdas[r][c];
        if (pieza == null) continue;
        pieza.size = Vector2.all(tamCelda);
        pieza.destino = centroCelda(r, c);
        pieza.position = pieza.destino.clone();
      }
    }
  }

  // ---------- Operaciones que usa el juego ----------

  bool get todasQuietas {
    for (final row in celdas) {
      for (final pieza in row) {
        if (pieza != null && !pieza.estaQuieta) return false;
      }
    }
    return true;
  }

  void intercambiarCeldas(Celda a, Celda b) {
    logica.intercambiar(a, b);
    final ca = celdas[a.fila][a.columna];
    final cb = celdas[b.fila][b.columna];
    celdas[a.fila][a.columna] = cb;
    celdas[b.fila][b.columna] = ca;
    cb?.destino = centroCelda(a.fila, a.columna);
    ca?.destino = centroCelda(b.fila, b.columna);
  }

  void explotarCeldas(Set<Celda> aExplotar) {
    logica.vaciar(aExplotar);
    for (final celda in aExplotar) {
      celdas[celda.fila][celda.columna]?.explotar();
      celdas[celda.fila][celda.columna] = null;
    }
  }

  void aplicarGravedad() {
    final result = logica.aplicarGravedad();
    for (final f in result.caidas) {
      final pieza = celdas[f.filaOrigen][f.columna];
      celdas[f.filaDestino][f.columna] = pieza;
      celdas[f.filaOrigen][f.columna] = null;
      pieza?.destino = centroCelda(f.filaDestino, f.columna);
    }
    for (final s in result.apariciones) {
      final pieza = PiezaComponente(
        tipo: s.tipo,
        position: centroCelda(s.filaInicio, s.columna),
        tamCelda: tamCelda,
      )..destino = centroCelda(s.fila, s.columna);
      celdas[s.fila][s.columna] = pieza;
      add(pieza);
    }
  }

  void mezclar() {
    seleccionada = null;
    logica.mezclar();
    for (var r = 0; r < logica.filas; r++) {
      for (var c = 0; c < logica.columnas; c++) {
        celdas[r][c]
          ?..tipo = logica.grilla[r][c]
          ..rebotar();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _temblor = max(0, _temblor - dt * 40);
    _destello = max(0, _destello - dt * 2.5);

    // Brillitos decorativos sobre piezas al azar (el tablero "brilla").
    _tiempoBrillo -= dt;
    if (_tiempoBrillo <= 0 && celdas.isNotEmpty) {
      _tiempoBrillo = 0.25 + _rng.nextDouble() * 0.35;
      final c = Celda(_rng.nextInt(8), _rng.nextInt(8));
      final offset = Vector2((_rng.nextDouble() - 0.5) * tamCelda * 0.5,
          (_rng.nextDouble() - 0.5) * tamCelda * 0.5);
      parent?.add(Destello(center: centroEnPantalla(c) + offset, size: tamCelda * 0.22));
    }
  }

  // ---------- Dibujo ----------

  @override
  void renderTree(Canvas canvas) {
    // Recorta para que los caramelos nuevos no se vean arriba del tablero.
    canvas.save();
    if (_temblor > 0) {
      canvas.translate((_rng.nextDouble() - 0.5) * _temblor, (_rng.nextDouble() - 0.5) * _temblor);
    }
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(position.x, position.y, size.x, size.y),
      const Radius.circular(18),
    ));
    super.renderTree(canvas);
    if (_destello > 0) {
      canvas.drawRect(
        Rect.fromLTWH(position.x, position.y, size.x, size.y),
        Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha((160 * _destello).toInt())
          ..blendMode = BlendMode.plus,
      );
    }
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0x55FFFFFF));

    // Pieza seleccionada: circulo blanco alrededor
    if (_seleccionada != null) {
      canvas.drawCircle(
        Offset((_seleccionada!.columna + 0.5) * tamCelda, (_seleccionada!.fila + 0.5) * tamCelda),
        tamCelda * 0.48,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  // ---------- Entrada (toques y deslizamientos) ----------

  Celda? _celdaEn(Vector2 local) {
    final c = (local.x / tamCelda).floor();
    final r = (local.y / tamCelda).floor();
    final celda = Celda(r, c);
    return logica.estaDentro(celda) ? celda : null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.manejarToque(_celdaEn(event.localPosition));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _inicioArrastre = _celdaEn(event.localPosition);
    _arrastreAcumulado.setZero();
    _arrastreUsado = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_arrastreUsado || _inicioArrastre == null) return;
    _arrastreAcumulado.add(event.localDelta);
    if (_arrastreAcumulado.length < tamCelda * 0.35) return;

    final start = _inicioArrastre!;
    final Celda destino;
    if (_arrastreAcumulado.x.abs() > _arrastreAcumulado.y.abs()) {
      destino = Celda(start.fila, start.columna + (_arrastreAcumulado.x > 0 ? 1 : -1));
    } else {
      destino = Celda(start.fila + (_arrastreAcumulado.y > 0 ? 1 : -1), start.columna);
    }
    _arrastreUsado = true;
    if (logica.estaDentro(destino)) game.manejarDeslizamiento(start, destino);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _inicioArrastre = null;
  }
}
