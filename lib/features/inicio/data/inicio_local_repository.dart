import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/inicio_repository.dart';
import '../domain/resumen_inicio.dart';

class InicioLocalRepository implements InicioRepository {
  InicioLocalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<ResumenInicio> obtenerResumen() async {
    final Database db = _database.database;

    final List<Map<String, dynamic>> totales = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_productos,
        SUM(CASE WHEN activo = 1 THEN 1 ELSE 0 END) AS activos,
        SUM(CASE WHEN activo = 1 AND stock_actual <= stock_minimo
             THEN 1 ELSE 0 END) AS stock_bajo
      FROM productos
    ''');

    final List<Map<String, dynamic>> valor = await db.rawQuery(
      'SELECT COALESCE(SUM(stock_actual * precio_compra), 0) AS total '
      'FROM productos WHERE activo = 1',
    );

    final Map<String, dynamic> fila = totales.first;
    return ResumenInicio(
      totalProductos: (fila['total_productos'] as int?) ?? 0,
      productosActivos: (fila['activos'] as int?) ?? 0,
      alertasStockBajo: (fila['stock_bajo'] as int?) ?? 0,
      valorInventario: ((valor.first['total'] as num?) ?? 0).toDouble(),
    );
  }
}
