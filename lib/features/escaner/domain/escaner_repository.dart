import '../../productos/domain/producto.dart';
import 'resultado_escaneo.dart';

/// Contrato del repositorio del escáner.
abstract class EscanerRepository {
  /// Busca un producto por su código único (lectura de cámara).
  Future<ResultadoEscaneo> buscarPorCodigo(String codigo);

  /// Búsqueda manual por código o nombre.
  Future<List<Producto>> buscarManual(String texto);
}
