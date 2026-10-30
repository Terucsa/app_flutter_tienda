import 'categoria.dart';
import 'producto.dart';

/// Contrato del repositorio de productos (capa de dominio).
/// La implementación vive en la capa de datos.
abstract class ProductoRepository {
  Future<List<Producto>> obtenerProductos({
    String? busqueda,
    bool? soloActivos,
  });

  Future<Producto?> obtenerPorId(int id);

  Future<Producto?> obtenerPorCodigo(String codigo);

  /// Guarda un producto nuevo. Si [stockInicial] es mayor que cero,
  /// registra un movimiento de entrada en la misma transacción.
  Future<Producto> guardarProducto(Producto producto, {int stockInicial = 0});

  Future<void> actualizarProducto(Producto producto);

  Future<void> alternarActivo(int id, bool activo);

  Future<List<Categoria>> obtenerCategorias();

  Future<bool> existeCodigo(String codigo, {int? excluirId});
}
