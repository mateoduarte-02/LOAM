// Tests de la logica del tablero (no necesitan emulador).
// Correr con:  flutter test
import 'package:candy_mon/componentes/juego/dominio/logica_tablero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el tablero inicial no tiene combinaciones armadas', () {
    for (var seed = 0; seed < 50; seed++) {
      final tablero = LogicaTablero(seed: seed);
      expect(tablero.buscarCombinaciones(), isEmpty);
    }
  });

  test('el tablero inicial siempre tiene al menos un movimiento', () {
    for (var seed = 0; seed < 50; seed++) {
      expect(LogicaTablero(seed: seed).hayMovimientoPosible(), isTrue);
    }
  });

  test('la misma semilla genera el mismo tablero (Reiniciar partida)', () {
    final a = LogicaTablero(seed: 42);
    final b = LogicaTablero(seed: 42);
    expect(a.grilla, equals(b.grilla));
  });

  test('detecta una linea horizontal de 3', () {
    final tablero = LogicaTablero(seed: 1);
    tablero.grilla[0][0] = 9;
    tablero.grilla[0][1] = 9;
    tablero.grilla[0][2] = 9;
    expect(tablero.buscarCombinaciones(),
        containsAll(const [Celda(0, 0), Celda(0, 1), Celda(0, 2)]));
  });

  test('la gravedad vuelve a llenar el tablero', () {
    final tablero = LogicaTablero(seed: 7);
    tablero.vaciar(const [Celda(7, 0), Celda(6, 0), Celda(5, 0)]);
    final result = tablero.aplicarGravedad();
    expect(result.apariciones.length, 3);
    for (final row in tablero.grilla) {
      expect(row.contains(LogicaTablero.vacio), isFalse);
    }
  });
}
