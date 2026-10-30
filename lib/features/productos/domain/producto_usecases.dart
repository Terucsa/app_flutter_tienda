import '../../../core/errors/inventario_exception.dart';
import 'producto.dart';
import 'producto_repository.dart';

/// Casos de uso de productos con las validaciones de negocio en dominio.
class ProductoUseCases {
  ProductoUseCases(this._repository);

  final ProductoRepository _repository;

  Future<Producto> crearProducto({
    required String codigo,
    required String nombre,
    String? descripcion,
    required int categoriaId,
    required double precioCompra,
    required double precioVenta,
    required int stockInicial,
    required int stockMinimo,
    String? fotoPath,
  }) async {
    final String codigoLimpio = codigo.trim();
    if (codigoLimpio.isEmpty) {
      throw const InventarioException('El código del producto es obligatorio.');
    }
    if (nombre.trim().isEmpty) {
      throw const InventarioException('El nombre del producto es obligatorio.');
    }
    if (precioCompra < 0 || precioVenta < 0) {
      throw const InventarioException('Los precios no pueden ser negativos.');
    }
    if (stockInicial < 0 || stockMinimo < 0) {
      throw const InventarioException(
        'El stock no puede tener valores negativos.',
      );
    }
    if (await _repository.existeCodigo(codigoLimpio)) {
      throw const InventarioException(
        'El código ya está registrado. Utilice un código único.',
      );
    }

    final Producto producto = Producto(
      codigo: codigoLimpio,
      nombre: nombre.trim(),
      descripcion: _limpiarDescripcion(descripcion),
      categoriaId: categoriaId,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      stock: stockInicial,
      stockMinimo: stockMinimo,
      fotoPath: fotoPath,
      activo: true,
      fechaCreacion: DateTime.now(),
    );

    return _repository.guardarProducto(producto, stockInicial: stockInicial);
  }

  Future<void> actualizarProducto(
    Producto productoActual, {
    required String codigo,
    required String nombre,
    String? descripcion,
    required int categoriaId,
    required double precioCompra,
    required double precioVenta,
    required int stockMinimo,
    String? fotoPath,
  }) async {
    final String codigoLimpio = codigo.trim();
    if (codigoLimpio.isEmpty) {
      throw const InventarioException('El código del producto es obligatorio.');
    }
    if (nombre.trim().isEmpty) {
      throw const InventarioException('El nombre del producto es obligatorio.');
    }
    if (precioCompra < 0 || precioVenta < 0 || stockMinimo < 0) {
      throw const InventarioException('Los valores no pueden ser negativos.');
    }
    if (await _repository.existeCodigo(codigoLimpio, excluirId: productoActual.id)) {
      throw const InventarioException(
        'El código ya está registrado en otro producto.',
      );
    }

    final Producto actualizado = productoActual.copyWith(
      codigo: codigoLimpio,
      nombre: nombre.trim(),
      descripcion: _limpiarDescripcion(descripcion),
      categoriaId: categoriaId,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      stockMinimo: stockMinimo,
      fotoPath: fotoPath,
    );

    await _repository.actualizarProducto(actualizado);
  }

  Future<void> cambiarEstado(int id, bool activo) {
    return _repository.alternarActivo(id, activo);
  }

  String? _limpiarDescripcion(String? descripcion) {
    final String? limpia = descripcion?.trim();
    return (limpia == null || limpia.isEmpty) ? null : limpia;
  }
}
