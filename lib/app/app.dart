import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../core/database/app_database.dart';
import '../features/escaner/data/escaner_local_repository.dart';
import '../features/escaner/presentation/providers/escaner_provider.dart';
import '../features/inicio/data/inicio_local_repository.dart';
import '../features/inicio/presentation/pages/inicio_page.dart';
import '../features/inicio/presentation/providers/inicio_provider.dart';
import '../features/movimientos/data/movimiento_local_repository.dart';
import '../features/movimientos/domain/registrar_movimiento_usecase.dart';
import '../features/movimientos/presentation/providers/movimientos_provider.dart';
import '../features/productos/data/producto_local_repository.dart';
import '../features/productos/domain/producto_repository.dart';
import '../features/productos/domain/producto_usecases.dart';
import '../features/productos/presentation/providers/productos_provider.dart';
import '../features/reportes/data/reporte_local_repository.dart';
import '../features/reportes/presentation/providers/reportes_provider.dart';
import 'tema.dart';

/// Raíz de la aplicación: configura el tema Cupertino y los proveedores
/// de estado de cada funcionalidad.
class AppTienda extends StatelessWidget {
  const AppTienda({super.key, required this.appDatabase});

  final AppDatabase appDatabase;

  @override
  Widget build(BuildContext context) {
    final ProductoRepository productoRepository =
        ProductoLocalRepository(appDatabase);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductosProvider>(
          create: (_) => ProductosProvider(
            productoRepository,
            ProductoUseCases(productoRepository),
          ),
        ),
        ChangeNotifierProvider<InicioProvider>(
          create: (_) => InicioProvider(InicioLocalRepository(appDatabase)),
        ),
        ChangeNotifierProvider<MovimientosProvider>(
          create: (_) => MovimientosProvider(
            RegistrarMovimientoUseCase(
              MovimientoLocalRepository(appDatabase),
              productoRepository,
            ),
          ),
        ),
        ChangeNotifierProvider<EscanerProvider>(
          create: (_) => EscanerProvider(EscanerLocalRepository(appDatabase)),
        ),
        ChangeNotifierProvider<ReportesProvider>(
          create: (_) => ReportesProvider(ReporteLocalRepository(appDatabase)),
        ),
      ],
      child: CupertinoApp(
        title: 'Inventario Inteligente',
        debugShowCheckedModeBanner: false,
        theme: TemaApp.temaCupertino(),
        home: const InicioPage(),
      ),
    );
  }
}
