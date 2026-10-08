import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:candy_mon/general/styles/tema_provider.dart';
import 'package:candy_mon/componentes/usuario/datos/usuario_provider.dart';
import 'package:candy_mon/componentes/inicio/presentacion/pantalla_inicio.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/general/styles/tema_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cargamos los datos guardados en el dispositivo (sin internet).
  final usuarioProvider = UsuarioProvider();
  final temaProvider = TemaProvider();
  await Future.wait([
    usuarioProvider.cargar(),
    temaProvider.cargar(),
    ServicioSonido.instancia.iniciar(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: usuarioProvider),
        ChangeNotifierProvider.value(value: temaProvider),
        ChangeNotifierProvider.value(value: ServicioSonido.instancia),
      ],
      child: const CandyMonApp(),
    ),
  );
}

class CandyMonApp extends StatelessWidget {
  const CandyMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final modoTema = context.watch<TemaProvider>().modoTema;
    return MaterialApp(
      title: 'CandyMon',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.oscuro,
      themeMode: modoTema,
      home: const PantallaInicio(),
    );
  }
}
