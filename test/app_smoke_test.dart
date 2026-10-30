import 'package:app_tienda/app/app.dart';
import 'package:app_tienda/core/database/app_database.dart';
import 'package:app_tienda/core/database/database_seeder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets(
      'la aplicación arranca y muestra los productos de demostración',
      (WidgetTester tester) async {
    final AppDatabase appDatabase = AppDatabase(ruta: inMemoryDatabasePath);
    await tester.runAsync(() async {
      await appDatabase.init();
      await DatabaseSeeder(appDatabase.database).seed();
    });

    await tester.pumpWidget(AppTienda(appDatabase: appDatabase));

    // Deja que las consultas asíncronas a SQLite terminen en tiempo real.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventario Inteligente'), findsOneWidget);
    expect(find.text('Valor del inventario: Q 3287.50'), findsOneWidget);
    expect(find.text('Agua Pura 500ml'), findsOneWidget);

    // Los productos inferiores del listado requieren desplazamiento.
    await tester.scrollUntilVisible(
      find.text('Coca Cola 355ml'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Coca Cola 355ml'), findsOneWidget);

    await tester.runAsync(() => appDatabase.cerrar());
  });
}
