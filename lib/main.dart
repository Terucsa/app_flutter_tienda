import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase appDatabase = AppDatabase();
  try {
    await appDatabase.init();
    await DatabaseSeeder(appDatabase.database).seed();
  } catch (error) {
    debugPrint('Error al inicializar la base de datos: $error');
  }

  runApp(AppTienda(appDatabase: appDatabase));
}
