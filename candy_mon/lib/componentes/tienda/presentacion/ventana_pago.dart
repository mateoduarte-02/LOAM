import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:candy_mon/general/styles/tema_app.dart';

/// PAGO SIMULADO (la consigna pide simular la monetizacion).
/// No se cobra nada ni se usa internet: todo pasa dentro de la app.
///
/// Pasos:
///   1. Elegir medio de pago (credito, debito o billetera virtual)
///   2. Si es tarjeta: completar el formulario (con validaciones)
///   3. "Procesando pago..." (espera de 2 segundos)
///   4. Pago aprobado
///
/// Devuelve true si el pago se aprobo.
Future<bool> mostrarVentanaPago(
  BuildContext context, {
  required String producto,
  required String precio,
}) async {
  final aprobado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VentanaPago(producto: producto, precio: precio),
  );
  return aprobado ?? false;
}

enum _Paso { medio, tarjeta, procesando, aprobado }

enum _Medio { credito, debito, billetera }

class _VentanaPago extends StatefulWidget {
  final String producto;
  final String precio;
  const _VentanaPago({required this.producto, required this.precio});

  @override
  State<_VentanaPago> createState() => _VentanaPagoState();
}

class _VentanaPagoState extends State<_VentanaPago> {
  _Paso _paso = _Paso.medio;
  _Medio _medio = _Medio.credito;

  // Formulario de tarjeta
  final _formulario = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _nombre = TextEditingController();
  final _vencimiento = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Redibuja la tarjeta de la vista previa mientras se escribe.
    _numero.addListener(() => setState(() {}));
    _nombre.addListener(() => setState(() {}));
    _vencimiento.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numero.dispose();
    _nombre.dispose();
    _vencimiento.dispose();
    _cvv.dispose();
    super.dispose();
  }

  bool get _esTarjeta => _medio != _Medio.billetera;

  String get _nombreMedio => switch (_medio) {
        _Medio.credito => 'Tarjeta de crédito',
        _Medio.debito => 'Tarjeta de débito',
        _Medio.billetera => 'Billetera PokePay',
      };

  // ---------- Acciones ----------

  void _continuar() {
    if (_esTarjeta) {
      setState(() => _paso = _Paso.tarjeta);
    } else {
      _pagar();
    }
  }

  void _usarTarjetaDePrueba() {
    _numero.text = '4242424242424242';
    _nombre.text = 'ASH KETCHUM';
    _vencimiento.text = '12/29';
    _cvv.text = '123';
  }

  void _confirmarTarjeta() {
    // validate() ejecuta los "validator" de cada campo y muestra los errores
    if (_formulario.currentState!.validate()) _pagar();
  }

  Future<void> _pagar() async {
    FocusScope.of(context).unfocus(); // cierra el teclado
    setState(() => _paso = _Paso.procesando);
    await Future.delayed(const Duration(seconds: 2)); // simula el banco
    if (!mounted) return;
    setState(() => _paso = _Paso.aprobado);
  }

  // ---------- Validaciones ----------

  String? _validarNumero(String? valor) {
    if (valor == null || valor.length != 16) return 'Tiene que tener 16 números';
    return null;
  }

  String? _validarNombre(String? valor) {
    if (valor == null || valor.trim().length < 3) return 'Escribí el nombre del titular';
    return null;
  }

  String? _validarVencimiento(String? valor) {
    // Formato MM/AA, con mes entre 01 y 12
    final formato = RegExp(r'^(0[1-9]|1[0-2])/\d{2}$');
    if (valor == null || !formato.hasMatch(valor)) return 'Formato MM/AA';
    return null;
  }

  String? _validarCvv(String? valor) {
    if (valor == null || valor.length != 3) return '3 números';
    return null;
  }

  // ---------- Pantallas de cada paso ----------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: switch (_paso) {
          _Paso.medio => _pasoMedio(),
          _Paso.tarjeta => _pasoTarjeta(),
          _Paso.procesando => _pasoProcesando(),
          _Paso.aprobado => _pasoAprobado(),
        },
      ),
    );
  }

  /// Resumen del producto (se muestra arriba en los primeros pasos).
  Widget _resumen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.amarillo.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_rounded, color: ColoresApp.rojo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.producto,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          Text(widget.precio,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: ColoresApp.rojo)),
        ],
      ),
    );
  }

  // Paso 1: elegir medio de pago
  Widget _pasoMedio() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medio de pago',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _resumen(),
        const SizedBox(height: 14),
        _OpcionMedio(
          icono: Icons.credit_card_rounded,
          titulo: 'Tarjeta de crédito',
          detalle: 'Hasta 3 cuotas sin interés',
          elegido: _medio == _Medio.credito,
          alTocar: () => setState(() => _medio = _Medio.credito),
        ),
        _OpcionMedio(
          icono: Icons.payment_rounded,
          titulo: 'Tarjeta de débito',
          detalle: 'Se descuenta en el momento',
          elegido: _medio == _Medio.debito,
          alTocar: () => setState(() => _medio = _Medio.debito),
        ),
        _OpcionMedio(
          icono: Icons.account_balance_wallet_rounded,
          titulo: 'Billetera PokePay',
          detalle: 'Saldo disponible: \$ 10.000',
          elegido: _medio == _Medio.billetera,
          alTocar: () => setState(() => _medio = _Medio.billetera),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: _continuar,
                child: Text(_esTarjeta ? 'Continuar' : 'Pagar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Paso 2: formulario de tarjeta
  Widget _pasoTarjeta() {
    return Form(
      key: _formulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _paso = _Paso.medio),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text(_nombreMedio,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          _VistaTarjeta(
            numero: _numero.text,
            nombre: _nombre.text,
            vencimiento: _vencimiento.text,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _numero,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // solo numeros
              LengthLimitingTextInputFormatter(16), // maximo 16
            ],
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              prefixIcon: Icon(Icons.credit_card_rounded),
              border: OutlineInputBorder(),
            ),
            validator: _validarNumero,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nombre del titular',
              prefixIcon: Icon(Icons.person_rounded),
              border: OutlineInputBorder(),
            ),
            validator: _validarNombre,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vencimiento,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [LengthLimitingTextInputFormatter(5)],
                  decoration: const InputDecoration(
                    labelText: 'Vence (MM/AA)',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarVencimiento,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  obscureText: true, // se ve como ***
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarCvv,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _usarTarjetaDePrueba,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: const Text('Usar tarjeta de prueba'),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmarTarjeta,
              icon: const Icon(Icons.lock_rounded),
              label: Text('Pagar ${widget.precio}'),
            ),
          ),
        ],
      ),
    );
  }

  // Paso 3: procesando
  Widget _pasoProcesando() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 6, color: ColoresApp.rojo),
        ),
        const SizedBox(height: 20),
        const Text('Procesando pago...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Conectando con $_nombreMedio', textAlign: TextAlign.center),
        const SizedBox(height: 20),
      ],
    );
  }

  // Paso 4: aprobado
  Widget _pasoAprobado() {
    final ultimos = _numero.text.length == 16 ? _numero.text.substring(12) : '';
    final detalleMedio = _esTarjeta ? '$_nombreMedio •••• $ultimos' : _nombreMedio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: ColoresApp.verde, size: 80),
        const SizedBox(height: 8),
        const Text('¡Pago aprobado!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _resumen(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_esTarjeta ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded,
                size: 18),
            const SizedBox(width: 6),
            Text(detalleMedio),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('¡Genial!'),
          ),
        ),
      ],
    );
  }
}

/// Una opcion de medio de pago (se marca la elegida).
class _OpcionMedio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final bool elegido;
  final VoidCallback alTocar;

  const _OpcionMedio({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.elegido,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: elegido ? ColoresApp.rojo : Colors.grey.shade400,
            width: elegido ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, size: 30, color: elegido ? ColoresApp.rojo : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(detalle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Icon(
              elegido ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: elegido ? ColoresApp.rojo : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibujo de la tarjeta que se va completando mientras se escribe.
class _VistaTarjeta extends StatelessWidget {
  final String numero;
  final String nombre;
  final String vencimiento;

  const _VistaTarjeta({
    required this.numero,
    required this.nombre,
    required this.vencimiento,
  });

  /// "4242424242" -> "4242 4242 42•• ••••"
  String get _numeroFormateado {
    final completo = numero.padRight(16, '•');
    return '${completo.substring(0, 4)} ${completo.substring(4, 8)} '
        '${completo.substring(8, 12)} ${completo.substring(12, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.azul, ColoresApp.azulOscuro],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.memory_rounded, color: ColoresApp.amarillo, size: 34), // chip
              Text('PokéCard',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const Spacer(),
          Text(_numeroFormateado,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(nombre.isEmpty ? 'NOMBRE DEL TITULAR' : nombre.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Text(vencimiento.isEmpty ? 'MM/AA' : vencimiento,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
