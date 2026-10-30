import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Utilidades genéricas para generar archivos CSV en el almacenamiento
/// local y compartirlos desde la aplicación.
class CsvExporter {
  CsvExporter._();

  static String _nombreArchivo(String prefijo) {
    final DateTime ahora = DateTime.now();
    final String sello =
        '${ahora.year}${ahora.month.toString().padLeft(2, '0')}'
        '${ahora.day.toString().padLeft(2, '0')}'
        '_${ahora.hour.toString().padLeft(2, '0')}'
        '${ahora.minute.toString().padLeft(2, '0')}'
        '${ahora.second.toString().padLeft(2, '0')}';
    return '${prefijo}_$sello.csv';
  }

  /// Escribe las [filas] (incluyendo la cabecera) en un CSV y devuelve su ruta.
  static Future<String> guardarCsv(
    String prefijo,
    List<List<dynamic>> filas,
  ) async {
    final String csv = const ListToCsvConverter().convert(filas);
    final Directory directorio = await getApplicationDocumentsDirectory();
    final String ruta = p.join(directorio.path, _nombreArchivo(prefijo));
    await File(ruta).writeAsString(csv);
    return ruta;
  }

  /// Comparte un archivo usando el panel del sistema.
  static Future<void> compartirArchivo(String ruta) async {
    await Share.shareXFiles([XFile(ruta)]);
  }
}
