import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Versión con dart:io (móvil y escritorio).
bool esEscritorio() =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// Configura SQLite nativo para plataformas de escritorio.
void configurarFfiEscritorio() {
  if (databaseFactoryOrNull == null) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
