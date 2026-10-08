/// Constantes del juego en un solo lugar (faciles de ajustar).
class ConstantesJuego {
  ConstantesJuego._();

  /// Movimientos con los que empieza cada partida.
  static const int movimientosIniciales = 20;

  /// Puntos necesarios para 1, 2 y 3 estrellas (la 3ra = "Maestro Pokémon").
  static const List<int> metasEstrellas = [400, 1000, 2000];

  /// Precios de los boosters en diamantes.
  static const int costoMartillo = 8;
  static const int costoMezclar = 5;
  static const int costoMovimientosExtra = 10;

  /// Segundos que dura la publicidad antes de poder cerrarla.
  static const int segundosPublicidad = 5;
}
