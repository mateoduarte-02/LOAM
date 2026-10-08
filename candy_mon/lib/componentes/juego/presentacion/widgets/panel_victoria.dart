import 'dart:math';

import 'package:flutter/material.dart';

import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/general/widgets/poke_widgets.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';

/// PANTALLA DE FIN DE PARTIDA con festejo:
///   - lluvia de confeti
///   - rayos de luz girando detras de la Pokébola
///   - 0 a 3 estrellas segun el puntaje (aparecen de a una)
///   - puntaje que cuenta hacia arriba
///   - cartel de "¡NUEVO RÉCORD!" si superaste tu mejor marca
class PanelVictoria extends StatefulWidget {
  static int estrellasPara(int puntaje) =>
      ConstantesJuego.metasEstrellas.where((t) => puntaje >= t).length;

  final int puntaje;
  final bool nuevoRecord;
  final VoidCallback alComprarMovimientos;
  final VoidCallback alNuevaPartida;

  const PanelVictoria({
    super.key,
    required this.puntaje,
    required this.nuevoRecord,
    required this.alComprarMovimientos,
    required this.alNuevaPartida,
  });

  @override
  State<PanelVictoria> createState() => _PanelVictoriaState();
}

class _PanelVictoriaState extends State<PanelVictoria> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  late final List<_Confetti> _confetti = List.generate(90, (_) => _Confetti.random());

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  int get _stars => PanelVictoria.estrellasPara(widget.puntaje);

  String get _title => switch (_stars) {
        3 => '¡Maestro Pokémon!',
        2 => '¡Excelente!',
        1 => '¡Bien hecho!',
        _ => '¡Buen intento!',
      };

  /// Valor 0..1 de una porcion de la animacion de entrada.
  double _seg(double start, double end, [Curve curve = Curves.easeOut]) {
    final v = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _loop]),
      builder: (context, _) {
        final cardIn = _seg(0, 0.25, Curves.elasticOut);
        final shownScore = (widget.puntaje * _seg(0.2, 0.6)).round();

        return Stack(
          children: [
            // Fondo oscuro con brillo central
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      ColoresApp.amarillo.withAlpha((90 * _seg(0, 0.3)).toInt()),
                      Colors.black.withAlpha((150 * _seg(0, 0.2)).toInt()),
                    ],
                  ),
                ),
              ),
            ),

            // Tarjeta
            Center(
              child: Transform.scale(
                scale: 0.3 + 0.7 * cardIn,
                child: Opacity(
                  opacity: _seg(0, 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: ColoresApp.amarillo, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: ColoresApp.amarillo.withAlpha(160),
                              blurRadius: 30 + 10 * sin(_loop.value * 2 * pi),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pokébola con rayos girando
                            SizedBox(
                              width: 120,
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: _loop.value * 2 * pi,
                                    child: CustomPaint(
                                      size: const Size(140, 140),
                                      painter: _RaysPainter(),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, -6 * sin(_loop.value * 4 * pi).abs()),
                                    child: const ImagenPokebola(size: 70),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.5 + 0.5 * _seg(0.1, 0.35, Curves.elasticOut),
                              child: TextoTitulo(_title, fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            // Estrellas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  _Star(
                                    filled: i < _stars,
                                    appear: _seg(0.3 + i * 0.12, 0.5 + i * 0.12, Curves.elasticOut),
                                    big: i == 1,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$shownScore',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: ColoresApp.rojo,
                                height: 1,
                              ),
                            ),
                            const Text('puntos', style: TextStyle(fontWeight: FontWeight.w700)),
                            if (widget.nuevoRecord) ...[
                              const SizedBox(height: 8),
                              Transform.scale(
                                scale: (1 + 0.08 * sin(_loop.value * 8 * pi)) *
                                    _seg(0.6, 0.75, Curves.elasticOut),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [ColoresApp.rojo, ColoresApp.naranja]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('🏆 ¡NUEVO RÉCORD! 🏆',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1)),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: widget.alNuevaPartida,
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: const Text('Nueva partida'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.alComprarMovimientos,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('+5 movimientos (10 💎)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Confeti por delante (no bloquea los toques)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(_confetti, _loop.value, _seg(0, 0.15)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Star extends StatelessWidget {
  final bool filled;
  final double appear;
  final bool big;
  const _Star({required this.filled, required this.appear, required this.big});

  @override
  Widget build(BuildContext context) {
    final size = big ? 58.0 : 46.0;
    return Transform.translate(
      offset: Offset(0, big ? -8 : 0),
      child: Transform.scale(
        scale: appear,
        child: Icon(
          Icons.star_rounded,
          size: size,
          color: filled ? ColoresApp.amarillo : Colors.grey.withAlpha(90),
          shadows: filled
              ? const [
                  Shadow(color: ColoresApp.naranja, blurRadius: 12),
                  Shadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 2),
                ]
              : null,
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a1 = i * 2 * pi / rays;
      final a2 = a1 + pi / rays;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a1) * r, c.dy + sin(a1) * r)
        ..lineTo(c.dx + cos(a2) * r, c.dy + sin(a2) * r)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [ColoresApp.amarillo.withAlpha(200), ColoresApp.amarillo.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Confetti {
  final double x; // 0..1
  final double offset; // 0..1
  final double speed;
  final double size;
  final double spin;
  final double sway;
  final Color color;
  final bool circle;

  _Confetti(this.x, this.offset, this.speed, this.size, this.spin, this.sway, this.color, this.circle);

  static final _rng = Random();
  static const _colors = [
    ColoresApp.amarillo,
    ColoresApp.rojo,
    ColoresApp.azul,
    ColoresApp.verde,
    ColoresApp.rosa,
    ColoresApp.naranja,
    Colors.white,
  ];

  factory _Confetti.random() => _Confetti(
        _rng.nextDouble(),
        _rng.nextDouble(),
        0.6 + _rng.nextDouble() * 0.9,
        5 + _rng.nextDouble() * 7,
        (_rng.nextDouble() - 0.5) * 20,
        10 + _rng.nextDouble() * 25,
        _colors[_rng.nextInt(_colors.length)],
        _rng.nextDouble() < 0.3,
      );
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> pieces;
  final double t;
  final double opacity;
  _ConfettiPainter(this.pieces, this.t, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final prog = (p.offset + t * p.speed) % 1.0;
      final y = -20 + prog * (size.height + 40);
      final x = p.x * size.width + sin((prog * 6 + p.offset * 10)) * p.sway;
      final paint = Paint()..color = p.color.withAlpha((230 * opacity).toInt());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * p.spin);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // El ancho "oscila" para simular que el papelito gira en 3D
        final w = p.size * (0.3 + 0.7 * cos(prog * p.spin).abs());
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: p.size * 0.6), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
