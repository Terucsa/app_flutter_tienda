import '../../../core/database/app_database.dart';
import '../domain/categoria.dart';
import '../domain/producto.dart';
import '../domain/producto_repository.dart';

/// Implementación local con SQLite del repositorio de productos.
class ProductoLocalRepository implements ProductoRepository {
  ProductoLocalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Producto>> obtenerProductos({
    String? busqueda,
    bool? soloActivos,
  }) async {
    final List<String> condiciones = [];
    final List<Object?> argumentos = [];

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      condiciones.add('(p.codigo LIKE ? OR p.nombre LIKE ?)');
      argumentos
        ..add('%${busqueda.trim()}%')
        ..add('%${busqueda.trim()}%');
    }
    if (soloActivos != null) {
      condiciones.add(soloActivos ? 'p.activo = 1' : 'p.activo = 0');
    }

    final String where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      '$where ORDER BY p.nombre COLLATE NOCASE',
      argumentos,
    );

    return filas.map(Producto.fromMap).toList();
  }

  @override
  Future<Producto?> obtenerPorId(int id) async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.id = ?',
      [id],
    );
    if (filas.isEmpty) return null;
    return Producto.fromMap(filas.first);
  }

  @override
  Future<Producto?> obtenerPorCodigo(String codigo) async {
    final List<Map<String, dynamic>> filas = await _database.database.rawQuery(
      'SELECT p.*, c.nombre AS categoria_nombre '
      'FROM productos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE p.codigo = ?',
      [codigo.trim()],
    );
    if (filas.isEmpty) return null;
    return Producto.fromMap(filas.first);
  }

  @override
  Future<Producto> guardarProducto(Producto producto,
      {int stockInicial = 0}) async {
    final int? nuevoId = await _database.database.transaction((txn) async {
      final int id = await txn.insert('productos', producto.toMap());

      if (stockInicial > 0) {
        await txn.insert('movimientos', {
          'producto_id': id,
          'tipo': 'ENTRADA',
          'cantidad': stockInicial,
          'stock_anterior': 0,
          'stock_resultante': stockInicial,
          'motivo': 'Inventario inicial',
          'responsable': 'Sistema',
          'fecha_hora': DateTime.now().toIso8601String(),
        });
      }
      return id;
    });

    return producto.copyWith(id: nuevoId);
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    await _database.database.update(
      'productos',
      {
        'codigo': producto.codigo,
        'nombre': producto.nombre,
        'descripcion': producto.descripcion,
        'categoria_id': producto.categoriaId,
        'precio_compra': producto.precioCompra,
        'precio_venta': producto.precioVenta,
        'stock_minimo': producto.stockMinimo,
        'foto_path': producto.fotoPath,
        'activo': producto.activo ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  @override
  Future<void> alternarActivo(int id, bool activo) async {
    await _database.database.update(
      'productos',
      {'activo': activo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    final List<Map<String, dynamic>> filas = await _database.database.query(
      'categorias',
      orderBy: 'nombre COLLATE NOCASE',
    );
    return filas.map(Categoria.fromMap).toList();
  }

  @override
  Future<bool> existeCodigo(String codigo, {int? excluirId}) async {
    final List<Map<String, dynamic>> filas = await _database.database.query(
      'productos',
      columns: ['id'],
      where: 'codigo = ?',
      whereArgs: [codigo.trim()],
    );
    return filas.any((fila) => fila['id'] != excluirId);
  }
}
