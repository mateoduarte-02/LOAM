import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' as p;

/// EFECTOS VISUALES (todos dibujados con Canvas, sin imagenes).
///   - ExplosionChispas   : explosion de chispas y estrellitas de colores
///   - AnilloLuz    : anillo de luz que se expande (arcoiris en combos)
///   - TextoFlotante : "+30" que sube y se desvanece
///   - Destello      : brillito que aparece sobre una pieza (decorativo)

final Random _rng = Random();

/// Estrella de 4 puntas (destello).
Path _sparkle(Offset c, double r, double rot) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final rr = i.isEven ? r : r * 0.28;
    final a = rot + i * pi / 4;
    final pt = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  return path..close();
}

class _Spark {
  Vector2 pos;
  Vector2 vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final bool star;
  double rot;
  final double spin;

  _Spark(this.pos, this.vel, this.life, this.size, this.color, this.star, this.rot, this.spin)
      : maxLife = life;
}

/// Explosion de chispas: [power] agranda todo (combos).
class ExplosionChispas extends Component {
  final List<_Spark> _sparks = [];
  final double gravity;

  ExplosionChispas({
    required Vector2 center,
    required Color color,
    int count = 12,
    double power = 1,
    this.gravity = 520,
  }) {
    const gold = Color(0xFFFFE066);
    const white = Color(0xFFFFFFFF);
    final light = Color.lerp(color, white, 0.5)!;
    final palette = [color, color, light, white, gold];
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = (120 + _rng.nextDouble() * 260) * power;
      _sparks.add(_Spark(
        center.clone(),
        Vector2(cos(angle), sin(angle))..scale(speed),
        0.45 + _rng.nextDouble() * 0.45,
        (3 + _rng.nextDouble() * 4) * sqrt(power),
        palette[_rng.nextInt(palette.length)],
        _rng.nextDouble() < 0.35,
        _rng.nextDouble() * pi,
        (_rng.nextDouble() - 0.5) * 12,
      ));
    }
  }

  @override
  void update(double dt) {
    var alive = false;
    for (final s in _sparks) {
      if (s.life <= 0) continue;
      alive = true;
      s.vel.y += gravity * dt;
      s.vel.scale(1 - min(0.9, 1.8 * dt));
      s.pos.add(s.vel * dt);
      s.rot += s.spin * dt;
      s.life -= dt;
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final s in _sparks) {
      if (s.life <= 0) continue;
      final t = (s.life / s.maxLife).clamp(0.0, 1.0);
      final o = s.pos.toOffset();
      final r = s.size * (0.4 + 0.6 * t);

      // Halo de luz (se suma al fondo -> efecto brillante)
      canvas.drawCircle(
        o,
        r * 2.4,
        Paint()
          ..color = s.color.withAlpha((110 * t).toInt())
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.4),
      );

      final core = Paint()..color = s.color.withAlpha((255 * t).toInt());
      if (s.star) {
        canvas.drawPath(_sparkle(o, r * 1.8, s.rot), core);
      } else {
        canvas.drawCircle(o, r, core);
      }
    }
  }
}

/// Anillo de luz que se expande desde [center].
class AnilloLuz extends Component {
  final Offset center;
  final double maxRadius;
  final double duration;
  final List<Color> colors;
  double _t = 0;

  AnilloLuz({
    required Vector2 center,
    required this.maxRadius,
    required this.colors,
    this.duration = 0.45,
  }) : center = center.toOffset();

  /// Anillo arcoiris para combos grandes.
  factory AnilloLuz.rainbow(Vector2 center, double maxRadius) => AnilloLuz(
        center: center,
        maxRadius: maxRadius,
        duration: 0.6,
        colors: const [
          Color(0xFFFF4D6D),
          Color(0xFFFFB703),
          Color(0xFFFFE066),
          Color(0xFF43B649),
          Color(0xFF2F7BEB),
          Color(0xFF9D4EDD),
        ],
      );

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final prog = (_t / duration).clamp(0.0, 1.0);
    final ease = 1 - pow(1 - prog, 3).toDouble();
    final fade = 1 - prog;

    // Destello blanco del centro (solo al principio)
    if (prog < 0.35) {
      final f = 1 - prog / 0.35;
      canvas.drawCircle(
        center,
        maxRadius * 0.55 * ease + 6,
        Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha((200 * f).toInt())
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    for (var i = 0; i < colors.length; i++) {
      final r = maxRadius * ease - i * 5;
      if (r <= 0) continue;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + 7 * fade
          ..color = colors[i].withAlpha((230 * fade).toInt())
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

/// Texto flotante ("+30", "x2").
class TextoFlotante extends Component {
  final Offset start;
  final double fontSize;
  final Color color;
  final String text;
  late final p.TextPainter _painter;
  double _t = 0;
  static const double _life = 1.0;

  TextoFlotante({
    required this.text,
    required Vector2 position,
    required this.color,
    this.fontSize = 26,
  }) : start = position.toOffset();

  @override
  Future<void> onLoad() async {
    _painter = p.TextPainter(
      text: p.TextSpan(
        text: text,
        style: p.TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFFFFF),
          shadows: [
            p.Shadow(color: color, offset: const Offset(2, 2)),
            p.Shadow(color: color, offset: const Offset(-1, -1)),
            const p.Shadow(color: Color(0x88000000), blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final prog = _t / _life;
    // Aparece con "pop" y despues sube desvaneciendose
    final scale = prog < 0.15 ? 0.5 + prog / 0.15 * 0.8 : 1.3 - min(0.3, (prog - 0.15) * 1.2);
    final alpha = prog < 0.7 ? 1.0 : 1 - (prog - 0.7) / 0.3;
    final y = start.dy - 70 * prog;

    canvas.save();
    canvas.translate(start.dx, y);
    canvas.scale(scale);
    canvas.saveLayer(null, Paint()..color = Color.fromARGB((255 * alpha).toInt(), 255, 255, 255));
    _painter.paint(canvas, Offset(-_painter.width / 2, -_painter.height / 2));
    canvas.restore();
    canvas.restore();
  }
}

/// Brillito decorativo que aparece y desaparece girando.
class Destello extends Component {
  final Offset center;
  final double size;
  double _t = 0;
  static const double _life = 0.7;

  Destello({required Vector2 center, required this.size}) : center = center.toOffset();

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final prog = _t / _life;
    final s = sin(prog * pi); // 0 -> 1 -> 0
    final r = size * s;
    canvas.drawCircle(
      center,
      r * 1.4,
      Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha((90 * s).toInt())
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.6),
    );
    canvas.drawPath(
      _sparkle(center, r, prog * pi),
      Paint()..color = const Color(0xFFFFFFFF).withAlpha((240 * s).toInt()),
    );
  }
}
