import 'package:flutter/foundation.dart';

import '../../../../core/utils/csv_exporter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/movimientos/domain/movimiento.dart';
import '../../../../features/productos/domain/producto.dart';
import '../../domain/filtro_historial.dart';
import '../../domain/reporte_inventario.dart';
import '../../domain/reporte_repository.dart';

class ReportesProvider extends ChangeNotifier {
  ReportesProvider(this._repository);

  final ReporteRepository _repository;

  ReporteInventario? _reporte;
  List<Producto> _alertas = [];
  List<Movimiento> _historial = [];
  FiltroHistorial _filtro = const FiltroHistorial();
  bool _cargando = false;

  ReporteInventario? get reporte => _reporte;
  List<Producto> get alertas => List.unmodifiable(_alertas);
  List<Movimiento> get historial => List.unmodifiable(_historial);
  FiltroHistorial get filtro => _filtro;
  bool get cargando => _cargando;

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _repository.obtenerReporteInventario(),
        _repository.productosConStockBajo(),
        _repository.obtenerHistorial(_filtro),
      ]);
      _reporte = resultados[0] as ReporteInventario;
      _alertas = resultados[1] as List<Producto>;
      _historial = resultados[2] as List<Movimiento>;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> aplicarFiltro({
    int? productoId,
    TipoMovimiento? tipo,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    _filtro = FiltroHistorial(
      productoId: productoId,
      tipo: tipo,
      desde: desde,
      hasta: hasta,
    );
    _cargando = true;
    notifyListeners();
    try {
      _historial = await _repository.obtenerHistorial(_filtro);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> limpiarFiltros() => aplicarFiltro();

  Future<void> exportarInventarioCsv() async {
    final List<Producto> productos = await _repository.obtenerInventarioCompleto();
    final List<List<dynamic>> filas = [
      [
        'Código',
        'Nombre',
        'Descripción',
        'Categoría',
        'Precio compra',
        'Precio venta',
        'Stock actual',
        'Stock mínimo',
        'Estado',
      ],
      ...productos.map((p) => [
            p.codigo,
            p.nombre,
            p.descripcion ?? '',
            p.categoriaNombre ?? '',
            p.precioCompra,
            p.precioVenta,
            p.stock,
            p.stockMinimo,
            p.activo ? 'Activo' : 'Inactivo',
          ]),
    ];
    final String ruta = await CsvExporter.guardarCsv('inventario', filas);
    await CsvExporter.compartirArchivo(ruta);
  }

  Future<void> exportarHistorialCsv() async {
    final List<Movimiento> movimientos =
        await _repository.obtenerHistorial(_filtro);
    final List<List<dynamic>> filas = [
      [
        'Fecha',
        'Producto',
        'Código',
        'Tipo',
        'Cantidad',
        'Stock anterior',
        'Stock resultante',
        'Motivo',
        'Responsable',
      ],
      ...movimientos.map((m) => [
            Formatters.fechaHora(m.fechaHora),
            m.productoNombre ?? '',
            m.productoCodigo ?? '',
            m.tipo.etiqueta,
            m.cantidad,
            m.stockAnterior,
            m.stockResultante,
            m.motivo,
            m.responsable,
          ]),
    ];
    final String ruta = await CsvExporter.guardarCsv('historial', filas);
    await CsvExporter.compartirArchivo(ruta);
  }
}
