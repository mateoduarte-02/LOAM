import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:candy_mon/componentes/juego/presentacion/flame/juego_match3.dart';
import 'package:candy_mon/componentes/usuario/datos/usuario_provider.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/componentes/publicidad/presentacion/ventana_publicidad.dart';
import 'package:candy_mon/general/widgets/fondo_app.dart';
import 'package:candy_mon/general/widgets/encabezado.dart';
import 'package:candy_mon/componentes/juego/presentacion/widgets/botonera.dart';
import 'package:candy_mon/general/widgets/poke_widgets.dart';
import 'package:candy_mon/componentes/juego/presentacion/widgets/barra_estrellas.dart';
import 'package:candy_mon/componentes/juego/presentacion/widgets/panel_victoria.dart';
import 'package:candy_mon/componentes/tienda/presentacion/pantalla_tienda.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> with WidgetsBindingObserver {
  late final JuegoMatch3 _juego;
  int _recordAlEmpezar = 0; // record antes de empezar la partida
  bool _esNuevoRecord = false;
  int _idVictoria = 0; // para reiniciar la animacion de festejo

  UsuarioProvider get _usuario => context.read<UsuarioProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ServicioSonido.instancia.detenerMusica(); // corta la musica del menu
    _juego = JuegoMatch3();
    _juego.puntaje.addListener(_alCambiarPuntaje);
    _juego.estado.addListener(_alCambiarEstado);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordAlEmpezar = _usuario.record;
      _usuario.actualizarPuntaje(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _juego.puntaje.removeListener(_alCambiarPuntaje);
    _juego.estado.removeListener(_alCambiarEstado);
    super.dispose();
  }

  // Si la app pasa a segundo plano, pausamos el juego.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _juego.pausar();
  }

  void _alCambiarPuntaje() {
    if (_juego.puntaje.value == 0) _recordAlEmpezar = _usuario.record;
    _usuario.actualizarPuntaje(_juego.puntaje.value);
  }

  void _alCambiarEstado() {
    // Musica: suena solo mientras se juega.
    if (_juego.estado.value == EstadoJuego.jugando) {
      ServicioSonido.instancia.iniciarMusica();
    } else {
      ServicioSonido.instancia.pausarMusica();
    }

    if (_juego.estado.value == EstadoJuego.terminado) {
      _esNuevoRecord = _juego.puntaje.value > _recordAlEmpezar && _juego.puntaje.value > 0;
      _idVictoria++;
      // Festejo si ganaste al menos 1 estrella o hiciste record
      final festejar = _esNuevoRecord || PanelVictoria.estrellasPara(_juego.puntaje.value) > 0;
      ServicioSonido.instancia.reproducir(festejar ? 'win' : 'gameover');
      setState(() {});
    }
  }

  // ---------- Botonera ----------

  /// Las cuentas BASIC ven un anuncio antes de reiniciar / nueva partida.
  Future<void> _conPublicidad(VoidCallback accion) async {
    if (!_usuario.esPro) {
      _juego.pausar();
      await mostrarPublicidad(context);
      if (!mounted) return;
    }
    accion();
  }

  void _alternarPausa() {
    _juego.estado.value == EstadoJuego.pausado ? _juego.reanudar() : _juego.pausar();
  }

  // ---------- Boosters ----------

  void _sinDiamantes() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('No te alcanzan los diamantes 💎'),
        action: SnackBarAction(
          label: 'TIENDA',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PantallaTienda())),
        ),
      ));
  }

  /// Martillo y Mezclar estan SIMULADOS: cobran los diamantes y muestran
  /// el aviso, pero no modifican el tablero.
  void _usarBoosterSimulado(int costo, String texto) {
    if (!_juego.puedeUsarBooster) return;
    if (!_usuario.gastarDiamantes(costo)) return _sinDiamantes();
    ServicioSonido.instancia.reproducir('coin', volume: 0.6);
    _juego.mostrarMensaje(texto);
  }

  void _usarMartillo() => _usarBoosterSimulado(ConstantesJuego.costoMartillo, '¡Martillo activado!');

  void _usarMezclar() => _usarBoosterSimulado(ConstantesJuego.costoMezclar, '¡Tablero mezclado!');

  /// +5 movimientos: este SI funciona, solo suma movimientos.
  void _comprarMovimientos() {
    if (!_usuario.gastarDiamantes(ConstantesJuego.costoMovimientosExtra)) return _sinDiamantes();
    ServicioSonido.instancia.reproducir('coin', volume: 0.6);
    _juego.sumarMovimientos(5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoApp(
        child: SafeArea(
          child: Column(
            children: [
              const Encabezado(mostrarVolver: true),
              _MovimientosYBoosters(
                juego: _juego,
                alMartillo: _usarMartillo,
                alMezclar: _usarMezclar,
                alComprarMovimientos: _comprarMovimientos,
              ),
              BarraEstrellas(puntaje: _juego.puntaje),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    children: [
                      Positioned.fill(child: GameWidget(game: _juego)),
                      Positioned.fill(child: _capaMensaje()),
                      Positioned.fill(child: _capaEstado()),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<EstadoJuego>(
                valueListenable: _juego.estado,
                builder: (_, estado, __) => Botonera(
                  estado: estado,
                  alIniciar: _juego.iniciar,
                  alPausar: _alternarPausa,
                  alReiniciar: () => _conPublicidad(_juego.reiniciar),
                  alNuevaPartida: () => _conPublicidad(_juego.nuevaPartida),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capaMensaje() {
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: _juego.mensaje,
        builder: (_, text, __) => Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: child,
            ),
            child: text == null
                ? const SizedBox.shrink()
                : Transform.rotate(
                    key: ValueKey(text + DateTime.now().millisecondsSinceEpoch.toString()),
                    angle: -0.08,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: RadialGradient(
                          colors: [ColoresApp.amarillo.withAlpha(120), ColoresApp.amarillo.withAlpha(0)],
                        ),
                      ),
                      child: TextoTitulo(text, fontSize: 40),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _capaEstado() {
    return ValueListenableBuilder<EstadoJuego>(
      valueListenable: _juego.estado,
      builder: (_, estado, __) {
        switch (estado) {
          case EstadoJuego.jugando:
            return const SizedBox.shrink();
          case EstadoJuego.listo:
            return _TarjetaCapa(
              onTap: _juego.iniciar,
              children: const [
                ImagenPokebola(size: 64),
                SizedBox(height: 8),
                Text('¡Tocá INICIAR, entrenador!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Tenés ${ConstantesJuego.movimientosIniciales} movimientos',
                    textAlign: TextAlign.center),
              ],
            );
          case EstadoJuego.pausado:
            return _TarjetaCapa(
              onTap: _juego.reanudar,
              children: const [
                Icon(Icons.pause_circle_filled_rounded, size: 64, color: ColoresApp.naranja),
                Text('Pausa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('Tocá para seguir jugando'),
              ],
            );
          case EstadoJuego.terminado:
            return PanelVictoria(
              key: ValueKey('victory$_idVictoria'),
              puntaje: _juego.puntaje.value,
              nuevoRecord: _esNuevoRecord,
              alComprarMovimientos: _comprarMovimientos,
              alNuevaPartida: () => _conPublicidad(_juego.nuevaPartida),
            );
        }
      },
    );
  }
}

class _TarjetaCapa extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onTap;
  const _TarjetaCapa({required this.children, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Fila con movimientos restantes y boosters pagados con diamantes.
class _MovimientosYBoosters extends StatelessWidget {
  final JuegoMatch3 juego;
  final VoidCallback alMartillo;
  final VoidCallback alMezclar;
  final VoidCallback alComprarMovimientos;

  const _MovimientosYBoosters({
    required this.juego,
    required this.alMartillo,
    required this.alMezclar,
    required this.alComprarMovimientos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: juego.movimientos,
            builder: (_, movimientos, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: movimientos <= 3
                      ? const [ColoresApp.rojo, ColoresApp.naranja]
                      : const [ColoresApp.azul, ColoresApp.azulOscuro],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text('Movs',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('$movimientos',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BotonBooster(
              emoji: '🔨',
              label: 'Martillo',
              costo: ConstantesJuego.costoMartillo,
              onTap: alMartillo,
            ),
          ),
          Expanded(
            child: _BotonBooster(
              emoji: '🔀',
              label: 'Mezclar',
              costo: ConstantesJuego.costoMezclar,
              onTap: alMezclar,
            ),
          ),
          Expanded(
            child: _BotonBooster(
              emoji: '➕',
              label: '+5 movs',
              costo: ConstantesJuego.costoMovimientosExtra,
              onTap: alComprarMovimientos,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonBooster extends StatelessWidget {
  final String emoji;
  final String label;
  final int costo;
  final VoidCallback onTap;

  const _BotonBooster({
    required this.emoji,
    required this.label,
    required this.costo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: scheme.surface.withAlpha(215),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: null)),
                Text('$costo 💎',
                    style: const TextStyle(
                        fontSize: 11, color: ColoresApp.diamante, fontWeight: FontWeight.w800)),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
