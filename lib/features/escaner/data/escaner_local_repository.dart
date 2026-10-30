import '../../../core/database/app_database.dart';
import '../../productos/domain/producto.dart';
import '../domain/escaner_repository.dart';
import '../domain/resultado_escaneo.dart';

class EscanerLocalRepository implements EscanerRepository {
  EscanerLocalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<ResultadoEscaneo> buscarPorCodigo(String codigo) async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.codigo = ?',
      [codigo.trim()],
    );
    if (filas.isEmpty) {
      return ResultadoEscaneo.noEncontrado(codigo.trim());
    }
    return ResultadoEscaneo.encontrado(Producto.fromMap(filas.first));
  }

  @override
  Future<List<Producto>> buscarManual(String texto) async {
    final String busqueda = texto.trim();
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.codigo LIKE ? OR p.nombre LIKE ? '
      'ORDER BY p.nombre COLLATE NOCASE LIMIT 20',
      ['%$busqueda%', '%$busqueda%'],
    );
    return filas.map(Producto.fromMap).toList();
  }
}
