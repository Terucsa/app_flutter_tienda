import 'package:flutter/cupertino.dart';

/// Paleta de colores y tema Cupertino de la aplicación.
class TemaApp {
  TemaApp._();

  static const Color colorPrimario = Color(0xFF007AFF);
  static const Color colorExito = Color(0xFF34C759);
  static const Color colorAdvertencia = Color(0xFFFF9500);
  static const Color colorPeligro = Color(0xFFFF3B30);
  static const Color colorFondo = Color(0xFFF2F2F7);
  static const Color colorTarjeta = CupertinoColors.white;

  static CupertinoThemeData temaCupertino() {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: colorPrimario,
      scaffoldBackgroundColor: colorFondo,
      barBackgroundColor: CupertinoColors.systemBackground,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          color: CupertinoColors.label,
          fontFamily: '.SF Pro Text',
        ),
      ),
    );
  }
}
