import 'package:flutter/material.dart';

import 'package:candy_mon/general/styles/tema_app.dart';

/// Imagen de la Pokébola (assets/images/pokeball.png).
/// Si no existe, muestra un icono parecido de Material.
class ImagenPokebola extends StatelessWidget {
  final double size;
  const ImagenPokebola({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pokeball.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.catching_pokemon, size: size, color: ColoresApp.rojo),
    );
  }
}

/// Sprite de una pieza (assets/images/<nombre>.png) para usar en la interfaz.
class SpritePokemon extends StatelessWidget {
  final String nombre;
  final double size;
  const SpritePokemon({super.key, required this.nombre, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$nombre.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.none, // pixel art nitido
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}

/// Texto estilo "titulo de juego": relleno amarillo con borde azul.
class TextoTitulo extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;

  const TextoTitulo(
    this.text, {
    super.key,
    this.fontSize = 48,
    this.fill = ColoresApp.amarillo,
    this.stroke = ColoresApp.azulOscuro,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      height: 1.1,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: const [Shadow(color: Color(0x55000000), offset: Offset(0, 4), blurRadius: 6)],
          ),
        ),
        Text(text, textAlign: TextAlign.center, style: base.copyWith(color: fill)),
      ],
    );
  }
}
