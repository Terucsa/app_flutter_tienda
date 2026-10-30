import 'package:flutter/cupertino.dart';

import '../widgets/formulario_movimiento.dart';

/// Pantalla de registro de movimientos de inventario
/// (entradas, salidas y ajustes).
class MovimientoPage extends StatelessWidget {
  const MovimientoPage({super.key, this.productoId});

  final int? productoId;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Registrar movimiento'),
      ),
      child: SafeArea(
        child: FormularioMovimiento(productoId: productoId),
      ),
    );
  }
}
