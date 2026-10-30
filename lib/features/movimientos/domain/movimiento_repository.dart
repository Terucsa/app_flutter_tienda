import 'movimiento.dart';

/// Contrato del repositorio de movimientos de inventario.
abstract class MovimientoRepository {
  /// Registra el movimiento y actualiza las existencias en una sola
  /// operación (transacción SQL).
  Future<Movimiento> registrarMovimiento(Movimiento movimiento);

  Future<List<Movimiento>> obtenerMovimientos({
    int? productoId,
    TipoMovimiento? tipo,
    DateTime? desde,
    DateTime? hasta,
  });
}
