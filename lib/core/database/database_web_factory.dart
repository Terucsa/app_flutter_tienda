import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Fábrica SQLite para Flutter Web (persistencia en indexeddb).
DatabaseFactory databaseFactoryWeb() => databaseFactoryFfiWeb;
