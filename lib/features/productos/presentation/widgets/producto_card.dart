import 'package:flutter/cupertino.dart';

import '../../../../app/tema.dart';
import '../../domain/producto.dart';

/// Tarjeta reutilizable de producto (estilo iOS).
/// - Nombre con botón de detalle a la par.
/// - Botones inferiores: activar/desactivar y editar.
class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    required this.onDetalle,
    required this.onEditar,
    required this.onAlternarActivo,
  });

  final Producto producto;
  final VoidCallback onDetalle;
  final VoidCallback onEditar;
  final VoidCallback onAlternarActivo;

  @override
  Widget build(BuildContext context) {
    final Color colorStock =
        producto.stockBajo ? TemaApp.colorPeligro : TemaApp.colorExito;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaApp.colorTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      producto.codigo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                onPressed: onDetalle,
                child: const Icon(
                  CupertinoIcons.info_circle,
                  color: TemaApp.colorPrimario,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: producto.activo
                      ? CupertinoColors.systemGreen.withValues(alpha: 0.15)
                      : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  producto.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: producto.activo
                        ? TemaApp.colorExito
                        : CupertinoColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stock: ${producto.stock}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorStock,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: producto.activo
                      ? CupertinoColors.systemGrey5
                      : TemaApp.colorExito,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: onAlternarActivo,
                  child: Text(
                    producto.activo ? 'Desactivar' : 'Activar',
                    style: TextStyle(
                      fontSize: 14,
                      color: producto.activo
                          ? CupertinoColors.label
                          : CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: TemaApp.colorPrimario,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: onEditar,
                  child: const Text(
                    'Editar',
                    style: TextStyle(fontSize: 14, color: CupertinoColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
