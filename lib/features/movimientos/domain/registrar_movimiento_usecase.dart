import '../../../core/errors/inventario_exception.dart';
import '../../productos/domain/producto_repository.dart';
import 'movimiento.dart';
import 'movimiento_repository.dart';

/// Caso de uso que valida y registra los movimientos de inventario.
/// Todas las reglas de negocio viven aquí, en la capa de dominio.
class RegistrarMovimientoUseCase {
  RegistrarMovimientoUseCase(this._movimientoRepository, this._productoRepository);

  final MovimientoRepository _movimientoRepository;
  final ProductoRepository _productoRepository;

  /// Registra una entrada o salida de inventario.
  Future<Movimiento> registrarEntradaSalida({
    required int productoId,
    required TipoMovimiento tipo,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    if (tipo == TipoMovimiento.ajuste) {
      throw const InventarioException(
        'Utilice registrarAjuste para los conteos físicos.',
      );
    }
    if (cantidad <= 0) {
      throw const InventarioException(
        'La cantidad debe ser mayor que cero.',
      );
    }
    if (motivo.trim().isEmpty) {
      throw const InventarioException('El motivo es obligatorio.');
    }
    if (responsable.trim().isEmpty) {
      throw const InventarioException('El responsable es obligatorio.');
    }

    final producto = await _productoRepository.obtenerPorId(productoId);
    if (producto == null) {
      throw const InventarioException('El producto no existe.');
    }

    final int stockAnterior = producto.stock;
    final int stockResultante;
    if (tipo == TipoMovimiento.entrada) {
      stockResultante = stockAnterior + cantidad;
    } else {
      if (cantidad > stockAnterior) {
        throw InventarioException(
          'No se permiten salidas superiores al stock disponible '
          '($stockAnterior unidades).',
        );
      }
      stockResultante = stockAnterior - cantidad;
    }

    return _registrar(
      Movimiento(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        stockAnterior: stockAnterior,
        stockResultante: stockResultante,
        motivo: motivo.trim(),
        responsable: responsable.trim(),
        fechaHora: DateTime.now(),
      ),
    );
  }

  /// Registra un ajuste por conteo físico. La cantidad contada se guarda
  /// como existencias resultantes y exige justificación obligatoria.
  Future<Movimiento> registrarAjuste({
    required int productoId,
    required int cantidadContada,
    required String justificacion,
    required String responsable,
  }) async {
    if (cantidadContada < 0) {
      throw const InventarioException(
        'La cantidad contada no puede ser negativa.',
      );
    }
    if (justificacion.trim().isEmpty) {
      throw const InventarioException(
        'El ajuste requiere una justificación obligatoria.',
      );
    }
    if (responsable.trim().isEmpty) {
      throw const InventarioException('El responsable es obligatorio.');
    }

    final producto = await _productoRepository.obtenerPorId(productoId);
    if (producto == null) {
      throw const InventarioException('El producto no existe.');
    }

    return _registrar(
      Movimiento(
        productoId: productoId,
        tipo: TipoMovimiento.ajuste,
        cantidad: cantidadContada,
        stockAnterior: producto.stock,
        stockResultante: cantidadContada,
        motivo: 'Conteo físico. $justificacion'.trim(),
        responsable: responsable.trim(),
        fechaHora: DateTime.now(),
      ),
    );
  }

  Future<Movimiento> _registrar(Movimiento movimiento) {
    return _movimientoRepository.registrarMovimiento(movimiento);
  }
}
