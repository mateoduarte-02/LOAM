import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:shared_preferences/shared_preferences.dart';

/// MUSICA Y EFECTOS DE SONIDO (funciona offline).
///
/// Los archivos van en assets/audio/ y son todos OPCIONALES:
/// si alguno falta, simplemente no suena (el juego no se rompe).
/// Formatos aceptados: .mp3, .wav, .ogg, .m4a
///
///   musica_inicio -> musica del menu principal
///   musica_fondo  -> musica de la partida (tambien acepta "music" o "musica")
///   swap          -> al intercambiar dos piezas
///   pop           -> al explotar una combinacion
///   combo         -> en las cascadas (combo x2, x3...)
///   fail          -> movimiento invalido
///   gameover      -> fin de la partida (sin estrellas)
///   win           -> festejo de fin de partida (estrellas o record)
///   coin          -> compras y boosters
///   click         -> botones
///
/// Como funciona:
///   - Efectos: un "pool" de reproductores por sonido, reutilizados
///     (crear un reproductor nuevo en cada sonido hacia que fallen).
///   - Musica: un solo reproductor en bucle que cambia de pista
///     (inicio o partida). Se guarda que pista "deberia" sonar, asi una
///     pausa nunca queda pisada por un play que tardo en cargar.
///   - Si la app pasa a segundo plano, la musica se pausa sola.
///   - Ningun sonido le "roba" el audio a otro (antes los efectos
///     cortaban la musica).
class ServicioSonido extends ChangeNotifier with WidgetsBindingObserver {
  ServicioSonido._();
  static final ServicioSonido instancia = ServicioSonido._();

  static const _kMusic = 'musicaActiva';
  static const _kSfx = 'efectosActivos';
  static const musicNames = ['musica_fondo', 'music', 'musica'];
  static const effects = ['swap', 'pop', 'combo', 'fail', 'gameover', 'win', 'coin', 'click'];
  static const _extensions = ['.mp3', '.wav', '.ogg', '.m4a'];

  SharedPreferences? _prefs;
  final Set<String> _available = {};
  final Map<String, AudioPool> _pools = {};

  AudioPlayer? _music;
  String? _pistaCargada; // archivo cargado en el reproductor
  String? _pistaQuerida; // archivo que deberia sonar (null = silencio)

  bool _musicOn = true;
  bool _sfxOn = true;

  bool get musicaActiva => _musicOn;
  bool get efectosActivos => _sfxOn;

  /// Busca un archivo por nombre (sin importar extension ni mayusculas).
  String? _find(String baseName) {
    for (final file in _available) {
      final lower = file.toLowerCase();
      for (final ext in _extensions) {
        if (lower == '${baseName.toLowerCase()}$ext') return file;
      }
    }
    return null;
  }

  String? get _musicFile {
    for (final n in musicNames) {
      final f = _find(n);
      if (f != null) return f;
    }
    return null;
  }

  Future<void> iniciar() async {
    _prefs = await SharedPreferences.getInstance();
    _musicOn = _prefs!.getBool(_kMusic) ?? true;
    _sfxOn = _prefs!.getBool(_kSfx) ?? true;
    WidgetsBinding.instance.addObserver(this); // para saber si la app se minimiza

    try {
      // Los efectos se mezclan con la musica en vez de cortarla.
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.music,
        ),
      ));

      // Que archivos de audio vinieron dentro de la app.
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final a in manifest.listAssets()) {
        if (a.startsWith('assets/audio/')) {
          _available.add(a.substring('assets/audio/'.length));
        }
      }
      debugPrint('🔊 Audios encontrados: ${_available.isEmpty ? "NINGUNO" : _available.join(", ")}');
      debugPrint('🎵 Musica de partida: ${_musicFile ?? "NO ENCONTRADA"}');
      debugPrint('🎵 Musica de inicio: ${_find('musica_inicio') ?? "NO ENCONTRADA"}');

      // Un pool por efecto (hasta 3 sonando a la vez del mismo efecto).
      for (final name in effects) {
        final file = _find(name);
        if (file == null) continue;
        try {
          _pools[name] = await FlameAudio.createPool(file, minPlayers: 1, maxPlayers: 3);
        } catch (e) {
          debugPrint('🔇 No se pudo preparar $file: $e');
        }
      }
    } catch (e) {
      debugPrint('🔇 No se pudo iniciar el audio: $e');
    }
  }

  // ---------------- Efectos ----------------

  /// Efecto de sonido: play('pop'), play('coin'), etc.
  void reproducir(String name, {double volume = 0.8}) {
    if (!_sfxOn) return;
    final pool = _pools[name];
    if (pool == null) return;
    pool.start(volume: volume).catchError((Object e) {
      debugPrint('🔇 Error reproduciendo $name: $e');
      return () async {};
    });
  }

  // ---------------- Musica ----------------

  /// Musica del menu principal (assets/audio/musica_inicio.*).
  Future<void> iniciarMusicaInicio() => _tocar(_find('musica_inicio'));

  /// Musica de la partida (assets/audio/musica_fondo.*).
  Future<void> iniciarMusica() => _tocar(_musicFile);

  /// Carga la pista (si es otra) y la reproduce en bucle.
  Future<void> _tocar(String? archivo) async {
    _pistaQuerida = archivo;
    if (!_musicOn || archivo == null) return;
    try {
      final player = _music ??= AudioPlayer();
      if (_pistaCargada != archivo) {
        await player.stop();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0.35);
        await player.setSource(AssetSource('audio/$archivo'));
        _pistaCargada = archivo;
      }
      // Mientras cargaba, quizas se pidio otra cosa: chequeamos de nuevo.
      if (_pistaQuerida != archivo || !_musicOn) return;
      await player.resume();
    } catch (e) {
      debugPrint('🔇 Error con la musica: $e');
    }
  }

  /// Pausa la musica (queda en el mismo lugar para seguir despues).
  Future<void> pausarMusica() async {
    _pistaQuerida = null;
    try {
      await _music?.pause();
    } catch (_) {}
  }

  /// Detiene la musica y la vuelve al principio.
  Future<void> detenerMusica() async {
    _pistaQuerida = null;
    try {
      await _music?.stop();
      _pistaCargada = null; // stop libera la fuente: se recarga despues
    } catch (_) {}
  }

  /// Si la app se minimiza, pausa la musica; al volver, la retoma.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pistaQuerida != null && _musicOn) _music?.resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _music?.pause();
    }
  }

  // ---------------- Interruptores ----------------

  void alternarMusica() {
    _musicOn = !_musicOn;
    _prefs?.setBool(_kMusic, _musicOn);
    if (_musicOn) {
      if (_pistaQuerida != null) _tocar(_pistaQuerida);
    } else {
      _music?.pause(); // _pistaQuerida se guarda para retomar despues
    }
    notifyListeners();
  }

  void alternarEfectos() {
    _sfxOn = !_sfxOn;
    _prefs?.setBool(_kSfx, _sfxOn);
    notifyListeners();
  }
}
