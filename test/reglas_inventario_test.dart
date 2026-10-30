import 'package:app_tienda/core/database/app_database.dart';
import 'package:app_tienda/core/database/database_seeder.dart';
import 'package:app_tienda/core/errors/inventario_exception.dart';
import 'package:app_tienda/features/movimientos/data/movimiento_local_repository.dart';
import 'package:app_tienda/features/movimientos/domain/movimiento.dart';
import 'package:app_tienda/features/movimientos/domain/registrar_movimiento_usecase.dart';
import 'package:app_tienda/features/productos/data/producto_local_repository.dart';
import 'package:app_tienda/features/productos/domain/producto.dart';
import 'package:app_tienda/features/productos/domain/producto_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  late ProductoLocalRepository productoRepository;
  late MovimientoLocalRepository movimientoRepository;
  late ProductoUseCases productoUseCases;
  late RegistrarMovimientoUseCase registrarMovimiento;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    appDatabase = AppDatabase(ruta: inMemoryDatabasePath);
    await appDatabase.init();
    productoRepository = ProductoLocalRepository(appDatabase);
    movimientoRepository = MovimientoLocalRepository(appDatabase);
    productoUseCases = ProductoUseCases(productoRepository);
    registrarMovimiento = RegistrarMovimientoUseCase(
      movimientoRepository,
      productoRepository,
    );
    await appDatabase.database.insert('categorias', {'nombre': 'Bebidas'});
  });

  tearDown(() async {
    await appDatabase.cerrar();
  });

  Future<Producto> crearProductoDemo({int stockInicial = 20}) {
    return productoUseCases.crearProducto(
      codigo: 'PROD-001',
      nombre: 'Agua Pura 500ml',
      descripcion: 'Botella de agua purificada',
      categoriaId: 1,
      precioCompra: 1.5,
      precioVenta: 2.5,
      stockInicial: stockInicial,
      stockMinimo: 5,
    );
  }

  group('Datos de demostración', () {
    test('el seeder precarga 3 categorías y 15 productos con trazabilidad',
        () async {
      await appDatabase.database.delete('movimientos');
      await appDatabase.database.delete('productos');
      await appDatabase.database.delete('categorias');

      final DatabaseSeeder seeder = DatabaseSeeder(appDatabase.database);
      await seeder.seed();

      final categorias = await appDatabase.database.query('categorias');
      expect(categorias, hasLength(3));

      final productos = await appDatabase.database.query('productos');
      expect(productos, hasLength(15));

      final movimientos = await appDatabase.database.query('movimientos');
      expect(movimientos, hasLength(15));
      expect(
        movimientos.every((m) => m['tipo'] == 'ENTRADA'),
        isTrue,
      );

      // El seed es idempotente: no duplica datos en ejecuciones posteriores.
      await seeder.seed();
      final categoriasDespues = await appDatabase.database.query('categorias');
      final productosDespues = await appDatabase.database.query('productos');
      expect(categoriasDespues, hasLength(3));
      expect(productosDespues, hasLength(15));
    });
  });

  group('Reglas de negocio de productos', () {
    test('crear producto con stock inicial registra movimiento de entrada', () async {
      final Producto producto = await crearProductoDemo(stockInicial: 20);

      expect(producto.id, isNotNull);
      expect(producto.stock, 20);

      final List<Movimiento> movimientos =
          await movimientoRepository.obtenerMovimientos();
      expect(movimientos, hasLength(1));
      expect(movimientos.first.tipo, TipoMovimiento.entrada);
      expect(movimientos.first.motivo, 'Inventario inicial');
      expect(movimientos.first.stockAnterior, 0);
      expect(movimientos.first.stockResultante, 20);
    });

    test('no permite códigos duplicados', () async {
      await crearProductoDemo();

      expect(
        () => crearProductoDemo(),
        throwsA(isA<InventarioException>()),
      );
    });

    test('valida que el código y el nombre sean obligatorios', () async {
      expect(
        () => productoUseCases.crearProducto(
          codigo: '   ',
          nombre: 'Producto sin código',
          categoriaId: 1,
          precioCompra: 1,
          precioVenta: 2,
          stockInicial: 0,
          stockMinimo: 0,
        ),
        throwsA(isA<InventarioException>()),
      );

      expect(
        () => productoUseCases.crearProducto(
          codigo: 'PROD-099',
          nombre: '  ',
          categoriaId: 1,
          precioCompra: 1,
          precioVenta: 2,
          stockInicial: 0,
          stockMinimo: 0,
        ),
        throwsA(isA<InventarioException>()),
      );
    });

    test('producto con movimientos se desactiva y conserva su historial',
        () async {
      final Producto producto = await crearProductoDemo();

      await productoRepository.alternarActivo(producto.id!, false);

      final Producto? inactivo =
          await productoRepository.obtenerPorId(producto.id!);
      expect(inactivo, isNotNull);
      expect(inactivo!.activo, isFalse);

      final List<Movimiento> movimientos =
          await movimientoRepository.obtenerMovimientos();
      expect(movimientos, isNotEmpty);
    });
  });

  group('Reglas de negocio de movimientos', () {
    test('la cantidad de entrada y salida debe ser mayor que cero', () async {
      final Producto producto = await crearProductoDemo();

      expect(
        () => registrarMovimiento.registrarEntradaSalida(
          productoId: producto.id!,
          tipo: TipoMovimiento.salida,
          cantidad: 0,
          motivo: 'Venta',
          responsable: 'Admin',
        ),
        throwsA(isA<InventarioException>()),
      );

      expect(
        () => registrarMovimiento.registrarEntradaSalida(
          productoId: producto.id!,
          tipo: TipoMovimiento.entrada,
          cantidad: -5,
          motivo: 'Compra',
          responsable: 'Admin',
        ),
        throwsA(isA<InventarioException>()),
      );
    });

    test('no permite salidas superiores al stock disponible', () async {
      final Producto producto = await crearProductoDemo(stockInicial: 20);

      expect(
        () => registrarMovimiento.registrarEntradaSalida(
          productoId: producto.id!,
          tipo: TipoMovimiento.salida,
          cantidad: 21,
          motivo: 'Venta',
          responsable: 'Admin',
        ),
        throwsA(isA<InventarioException>()),
      );

      // El stock queda intacto y no se registra movimiento parcial.
      final Producto? actualizado =
          await productoRepository.obtenerPorId(producto.id!);
      expect(actualizado!.stock, 20);
      final List<Movimiento> movimientos =
          await movimientoRepository.obtenerMovimientos();
      expect(movimientos, hasLength(1));
    });

    test('la salida exitosa actualiza existencias con trazabilidad', () async {
      final Producto producto = await crearProductoDemo(stockInicial: 20);

      final Movimiento salida = await registrarMovimiento.registrarEntradaSalida(
        productoId: producto.id!,
        tipo: TipoMovimiento.salida,
        cantidad: 16,
        motivo: 'Venta',
        responsable: 'Admin',
      );

      expect(salida.stockAnterior, 20);
      expect(salida.stockResultante, 4);

      final Producto? actualizado =
          await productoRepository.obtenerPorId(producto.id!);
      expect(actualizado!.stock, 4);
      expect(actualizado.stockBajo, isTrue);
    });

    test('la entrada aumenta las existencias', () async {
      final Producto producto = await crearProductoDemo(stockInicial: 4);

      final Movimiento entrada = await registrarMovimiento.registrarEntradaSalida(
        productoId: producto.id!,
        tipo: TipoMovimiento.entrada,
        cantidad: 10,
        motivo: 'Compra',
        responsable: 'Admin',
      );

      expect(entrada.stockAnterior, 4);
      expect(entrada.stockResultante, 14);

      final Producto? actualizado =
          await productoRepository.obtenerPorId(producto.id!);
      expect(actualizado!.stock, 14);
    });

    test('el ajuste exige justificación obligatoria', () async {
      final Producto producto = await crearProductoDemo();

      expect(
        () => registrarMovimiento.registrarAjuste(
          productoId: producto.id!,
          cantidadContada: 3,
          justificacion: '   ',
          responsable: 'Admin',
        ),
        throwsA(isA<InventarioException>()),
      );
    });

    test('el ajuste por conteo físico corrige las existencias', () async {
      final Producto producto = await crearProductoDemo(stockInicial: 20);

      final Movimiento ajuste = await registrarMovimiento.registrarAjuste(
        productoId: producto.id!,
        cantidadContada: 3,
        justificacion: 'Conteo físico: faltan unidades',
        responsable: 'Admin',
      );

      expect(ajuste.tipo, TipoMovimiento.ajuste);
      expect(ajuste.stockAnterior, 20);
      expect(ajuste.stockResultante, 3);

      final Producto? actualizado =
          await productoRepository.obtenerPorId(producto.id!);
      expect(actualizado!.stock, 3);
    });

    test('flujo completo de la prueba de aceptación', () async {
      // 1. Producto con stock mínimo de 5 y entrada inicial de 20.
      final Producto producto = await crearProductoDemo(stockInicial: 20);

      // 2. Salida de 16 → quedan 4 (alerta de stock bajo).
      await registrarMovimiento.registrarEntradaSalida(
        productoId: producto.id!,
        tipo: TipoMovimiento.salida,
        cantidad: 16,
        motivo: 'Venta',
        responsable: 'Admin',
      );
      Producto? actual = await productoRepository.obtenerPorId(producto.id!);
      expect(actual!.stock, 4);
      expect(actual.stockBajo, isTrue);

      // 3. Retirar 5 se impide (no hay suficiente stock).
      expect(
        () => registrarMovimiento.registrarEntradaSalida(
          productoId: producto.id!,
          tipo: TipoMovimiento.salida,
          cantidad: 5,
          motivo: 'Venta',
          responsable: 'Admin',
        ),
        throwsA(isA<InventarioException>()),
      );

      // 4. Conteo físico de 3 con justificación.
      await registrarMovimiento.registrarAjuste(
        productoId: producto.id!,
        cantidadContada: 3,
        justificacion: 'Conteo físico semanal',
        responsable: 'Admin',
      );
      actual = await productoRepository.obtenerPorId(producto.id!);
      expect(actual!.stock, 3);

      // 5. Historial completo: entrada inicial, salida y ajuste.
      final List<Movimiento> historial =
          await movimientoRepository.obtenerMovimientos();
      expect(historial, hasLength(3));
      expect(
        historial.map((m) => m.tipo).toSet(),
        containsAll([
          TipoMovimiento.entrada,
          TipoMovimiento.salida,
          TipoMovimiento.ajuste,
        ]),
      );
    });
  });
}
