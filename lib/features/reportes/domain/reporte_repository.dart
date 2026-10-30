import '../../movimientos/domain/movimiento.dart';
import '../../productos/domain/producto.dart';
import 'filtro_historial.dart';
import 'reporte_inventario.dart';

/// Contrato del repositorio de reportes y consultas.
abstract class ReporteRepository {
  Future<ReporteInventario> obtenerReporteInventario();

  Future<List<Producto>> productosConStockBajo();

  Future<List<Movimiento>> obtenerHistorial(FiltroHistorial filtro);

  Future<List<Producto>> obtenerInventarioCompleto();
}
