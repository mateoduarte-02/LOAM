import 'package:flutter/material.dart';

import 'package:candy_mon/componentes/juego/presentacion/flame/juego_match3.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/general/styles/tema_app.dart';

/// BOTONERA externa al juego: Iniciar, Pausa/Reanudar, Reiniciar, Nueva.
class Botonera extends StatelessWidget {
  final EstadoJuego estado;
  final VoidCallback alIniciar;
  final VoidCallback alPausar;
  final VoidCallback alReiniciar;
  final VoidCallback alNuevaPartida;

  const Botonera({
    super.key,
    required this.estado,
    required this.alIniciar,
    required this.alPausar,
    required this.alReiniciar,
    required this.alNuevaPartida,
  });

  @override
  Widget build(BuildContext context) {
    final estaPausado = estado == EstadoJuego.pausado;
    final puedePausar = estado == EstadoJuego.jugando || estaPausado;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Row(
        children: [
          _BotonControl(
            icon: Icons.play_arrow_rounded,
            label: 'Iniciar',
            color: ColoresApp.verde,
            onPressed: estado == EstadoJuego.listo ? alIniciar : null,
          ),
          _BotonControl(
            icon: estaPausado ? Icons.play_circle_fill_rounded : Icons.pause_rounded,
            label: estaPausado ? 'Seguir' : 'Pausa',
            color: ColoresApp.naranja,
            onPressed: puedePausar ? alPausar : null,
          ),
          _BotonControl(
            icon: Icons.replay_rounded,
            label: 'Reiniciar',
            color: ColoresApp.azul,
            onPressed: alReiniciar,
          ),
          _BotonControl(
            icon: Icons.auto_awesome_rounded,
            label: 'Nueva',
            color: ColoresApp.rojo,
            onPressed: alNuevaPartida,
          ),
        ],
      ),
    );
  }
}

class _BotonControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _BotonControl({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(20),
            elevation: enabled ? 4 : 0,
            shadowColor: color,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed == null
                  ? null
                  : () {
                      ServicioSonido.instancia.reproducir('click', volume: 0.5);
                      onPressed!();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
