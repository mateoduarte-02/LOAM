import 'package:flutter/material.dart';

import 'package:candy_mon/general/styles/tema_app.dart';

/// Fondo de todas las pantallas: una imagen (assets/images/fondo.png).
/// En modo oscuro se oscurece la misma imagen.
/// Si la imagen no existe, se ve solo un degradado de colores.
class FondoApp extends StatelessWidget {
  final Widget child;
  const FondoApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // Degradado de respaldo (se ve si no esta la imagen)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: oscuro ? ColoresApp.fondoOscuro : ColoresApp.fondoClaro,
        ),
        image: DecorationImage(
          image: const AssetImage('assets/images/fondo.png'),
          fit: BoxFit.cover, // la imagen cubre toda la pantalla
          colorFilter: oscuro
              ? const ColorFilter.mode(Colors.black54, BlendMode.darken)
              : null,
          onError: (_, __) {}, // si no esta la imagen, no pasa nada
        ),
      ),
      child: child,
    );
  }
}
