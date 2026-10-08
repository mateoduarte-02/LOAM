import 'dart:math';

/// Posicion de una celda en el tablero.
class Celda {
  final int fila;
  final int columna;
  const Celda(this.fila, this.columna);

  bool esVecina(Celda otra) =>
      (fila - otra.fila).abs() + (columna - otra.columna).abs() == 1;

  @override
  bool operator ==(Object other) =>
      other is Celda && other.fila == fila && other.columna == columna;

  @override
  int get hashCode => fila * 1000 + columna;

  @override
  String toString() => 'Celda($fila, $columna)';
}

/// Una pieza que cae de [filaOrigen] a [filaDestino] en la [columna].
class Caida {
  final int columna, filaOrigen, filaDestino;
  const Caida(this.columna, this.filaOrigen, this.filaDestino);
}

/// Una pieza nueva que aparece arriba del tablero ([filaInicio] es negativo)
/// y cae hasta [fila].
class Aparicion {
  final int columna, fila, tipo, filaInicio;
  const Aparicion(this.columna, this.fila, this.tipo, this.filaInicio);
}

class ResultadoGravedad {
  final List<Caida> caidas;
  final List<Aparicion> apariciones;
  const ResultadoGravedad(this.caidas, this.apariciones);
}

/// LOGICA PURA DEL MATCH-3 (sin graficos).
/// La grilla guarda numeros: cada numero es un tipo de caramelo,
/// y [vacio] (-1) significa celda vacia.
///
/// Separarla de Flame permite testearla (ver test/logica_tablero_test.dart)
/// y explicarla facil en la defensa.
class LogicaTablero {
  static const int vacio = -1;

  final int filas;
  final int columnas;
  final int tipos;
  final Random _rng;
  late final List<List<int>> grilla;

  /// Con la misma [seed] se genera exactamente el mismo tablero
  /// (eso usamos para "Reiniciar partida").
  LogicaTablero({this.filas = 8, this.columnas = 8, this.tipos = 6, int? seed})
      : _rng = Random(seed) {
    grilla = List.generate(filas, (_) => List.filled(columnas, vacio));
    llenarSinCombinaciones();
  }

  int tipoEn(Celda c) => grilla[c.fila][c.columna];

  bool estaDentro(Celda c) =>
      c.fila >= 0 && c.fila < filas && c.columna >= 0 && c.columna < columnas;

  /// Llena el tablero sin combinaciones iniciales y garantizando
  /// que exista al menos un movimiento posible.
  void llenarSinCombinaciones() {
    do {
      for (var r = 0; r < filas; r++) {
        for (var c = 0; c < columnas; c++) {
          int k;
          do {
            k = _rng.nextInt(tipos);
          } while (_formariaCombinacion(r, c, k));
          grilla[r][c] = k;
        }
      }
    } while (!hayMovimientoPosible());
  }

  // Como llenamos de izquierda a derecha y de arriba hacia abajo,
  // solo hace falta mirar las 2 celdas de la izquierda y las 2 de arriba.
  bool _formariaCombinacion(int r, int c, int k) =>
      (c >= 2 && grilla[r][c - 1] == k && grilla[r][c - 2] == k) ||
      (r >= 2 && grilla[r - 1][c] == k && grilla[r - 2][c] == k);

  /// Devuelve todas las celdas que forman parte de una linea de 3 o mas
  /// caramelos iguales (horizontal o vertical).
  Set<Celda> buscarCombinaciones() {
    final result = <Celda>{};

    // Filas
    for (var r = 0; r < filas; r++) {
      var c = 0;
      while (c < columnas) {
        final k = grilla[r][c];
        var end = c + 1;
        while (end < columnas && grilla[r][end] == k) {
          end++;
        }
        if (k != vacio && end - c >= 3) {
          for (var i = c; i < end; i++) {
            result.add(Celda(r, i));
          }
        }
        c = end;
      }
    }

    // Columnas
    for (var c = 0; c < columnas; c++) {
      var r = 0;
      while (r < filas) {
        final k = grilla[r][c];
        var end = r + 1;
        while (end < filas && grilla[end][c] == k) {
          end++;
        }
        if (k != vacio && end - r >= 3) {
          for (var i = r; i < end; i++) {
            result.add(Celda(i, c));
          }
        }
        r = end;
      }
    }
    return result;
  }

  void intercambiar(Celda a, Celda b) {
    final tmp = grilla[a.fila][a.columna];
    grilla[a.fila][a.columna] = grilla[b.fila][b.columna];
    grilla[b.fila][b.columna] = tmp;
  }

  /// Prueba todos los intercambios posibles (derecha y abajo)
  /// y se fija si alguno genera una combinacion.
  bool hayMovimientoPosible() {
    for (var r = 0; r < filas; r++) {
      for (var c = 0; c < columnas; c++) {
        final a = Celda(r, c);
        for (final b in [Celda(r, c + 1), Celda(r + 1, c)]) {
          if (!estaDentro(b)) continue;
          intercambiar(a, b);
          final ok = buscarCombinaciones().isNotEmpty;
          intercambiar(a, b);
          if (ok) return true;
        }
      }
    }
    return false;
  }

  void vaciar(Iterable<Celda> celdas) {
    for (final c in celdas) {
      grilla[c.fila][c.columna] = vacio;
    }
  }

  /// GRAVEDAD: por cada columna, los caramelos bajan a ocupar
  /// los huecos y arriba se generan caramelos nuevos.
  ResultadoGravedad aplicarGravedad() {
    final caidas = <Caida>[];
    final apariciones = <Aparicion>[];

    for (var c = 0; c < columnas; c++) {
      var write = filas - 1; // proxima posicion libre desde abajo
      for (var r = filas - 1; r >= 0; r--) {
        if (grilla[r][c] != vacio) {
          if (r != write) {
            grilla[write][c] = grilla[r][c];
            grilla[r][c] = vacio;
            caidas.add(Caida(c, r, write));
          }
          write--;
        }
      }
      // Quedan (write + 1) huecos arriba: se llenan con caramelos nuevos.
      final missing = write + 1;
      for (var r = write; r >= 0; r--) {
        final k = _rng.nextInt(tipos);
        grilla[r][c] = k;
        apariciones.add(Aparicion(c, r, k, r - missing));
      }
    }
    return ResultadoGravedad(caidas, apariciones);
  }

  /// Mezcla los caramelos hasta que no haya combinaciones armadas
  /// y exista al menos un movimiento.
  void mezclar() {
    final all = <int>[for (final fila in grilla) ...fila];
    var attempts = 0;
    do {
      all.shuffle(_rng);
      var i = 0;
      for (var r = 0; r < filas; r++) {
        for (var c = 0; c < columnas; c++) {
          grilla[r][c] = all[i++];
        }
      }
      attempts++;
      if (attempts > 200) {
        llenarSinCombinaciones(); // caso extremo: tablero nuevo
        return;
      }
    } while (buscarCombinaciones().isNotEmpty || !hayMovimientoPosible());
  }
}
