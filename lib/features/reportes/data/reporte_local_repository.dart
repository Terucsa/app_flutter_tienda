import '../../../core/database/app_database.dart';
import '../../movimientos/domain/movimiento.dart';
import '../../productos/domain/producto.dart';
import '../domain/filtro_historial.dart';
import '../domain/reporte_inventario.dart';
import '../domain/reporte_repository.dart';

class ReporteLocalRepository implements ReporteRepository {
  ReporteLocalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<ReporteInventario> obtenerReporteInventario() async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN activo = 1 THEN stock_actual * precio_compra ELSE 0 END), 0) AS valor_total,
        SUM(CASE WHEN activo = 1 THEN 1 ELSE 0 END) AS activos,
        SUM(CASE WHEN activo = 1 AND stock_actual <= stock_minimo THEN 1 ELSE 0 END) AS stock_bajo
      FROM productos
    ''');

    final Map<String, dynamic> fila = filas.first;
    return ReporteInventario(
      valorTotal: ((fila['valor_total'] as num?) ?? 0).toDouble(),
      totalProductosActivos: (fila['activos'] as int?) ?? 0,
      alertasStockBajo: (fila['stock_bajo'] as int?) ?? 0,
    );
  }

  @override
  Future<List<Producto>> productosConStockBajo() async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.activo = 1 AND p.stock_actual <= p.stock_minimo '
      'ORDER BY p.stock_actual ASC',
    );
    return filas.map(Producto.fromMap).toList();
  }

  @override
  Future<List<Movimiento>> obtenerHistorial(FiltroHistorial filtro) async {
    final List<String> condiciones = [];
    final List<Object?> argumentos = [];

    if (filtro.productoId != null) {
      condiciones.add('m.producto_id = ?');
      argumentos.add(filtro.productoId);
    }
    if (filtro.tipo != null) {
      condiciones.add('m.tipo = ?');
      argumentos.add(filtro.tipo!.codigo);
    }
    if (filtro.desde != null) {
      condiciones.add('m.fecha_hora >= ?');
      argumentos.add(filtro.desde!.toIso8601String());
    }
    if (filtro.hasta != null) {
      condiciones.add('m.fecha_hora <= ?');
      argumentos.add(filtro.hasta!.toIso8601String());
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

  @override
  Future<List<Producto>> obtenerInventarioCompleto() async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'ORDER BY p.nombre COLLATE NOCASE',
    );
    return filas.map(Producto.fromMap).toList();
  }
}
