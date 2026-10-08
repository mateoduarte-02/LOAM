# CandyMon — TP2 Laboratorio Orientado a Aplicaciones Móviles

Juego match-3 (estilo Candy Crush) con temática Pokémon, hecho con **Flutter + Flame** (Plan A).
Funciona 100 % offline (modo avión).

## Cómo correrlo

```
flutter pub get
dart run flutter_launcher_icons   # genera el ícono (una sola vez)
flutter run                       # en emulador o celular
flutter build apk --release       # APK en build/app/outputs/flutter-apk/
flutter test                      # tests de la lógica del tablero
```

## Estructura

Organizada como en la práctica de la materia: lo compartido en `general/`
y cada funcionalidad en `componentes/<módulo>/` separada en
`datos/` (guardado), `dominio/` (modelos y lógica) y `presentacion/` (pantallas y widgets).

```
lib/
├── main.dart                         punto de partida: providers y MaterialApp (CandyMonApp)
├── general/
│   ├── constantes/
│   │   └── constantes_juego.dart     movimientos, metas de estrellas, precios, segundos de publicidad
│   ├── styles/
│   │   ├── tema_app.dart             ColoresApp y TemaApp (claro / oscuro)
│   │   └── tema_provider.dart        TemaProvider: cambia y recuerda el modo
│   ├── utilidades/
│   │   └── sonido.dart               ServicioSonido: música y efectos
│   └── widgets/
│       ├── encabezado.dart           Encabezado (usuario, score, BASIC/PRO, diamantes)
│       ├── fondo_app.dart            FondoApp (degradado + Pokébolas)
│       └── poke_widgets.dart         ImagenPokebola, SpritePokemon, TextoTitulo
└── componentes/
    ├── usuario/
    │   ├── datos/usuario_provider.dart   UsuarioProvider: diamantes, PRO, récord (shared_preferences)
    │   └── dominio/usuario.dart          Usuario (simulado, ya logueado)
    ├── inicio/
    │   └── presentacion/pantalla_inicio.dart
    ├── juego/
    │   ├── dominio/logica_tablero.dart   LogicaTablero: lógica pura del match-3 (testeada)
    │   └── presentacion/
    │       ├── pantalla_juego.dart       PantallaJuego (StatefulWidget)
    │       ├── flame/
    │       │   ├── juego_match3.dart     JuegoMatch3 (FlameGame): estados, turnos, cascadas
    │       │   ├── tablero_componente.dart  dibujo del tablero, toques y deslizamientos
    │       │   ├── pieza_componente.dart    cada Pokémon y sus animaciones
    │       │   └── efectos.dart             chispas, anillos de luz, puntos, brillos
    │       └── widgets/
    │           ├── botonera.dart         Botonera: Iniciar, Pausa, Reiniciar, Nueva
    │           ├── barra_estrellas.dart  progreso hacia las 3 estrellas
    │           └── panel_victoria.dart   fin de partida con estrellas y confeti
    ├── tienda/
    │   └── presentacion/pantalla_tienda.dart     PokeShop: compra simulada
    └── publicidad/
        └── presentacion/ventana_publicidad.dart  anuncio con cuenta regresiva
test/
└── logica_tablero_test.dart
assets/
├── images/   sprites de las piezas, pokeball.png, publicidad.png
├── audio/    musica_fondo.mp3 y efectos .wav (generados por código)
└── icon/     ícono de la app
```

## Requisitos de la consigna

| Requisito | Dónde |
|---|---|
| Flutter + motor de juego | Flame (`JuegoMatch3`) en `componentes/juego/presentacion/flame/` |
| Offline | Sin internet; datos en `shared_preferences`, imágenes y audio como assets |
| Login simulado | `UsuarioProvider.usuario` fijo |
| Header (usuario, score, cuenta, diamantes) | `general/widgets/encabezado.dart`, en todas las pantallas |
| Diamantes usados en el juego | Boosters: +5 movimientos (funcional), Martillo y Mezclar (simulados) |
| Monetización simulada | `componentes/tienda/`: compra de diamantes y cuenta PRO |
| Botonera fuera del juego | `Botonera` llama a `iniciar()`, `pausar()`, `reanudar()`, `reiniciar()`, `nuevaPartida()` |
| Publicidad | `componentes/publicidad/`: modal de 5 s al reiniciar / nueva partida (PRO no la ve) |
| Modo claro / oscuro | Botón en el encabezado (`TemaProvider`) |
| Atractivo para chicos | Colores saturados, animaciones, efectos de luz, sonidos, confeti |

## Cómo funciona (Widget → Comando → Estado)

Igual que el esquema de la práctica: el **widget** invoca un **comando**, el comando
modifica el **estado** y la pantalla se redibuja.

- Botón **Pausa** (widget) → `juego.pausar()` (comando) → `estado = pausado` (estado) → la pantalla muestra "Pausa".
- Tocar dos piezas (widget) → `manejarToque()` → cambian `puntaje` y `movimientos` → el encabezado se actualiza.
- Comprar diamantes (widget) → `sumarDiamantes()` → `UsuarioProvider` avisa con `notifyListeners()` → el encabezado se redibuja.

## Lógica del juego (para la defensa)

1. **Tablero:** matriz 8x8 de enteros (`LogicaTablero.grilla`); cada número es un Pokémon y `-1` es vacío.
2. **Generación:** se llena evitando 3 iguales seguidos (`_formariaCombinacion` mira 2 a la izquierda y 2 arriba) y se repite si no hay movimientos posibles.
3. **Intercambio:** si no forma combinación, las piezas vuelven y no se gasta movimiento.
4. **Detección** (`buscarCombinaciones`): recorre filas y columnas buscando rachas de 3 o más.
5. **Gravedad** (`aplicarGravedad`): por columna, de abajo hacia arriba, cada pieza baja al primer hueco; arriba se crean piezas nuevas.
6. **Cascadas:** se repite mientras haya combinaciones. Puntos = piezas × 10 × número de combo.
7. **Animación:** cada pieza tiene un `destino` y se mueve hacia él en `update(dt)` (el bucle del juego, como el `Timer.periodic` de la práctica pero manejado por Flame).
8. **Pausa:** `pauseEngine()` detiene el bucle, así que se congelan animaciones y esperas; la música también se pausa.
9. **Flame ↔ Flutter:** el juego expone `ValueNotifier`s (`puntaje`, `movimientos`, `estado`, `mensaje`) y la UI los escucha con `ValueListenableBuilder`.
10. **Estrellas:** 400 / 1000 / 2000 puntos (`ConstantesJuego.metasEstrellas`).
