import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:candy_mon/componentes/juego/presentacion/flame/pieza_componente.dart';
import 'package:candy_mon/componentes/usuario/datos/usuario_provider.dart';
import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/general/widgets/fondo_app.dart';
import 'package:candy_mon/general/widgets/encabezado.dart';
import 'package:candy_mon/general/widgets/poke_widgets.dart';
import 'package:candy_mon/componentes/juego/presentacion/pantalla_juego.dart';
import 'package:candy_mon/componentes/tienda/presentacion/pantalla_tienda.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  @override
  void initState() {
    super.initState();
    ServicioSonido.instancia.iniciarMusicaInicio(); // musica del menu
  }

  /// Abre la partida y, al volver, retoma la musica del menu.
  Future<void> _irAJugar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PantallaJuego()),
    );
    ServicioSonido.instancia.iniciarMusicaInicio();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>();
    return Scaffold(
      body: FondoApp(
        child: SafeArea(
          child: Column(
            children: [
              const Encabezado(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      const _PokebolaBalanceo(),
                      const SizedBox(height: 6),
                      const TextoTitulo('CandyMon', fontSize: 54),
                      const SizedBox(height: 4),
                      Text(
                        '¡Hola, entrenador ${usuario.usuario.nombre}! ¿Listo para combinar?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 18),
                      const _DesfilePokemon(),
                      const SizedBox(height: 22),
                      _BotonJugar(alTocar: _irAJugar),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BotonCuadrado(
                              texto: 'PokeShop',
                              icono: Icons.storefront_rounded,
                              color: ColoresApp.azul,
                              alTocar: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PantallaTienda()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _BotonCuadrado(
                              texto: 'Cómo jugar',
                              icono: Icons.help_rounded,
                              color: ColoresApp.amarillo,
                              colorTexto: ColoresApp.azulOscuro,
                              alTocar: () => _mostrarReglas(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pokébola que se balancea como cuando atrapas un Pokémon.
class _PokebolaBalanceo extends StatefulWidget {
  const _PokebolaBalanceo();

  @override
  State<_PokebolaBalanceo> createState() => _PokebolaBalanceoState();
}

class _PokebolaBalanceoState extends State<_PokebolaBalanceo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Se mueve en la primera mitad, quieta en la segunda
        final t = _c.value < 0.5 ? _c.value * 2 : 0.0;
        final angle = sin(t * pi * 3) * 0.35 * (1 - t);
        return Transform.rotate(angle: angle, alignment: Alignment.bottomCenter, child: child);
      },
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x66FFCB05), blurRadius: 30, spreadRadius: 6)],
        ),
        child: const ImagenPokebola(size: 84),
      ),
    );
  }
}

/// Los 6 Pokémon del juego saltando en fila.
class _DesfilePokemon extends StatefulWidget {
  const _DesfilePokemon();

  @override
  State<_DesfilePokemon> createState() => _DesfilePokemonState();
}

class _DesfilePokemonState extends State<_DesfilePokemon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const nombres = PiezaComponente.nombresPiezas;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < nombres.length; i++)
            Transform.translate(
              offset: Offset(0, -10 * max(0, sin((_c.value * 2 * pi) - i * 0.6))),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PiezaComponente.colores[i].withAlpha(70),
                ),
                child: SpritePokemon(nombre: nombres[i], size: 46),
              ),
            ),
        ],
      ),
    );
  }
}

/// Muestra las reglas en una ventana que sube desde abajo.
void _mostrarReglas(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // la ventana se ajusta al alto del contenido
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImagenPokebola(size: 28),
              SizedBox(width: 10),
              Text('¿Cómo se juega?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          SizedBox(height: 16),
          _Regla(emoji: '👆', texto: 'Deslizá o tocá dos Pokémon vecinos para cambiarlos de lugar.'),
          _Regla(emoji: '⚡', texto: 'Juntá 3 o más iguales en línea para lanzar un ataque.'),
          _Regla(emoji: '🔥', texto: 'Las cascadas son golpes críticos: ¡suman más puntos!'),
          _Regla(emoji: '⭐', texto: 'Llegá a 400, 1000 y 2000 puntos para ganar las 3 estrellas.'),
          _Regla(emoji: '🎯', texto: 'Tenés ${ConstantesJuego.movimientosIniciales} movimientos por partida.'),
          _Regla(emoji: '💎', texto: 'Comprá diamantes en la PokeShop para sumar movimientos.'),
        ],
      ),
    ),
  );
}

class _Regla extends StatelessWidget {
  final String emoji;
  final String texto;
  const _Regla({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

/// Boton principal: grande, rojo y "late" suavemente para invitar a tocarlo.
class _BotonJugar extends StatefulWidget {
  final VoidCallback alTocar;
  const _BotonJugar({required this.alTocar});

  @override
  State<_BotonJugar> createState() => _BotonJugarState();
}

class _BotonJugarState extends State<_BotonJugar> with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _latido, curve: Curves.easeInOut),
      ),
      child: GestureDetector(
        onTap: widget.alTocar,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: ColoresApp.rojo,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(color: ColoresApp.rojoOscuro, offset: Offset(0, 6)),
              BoxShadow(color: Color(0x55E3350D), blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImagenPokebola(size: 40),
              SizedBox(width: 14),
              Text(
                '¡JUGAR!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton secundario cuadrado con icono grande y texto abajo.
class _BotonCuadrado extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final Color colorTexto;
  final VoidCallback alTocar;

  const _BotonCuadrado({
    required this.texto,
    required this.icono,
    required this.color,
    required this.alTocar,
    this.colorTexto = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(color, Colors.black, 0.3)!,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icono, size: 40, color: colorTexto),
            const SizedBox(height: 6),
            Text(
              texto,
              style: TextStyle(color: colorTexto, fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
