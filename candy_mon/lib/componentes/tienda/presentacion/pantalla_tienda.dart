import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:candy_mon/componentes/usuario/datos/usuario_provider.dart';
import 'package:candy_mon/general/utilidades/sonido.dart';
import 'package:candy_mon/general/styles/tema_app.dart';
import 'package:candy_mon/general/widgets/fondo_app.dart';
import 'package:candy_mon/general/widgets/encabezado.dart';
import 'package:candy_mon/componentes/tienda/presentacion/ventana_pago.dart';

class _Pack {
  final int diamantes;
  final String price;
  final String emoji;
  final String? tag;
  const _Pack(this.diamantes, this.price, this.emoji, [this.tag]);
}

/// POKESHOP: monetizacion SIMULADA (la pide la consigna).
/// Se compran diamantes y la cuenta PRO; no hay cobro real.
class PantallaTienda extends StatelessWidget {
  const PantallaTienda({super.key});

  static const _packs = [
    _Pack(50, '\$ 499', '💎'),
    _Pack(150, '\$ 1.299', '💎💎', '+20%'),
    _Pack(400, '\$ 2.999', '💰', 'POPULAR'),
    _Pack(1000, '\$ 5.999', '👑', 'MEJOR VALOR'),
  ];

  Future<void> _comprarPaquete(BuildContext context, _Pack pack) async {
    final usuario = context.read<UsuarioProvider>();
    final pagado = await mostrarVentanaPago(context,
        producto: '${pack.diamantes} diamantes', precio: pack.price);
    if (!pagado) return;
    if (!context.mounted) return;
    ServicioSonido.instancia.reproducir('coin');
    usuario.sumarDiamantes(pack.diamantes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Sumaste ${pack.diamantes} 💎!')),
    );
  }

  Future<void> _comprarPro(BuildContext context) async {
    final usuario = context.read<UsuarioProvider>();
    final pagado = await mostrarVentanaPago(context,
        producto: 'CandyMon PRO', precio: '\$ 2.499 / mes');
    if (!pagado) return;
    if (!context.mounted) return;
    ServicioSonido.instancia.reproducir('coin');
    usuario.cambiarPro(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('👑 ¡Ya sos PRO!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>();
    return Scaffold(
      body: FondoApp(
        child: SafeArea(
          child: Column(
            children: [
              const Encabezado(mostrarVolver: true, abrirTiendaConDiamantes: false),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('PokeShop',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _ProCard(
                      esPro: usuario.esPro,
                      onBuy: () => _comprarPro(context),
                      onCancel: () => usuario.cambiarPro(false),
                    ),
                    const SizedBox(height: 20),
                    const Text('Diamantes',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        for (final p in _packs)
                          _PackCard(pack: p, onTap: () => _comprarPaquete(context, p)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  final bool esPro;
  final VoidCallback onBuy;
  final VoidCallback onCancel;
  const _ProCard({required this.esPro, required this.onBuy, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [ColoresApp.amarillo, ColoresApp.naranja, ColoresApp.rojo]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x55FF9F1C), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('👑', style: TextStyle(fontSize: 36)),
              SizedBox(width: 10),
              Text('CandyMon PRO',
                  style: TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('✔ Sin publicidad\n✔ Insignia 👑 PRO en tu perfil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: esPro
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    onPressed: onCancel,
                    child: const Text('Ya sos PRO · Volver a BASIC'),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColoresApp.naranja,
                    ),
                    onPressed: onBuy,
                    child: const Text('Hacerme PRO · \$ 2.499 / mes'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final _Pack pack;
  final VoidCallback onTap;
  const _PackCard({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              // FittedBox: si la tarjeta queda chica, achica el contenido
              // en vez de desbordar ("bottom overflowed").
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pack.emoji, style: const TextStyle(fontSize: 38)),
                      const SizedBox(height: 6),
                      Text('${pack.diamantes}',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900, color: ColoresApp.diamante)),
                      const Text('diamantes'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColoresApp.rojo,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(pack.price,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (pack.tag != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColoresApp.amarillo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pack.tag!,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
