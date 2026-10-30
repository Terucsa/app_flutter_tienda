import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_ffi_stub.dart'
    if (dart.library.io) 'database_ffi_io.dart' as escritorio;
import 'database_web_factory_stub.dart'
    if (dart.library.js_interop) 'database_web_factory.dart' as web;

/// Punto único de acceso a la base de datos local SQLite.
///
/// Soporta las tres plataformas:
/// - Android/iOS: sqflite nativo.
/// - Linux/Windows/macOS: sqflite_common_ffi.
/// - Web (Chrome): sqflite_common_ffi_web (persistencia en indexeddb).
class AppDatabase {
  AppDatabase({String? ruta}) : _rutaPersonalizada = ruta;

  static const String _nombreArchivo = 'inventario_inteligente.db';
  static const int _version = 1;

  final String? _rutaPersonalizada;
  Database? _database;

  Future<Database> init() async {
    if (_database != null) {
      return _database!;
    }

    if (kIsWeb) {
      databaseFactory = web.databaseFactoryWeb();
      _database = await openDatabase(
        _nombreArchivo,
        version: _version,
        onCreate: crearEsquema,
      );
      return _database!;
    }

    if (escritorio.esEscritorio()) {
      escritorio.configurarFfiEscritorio();
    }

    final String ruta =
        _rutaPersonalizada ?? join(await getDatabasesPath(), _nombreArchivo);
    _database = await openDatabase(
      ruta,
      version: _version,
      onCreate: crearEsquema,
    );
    return _database!;
  }

  Database get database {
    final Database? db = _database;
    if (db == null) {
      throw StateError(
        'La base de datos no está inicializada. Llame a init() primero.',
      );
    }
    return db;
  }

  Future<void> cerrar() async {
    await _database?.close();
    _database = null;
  }

  /// Crea el esquema de tablas del inventario.
  static Future<void> crearEsquema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        categoria_id INTEGER NOT NULL,
        precio_compra REAL NOT NULL,
        precio_venta REAL NOT NULL,
        stock_actual INTEGER NOT NULL DEFAULT 0,
        stock_minimo INTEGER NOT NULL DEFAULT 0,
        foto_path TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        stock_anterior INTEGER NOT NULL,
        stock_resultante INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        responsable TEXT NOT NULL,
        fecha_hora TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_movimientos_producto ON movimientos (producto_id)',
    );
    await db.execute(
      'CREATE INDEX idx_movimientos_fecha ON movimientos (fecha_hora)',
    );
  }
}
