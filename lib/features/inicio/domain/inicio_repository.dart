import 'resumen_inicio.dart';

/// Contrato del repositorio de la pantalla de inicio.
abstract class InicioRepository {
  Future<ResumenInicio> obtenerResumen();
}
