/// Usuario simulado: la consigna dice que la app "ya entra logueada",
/// asi que no hay login real.
class Usuario {
  final String nombre;
  final String email;

  const Usuario({required this.nombre, required this.email});

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
}
