import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/general/constantes/constantes_juego.dart';

/// PUBLICIDAD simulada: ventana modal con cuenta regresiva.
/// Se muestra al reiniciar o empezar una nueva partida (solo cuentas BASIC).
///
/// Muestra una captura de la pagina publicitada guardada en
/// assets/images/publicidad.png (funciona OFFLINE, es solo una imagen).
/// Si la imagen no existe, muestra un anuncio de ejemplo.
class ConfigPublicidad {
  static const rutaImagen = 'assets/images/publicidad.png';
  static const titulo = 'Rabbit3D · Impresión 3D';
  static const subtitulo = 'Llaveros y productos impresos en 3D por cantidad para cumpleaños, escuelas y marcas.';
  static const url = 'lamadriguera.site/Rabbit3d';
  static const enlace = 'https://lamadriguera.site/Rabbit3d/';
}

Future<void> mostrarPublicidad(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (_) => const _VentanaPublicidad(),
  );
}

class _VentanaPublicidad extends StatefulWidget {
  const _VentanaPublicidad();

  @override
  State<_VentanaPublicidad> createState() => _VentanaPublicidadState();
}

class _VentanaPublicidadState extends State<_VentanaPublicidad> {
  int _restantes = ConstantesJuego.segundosPublicidad;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restantes <= 1) t.cancel();
      setState(() => _restantes--);
    });
  }

  /// Abre la pagina del anuncio en el navegador.
  /// El juego funciona sin internet: si no hay conexion, solo avisa.
  Future<void> _abrirSitio() async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      // Pregunta rapida para saber si hay internet
      final respuesta = await InternetAddress.lookup('lamadriguera.site')
          .timeout(const Duration(seconds: 3));
      if (respuesta.isEmpty) throw const SocketException('sin conexion');
      await launchUrl(Uri.parse(ConfigPublicidad.enlace), mode: LaunchMode.externalApplication);
    } catch (_) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('Sin conexión a internet: no se puede abrir el sitio')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puedeCerrar = _restantes <= 0;
    final maxImageHeight = MediaQuery.of(context).size.height * 0.5;

    return PopScope(
      canPop: puedeCerrar,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Captura de la pagina (o anuncio de ejemplo si falta)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxImageHeight, minHeight: 180),
                  child: GestureDetector(
                    onTap: _abrirSitio, // tocar el anuncio abre la pagina
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: Image.asset(
                        ConfigPublicidad.rutaImagen,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const _AnuncioDeEjemplo(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColoresApp.amarillo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Anuncio',
                        style: TextStyle(
                            color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: puedeCerrar
                      ? IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Text('$_restantes',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: (ConstantesJuego.segundosPublicidad - _restantes) / ConstantesJuego.segundosPublicidad,
              minHeight: 5,
              color: ColoresApp.rojo,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  const Text(ConfigPublicidad.titulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 2),
                  const Text(ConfigPublicidad.subtitulo, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _abrirSitio,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(ConfigPublicidad.url,
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    puedeCerrar ? '¡Ya podés cerrar el anuncio!' : 'Tu partida empieza en $_restantes...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('👑 Las cuentas CandyMon PRO no ven anuncios',
                      style: TextStyle(fontSize: 12)),
                  if (puedeCerrar) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('¡A jugar!'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anuncio de ejemplo si no existe assets/images/publicidad.png
class _AnuncioDeEjemplo extends StatelessWidget {
  const _AnuncioDeEjemplo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.azul, ColoresApp.violeta],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐰', style: TextStyle(fontSize: 56)),
            SizedBox(height: 6),
            Text('RABBIT 3D',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 2)),
            Text('lamadriguera.site',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
