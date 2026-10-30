import 'package:sqflite/sqflite.dart';

/// Versión no web: la fábrica web nunca se usa en esta plataforma.
DatabaseFactory databaseFactoryWeb() =>
    throw UnsupportedError('La fábrica web no está disponible aquí.');
