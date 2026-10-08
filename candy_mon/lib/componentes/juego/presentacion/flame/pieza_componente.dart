import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Una pieza del tablero: burbuja de color + imagen del Pokemon.
/// Se mueve solo hacia [destino], asi se animan intercambios y caidas.
class PiezaComponente extends PositionComponent {
  static const List<Color> colores = [
    Color(0xFFFF9F1C), // naranja    - charizard
    Color(0xFFFFD60A), // amarillo   - pikachu
    Color(0xFF43B649), // verde pasto - venusaur
    Color(0xFF2F7BEB), // azul       - blastoise
    Color(0xFF9D4EDD), // violeta    - gengar
    Color(0xFFFF5FA2), // rosa      - snorlax
  ];

  /// Nombre de cada pieza = nombre del archivo en assets/images/ (sin .png).
  static const List<String> nombresPiezas = [
    'charizard',
    'pikachu',
    'venusaur',
    'blastoise',
    'gengar',
    'snorlax',
  ];

  /// Imagenes de las piezas (assets/images/charizard.png, pikachu.png, ...).
  /// Si una no existe, esa pieza se ve solo como una burbuja de color.
  static final List<Sprite?> sprites = List.filled(6, null);

  int tipo;
  Vector2 destino;
  bool seleccionada = false;

  bool _explotando = false;
  double _tiempoExplosion = 0;
  double _tiempo = 0;
  double _rebote = 0;

  PiezaComponente({
    required this.tipo,
    required Vector2 position,
    required double tamCelda,
  })  : destino = position.clone(),
        super(
          position: position,
          size: Vector2.all(tamCelda),
          anchor: Anchor.center,
        );

  bool get estaQuieta => position.distanceTo(destino) < 0.5;

  /// Animacion de "explotar": se achica y desaparece.
  void explotar() => _explotando = true;

  /// Pequeño rebote (al mezclar).
  void rebotar() => _rebote = 1;

  @override
  void update(double dt) {
    super.update(dt);
    _tiempo += dt;

    // Movimiento hacia la posicion objetivo (12 celdas por segundo).
    final delta = destino - position;
    final dist = delta.length;
    final step = size.x * 12 * dt;
    if (dist <= step) {
      position.setFrom(destino);
    } else {
      position.add(delta.normalized()..scale(step));
    }

    if (_explotando) {
      // Se infla con un destello blanco y despues se achica.
      _tiempoExplosion += dt;
      if (_tiempoExplosion < 0.08) {
        scale.setAll(1 + _tiempoExplosion / 0.08 * 0.35);
      } else {
        final s = 1.35 * (1 - (_tiempoExplosion - 0.08) / 0.12);
        if (s <= 0) {
          removeFromParent();
          return;
        }
        scale.setAll(s);
      }
      return;
    }

    if (_rebote > 0) _rebote = max(0, _rebote - dt * 3);

    final targetScale = seleccionada ? 1.12 + sin(_tiempo * 10) * 0.05 : 1.0;
    final s = targetScale + sin(_rebote * pi) * 0.25;
    scale.setAll(scale.x + (s - scale.x) * min(1, dt * 18));
  }

  @override
  void render(Canvas canvas) {
    _dibujarPieza(canvas);
    if (_explotando) {
      final f = (1 - _tiempoExplosion / 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(size.x / 2, size.x / 2),
        size.x * 0.48,
        Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha((220 * f).toInt())
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.x * 0.12),
      );
    }
  }

  /// Dibuja la pieza: una "burbuja" del color del Pokemon y su imagen encima.
  void _dibujarPieza(Canvas canvas) {
    final w = size.x;
    final centro = Offset(w / 2, w / 2);
    final radio = w * 0.42;
    final color = colores[tipo % colores.length];

    // Sombra
    canvas.drawCircle(centro.translate(0, w * 0.04), radio, Paint()..color = const Color(0x33000000));

    // Burbuja de color
    canvas.drawCircle(centro, radio, Paint()..color = color);

    // Borde mas oscuro
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = Color.lerp(color, const Color(0xFF000000), 0.2)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );

    // Imagen del Pokemon (pixel art nitido, sin difuminar)
    final sprite = sprites[tipo % sprites.length];
    if (sprite != null) {
      final tamImagen = w * 0.86;
      sprite.render(
        canvas,
        position: Vector2((w - tamImagen) / 2, (w - tamImagen) / 2),
        size: Vector2.all(tamImagen),
        overridePaint: Paint()..filterQuality = FilterQuality.none,
      );
    }
  }
}
