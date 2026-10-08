import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:candy_mon/general/styles/tema_provider.dart';
import 'package:candy_mon/componentes/usuario/datos/usuario_provider.dart';
import 'package:candy_mon/componentes/tienda/presentacion/pantalla_tienda.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/general/widgets/poke_widgets.dart';

/// HEADER obligatorio: nombre de usuario, puntaje, tipo de cuenta (BASIC/PRO)
/// y diamantes. Estilo "Pokédex": rojo arriba, franja negra, panel claro abajo.
class Encabezado extends StatelessWidget {
  final bool mostrarVolver;
  final bool abrirTiendaConDiamantes;

  const Encabezado({
    super.key,
    this.mostrarVolver = false,
    this.abrirTiendaConDiamantes = true,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>();
    final tema = context.watch<TemaProvider>();
    final sonido = context.watch<ServicioSonido>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ---- Parte roja ----
          Container(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColoresApp.rojo, ColoresApp.rojoOscuro],
              ),
            ),
            child: Row(
              children: [
                if (mostrarVolver)
                  IconButton(
                    tooltip: 'Volver',
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                else
                  const SizedBox(width: 6),
                // Avatar: inicial del entrenador con mini pokébola
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: ColoresApp.amarillo, width: 3),
                      ),
                      child: Text(
                        usuario.usuario.inicial,
                        style: const TextStyle(
                            color: ColoresApp.rojo, fontWeight: FontWeight.w900, fontSize: 19),
                      ),
                    ),
                    const Positioned(right: -4, bottom: -4, child: ImagenPokebola(size: 18)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrenador ${usuario.usuario.nombre}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      _AccountBadge(esPro: usuario.esPro),
                    ],
                  ),
                ),
                _HeaderIcon(
                  tooltip: sonido.musicaActiva ? 'Apagar música' : 'Prender música',
                  icon: sonido.musicaActiva ? Icons.music_note_rounded : Icons.music_off_rounded,
                  onPressed: sonido.alternarMusica,
                ),
                _HeaderIcon(
                  tooltip: sonido.efectosActivos ? 'Silenciar efectos' : 'Activar efectos',
                  icon: sonido.efectosActivos ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  onPressed: sonido.alternarEfectos,
                ),
                _HeaderIcon(
                  tooltip: tema.esOscuro ? 'Modo claro' : 'Modo oscuro',
                  icon: tema.esOscuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  onPressed: tema.alternar,
                ),
              ],
            ),
          ),
          // ---- Franja negra con "botoncito" como la Pokédex ----
          Container(
            height: 6,
            color: const Color(0xFF222222),
          ),
          // ---- Panel de estadisticas ----
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: '⭐',
                    label: 'Score',
                    value: '${usuario.puntaje}',
                    color: ColoresApp.naranja,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatChip(
                    icon: '🏆',
                    label: 'Récord',
                    value: '${usuario.record}',
                    color: ColoresApp.azul,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatChip(
                    icon: '💎',
                    label: 'Diamantes',
                    value: '${usuario.diamantes}',
                    color: ColoresApp.diamante,
                    trailing: abrirTiendaConDiamantes ? Icons.add_circle_rounded : null,
                    onTap: abrirTiendaConDiamantes
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PantallaTienda()),
                            )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  const _HeaderIcon({required this.tooltip, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: Colors.white,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final bool esPro;
  const _AccountBadge({required this.esPro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: esPro ? ColoresApp.amarillo : Colors.white24,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: esPro ? ColoresApp.azulOscuro : Colors.white54, width: 1.5),
      ),
      child: Text(
        esPro ? '👑 PRO' : 'BASIC',
        style: TextStyle(
          color: esPro ? ColoresApp.azulOscuro : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(40),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) Icon(trailing, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
