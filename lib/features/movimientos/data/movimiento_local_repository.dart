import '../../../core/database/app_database.dart';
import '../../../core/errors/inventario_exception.dart';
import '../domain/movimiento.dart';
import '../domain/movimiento_repository.dart';

/// Implementación local con SQLite del repositorio de movimientos.
/// El registro del movimiento y la actualización del stock se ejecutan
/// como una sola operación atómica.
class MovimientoLocalRepository implements MovimientoRepository {
  MovimientoLocalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<Movimiento> registrarMovimiento(Movimiento movimiento) async {
    int stockAnterior = 0;
    int stockResultante = 0;

    final int? id = await _database.database.transaction((txn) async {
      final List<Map<String, dynamic>> filas = await txn.query(
        'productos',
        columns: ['stock_actual', 'activo'],
        where: 'id = ?',
        whereArgs: [movimiento.productoId],
      );
      if (filas.isEmpty) {
        throw const InventarioException('El producto no existe.');
      }
      stockAnterior = filas.first['stock_actual'] as int;

      switch (movimiento.tipo) {
        case TipoMovimiento.entrada:
          stockResultante = stockAnterior + movimiento.cantidad;
        case TipoMovimiento.salida:
          if (movimiento.cantidad > stockAnterior) {
            throw const InventarioException(
              'No se permiten salidas superiores al stock disponible.',
            );
          }
          stockResultante = stockAnterior - movimiento.cantidad;
        case TipoMovimiento.ajuste:
          stockResultante = movimiento.cantidad;
      }

      final int nuevoId = await txn.insert('movimientos', {
        'producto_id': movimiento.productoId,
        'tipo': movimiento.tipo.codigo,
        'cantidad': movimiento.cantidad,
        'stock_anterior': stockAnterior,
        'stock_resultante': stockResultante,
        'motivo': movimiento.motivo,
        'responsable': movimiento.responsable,
        'fecha_hora': movimiento.fechaHora.toIso8601String(),
      });

      await txn.update(
        'productos',
        {'stock_actual': stockResultante},
        where: 'id = ?',
        whereArgs: [movimiento.productoId],
      );

      return nuevoId;
    });

    return Movimiento(
      id: id,
      productoId: movimiento.productoId,
      productoNombre: movimiento.productoNombre,
      productoCodigo: movimiento.productoCodigo,
      tipo: movimiento.tipo,
      cantidad: movimiento.cantidad,
      stockAnterior: stockAnterior,
      stockResultante: stockResultante,
      motivo: movimiento.motivo,
      responsable: movimiento.responsable,
      fechaHora: movimiento.fechaHora,
    );
  }

  @override
  Future<List<Movimiento>> obtenerMovimientos({
    int? productoId,
    TipoMovimiento? tipo,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final List<String> condiciones = [];
    final List<Object?> argumentos = [];

    if (productoId != null) {
      condiciones.add('m.producto_id = ?');
      argumentos.add(productoId);
    }
    if (tipo != null) {
      condiciones.add('m.tipo = ?');
      argumentos.add(tipo.codigo);
    }
    if (desde != null) {
      condiciones.add('m.fecha_hora >= ?');
      argumentos.add(desde.toIso8601String());
    }
    if (hasta != null) {
      condiciones.add('m.fecha_hora <= ?');
      argumentos.add(hasta.toIso8601String());
    }

    final String where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT m.*, p.nombre AS producto_nombre, p.codigo AS producto_codigo '
      'FROM movimientos m '
      'JOIN productos p ON p.id = m.producto_id '
      '$where ORDER BY m.fecha_hora DESC, m.id DESC',
      argumentos,
    );

    return filas.map(Movimiento.fromMap).toList();
  }
}
