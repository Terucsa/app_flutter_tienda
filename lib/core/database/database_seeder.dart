import 'package:sqflite/sqflite.dart';

/// Inserta los datos de demostración en la primera ejecución:
/// 3 categorías y 15 productos, con su movimiento de entrada inicial
/// para conservar la trazabilidad de las existencias.
class DatabaseSeeder {
  DatabaseSeeder(this._database);

  final Database _database;

  static const List<Map<String, Object?>> _categorias = [
    {'nombre': 'Bebidas'},
    {'nombre': 'Abarrotes'},
    {'nombre': 'Limpieza'},
  ];

  // [codigo, nombre, descripcion, categoria, precioCompra, precioVenta, stock, stockMinimo]
  static const List<List<Object?>> _productos = [
    ['PROD-001', 'Coca Cola 355ml', 'Bebida gaseosa en lata', 0, 4.5, 6.0, 24, 6],
    ['PROD-002', 'Agua Pura 500ml', 'Botella de agua purificada', 0, 1.5, 2.5, 40, 10],
    ['PROD-003', 'Jugo de Naranja 1L', 'Jugo natural de naranja', 0, 7.0, 10.0, 18, 5],
    ['PROD-004', 'Café Molido 250g', 'Café tostado y molido', 1, 22.0, 28.0, 30, 8],
    ['PROD-005', 'Azúcar 1kg', 'Azúcar blanca granulada', 1, 6.5, 8.0, 50, 12],
    ['PROD-006', 'Arroz 5lb', 'Arroz de grano entero', 1, 18.0, 23.0, 25, 6],
    ['PROD-007', 'Frijol Negro 1lb', 'Frijol negro seco', 1, 7.5, 9.5, 35, 10],
    ['PROD-008', 'Aceite Vegetal 1L', 'Aceite vegetal comestible', 1, 14.0, 18.5, 20, 5],
    ['PROD-009', 'Harina de Maíz 1kg', 'Harina de maíz nixtamalizado', 1, 5.0, 7.0, 22, 8],
    ['PROD-010', 'Sal 1lb', 'Sal yodada de mesa', 1, 2.0, 3.5, 45, 15],
    ['PROD-011', 'Detergente 800g', 'Detergente en polvo multiusos', 2, 13.0, 17.0, 15, 4],
    ['PROD-012', 'Jabón de Barra', 'Jabón de tocador 100g', 2, 2.5, 4.0, 60, 20],
    ['PROD-013', 'Cloro 1L', 'Cloro líquido desinfectante', 2, 8.0, 11.0, 12, 3],
    ['PROD-014', 'Desinfectante 500ml', 'Desinfectante aroma lavanda', 2, 9.5, 13.0, 10, 4],
    ['PROD-015', 'Papel Higiénico 4pk', 'Paquete de 4 rollos doble hoja', 2, 10.0, 14.5, 28, 7],
  ];

  Future<void> seed() async {
    final int? cantidadCategorias = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM categorias'),
    );
    if ((cantidadCategorias ?? 0) > 0) {
      return;
    }

    await _database.transaction((txn) async {
      final List<int> idsCategorias = [];
      for (final categoria in _categorias) {
        final int id = await txn.insert('categorias', categoria);
        idsCategorias.add(id);
      }

      for (final datos in _productos) {
        final String codigo = datos[0]! as String;
        final String nombre = datos[1]! as String;
        final String? descripcion = datos[2] as String?;
        final int categoriaId = idsCategorias[datos[3]! as int];
        final double precioCompra = (datos[4]! as num).toDouble();
        final double precioVenta = (datos[5]! as num).toDouble();
        final int stock = datos[6]! as int;
        final int stockMinimo = datos[7]! as int;

        final int productoId = await txn.insert('productos', {
          'codigo': codigo,
          'nombre': nombre,
          'descripcion': descripcion,
          'categoria_id': categoriaId,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'stock_actual': stock,
          'stock_minimo': stockMinimo,
          'foto_path': null,
          'activo': 1,
          'fecha_creacion': DateTime.now().toIso8601String(),
        });

        if (stock > 0) {
          await txn.insert('movimientos', {
            'producto_id': productoId,
            'tipo': 'ENTRADA',
            'cantidad': stock,
            'stock_anterior': 0,
            'stock_resultante': stock,
            'motivo': 'Inventario inicial',
            'responsable': 'Sistema',
            'fecha_hora': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }
}
