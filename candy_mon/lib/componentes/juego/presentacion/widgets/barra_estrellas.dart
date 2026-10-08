import 'package:flutter/material.dart';

import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/componentes/juego/presentacion/widgets/panel_victoria.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';

/// Barra de progreso de estrellas (como en Candy Crush):
/// muestra cuanto falta para cada estrella y para "Maestro Pokémon".
class BarraEstrellas extends StatelessWidget {
  final ValueNotifier<int> puntaje;
  const BarraEstrellas({super.key, required this.puntaje});

  static const _titulos = ['¡Bien hecho!', '¡Excelente!', '¡Maestro Pokémon!'];

  @override
  Widget build(BuildContext context) {
    const metas = ConstantesJuego.metasEstrellas;
    final max = metas.last;
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: puntaje,
      builder: (context, value, _) {
        final estrellas = PanelVictoria.estrellasPara(value);
        final String texto;
        if (estrellas >= metas.length) {
          texto = '⭐⭐⭐ ¡Sos Maestro Pokémon!';
        } else {
          final faltan = metas[estrellas] - value;
          texto = 'Faltan $faltan pts para ${_titulos[estrellas]}';
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: estrellas >= 3 ? ColoresApp.naranja : null,
                  )),
              const SizedBox(height: 4),
              SizedBox(
                height: 26,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final width = c.maxWidth;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: (value / max).clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) => Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Fondo de la barra
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: scheme.surface.withAlpha(200),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ColoresApp.azulOscuro.withAlpha(80)),
                            ),
                          ),
                          // Relleno
                          Container(
                            height: 12,
                            width: width * progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ColoresApp.amarillo, ColoresApp.naranja, ColoresApp.rojo],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: ColoresApp.amarillo.withAlpha(150), blurRadius: 8),
                              ],
                            ),
                          ),
                          // Estrellas en cada meta
                          for (var i = 0; i < metas.length; i++)
                            Positioned(
                              left: (width * metas[i] / max) - 13,
                              child: _Marcador(
                                alcanzada: value >= metas[i],
                                big: i == metas.length - 1,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Marcador extends StatelessWidget {
  final bool alcanzada;
  final bool big;
  const _Marcador({required this.alcanzada, required this.big});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: alcanzada ? 1.15 : 0.9,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: Icon(
        Icons.star_rounded,
        size: big ? 28 : 24,
        color: alcanzada ? ColoresApp.amarillo : Colors.grey.shade400,
        shadows: const [Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
    );
  }
}
