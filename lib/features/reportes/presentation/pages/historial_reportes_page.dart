import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../../core/utils/formatters.dart';
import '../../../movimientos/domain/movimiento.dart';
import '../../../productos/domain/producto.dart';
import '../../../productos/presentation/providers/productos_provider.dart';
import '../providers/reportes_provider.dart';

/// Historial de movimientos y reportes del inventario,
/// con filtros por producto, tipo y fechas, y exportación CSV.
class HistorialReportesPage extends StatefulWidget {
  const HistorialReportesPage({super.key});

  @override
  State<HistorialReportesPage> createState() => _HistorialReportesPageState();
}

class _HistorialReportesPageState extends State<HistorialReportesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportesProvider>().cargar();
      context.read<ProductosProvider>().cargar();
    });
  }

  Future<void> _seleccionarProducto() async {
    final ReportesProvider provider = context.read<ReportesProvider>();
    final List<Producto> productos =
        context.read<ProductosProvider>().todosLosProductos;
    if (!mounted) return;

    int indiceInicial = 0;
    final int? idActual = provider.filtro.productoId;
    if (idActual != null) {
      final int existente = productos.indexWhere((p) => p.id == idActual);
      if (existente >= 0) indiceInicial = existente + 1;
    }

    final int? seleccion = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Text(
                    'Filtrar por producto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        Navigator.of(context).pop(indiceInicial),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
              Container(height: 1, color: CupertinoColors.separator),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: indiceInicial,
                  ),
                  itemExtent: 36,
                  onSelectedItemChanged: (indice) =>
                      indiceInicial = indice,
                  children: [
                    const Center(child: Text('Todos los productos')),
                    ...productos.map(
                      (producto) => Center(
                        child: Text(
                          producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (seleccion == null) return;
    final int? productoId =
        seleccion == 0 ? null : productos[seleccion - 1].id;
    await provider.aplicarFiltro(productoId: productoId);
  }

  Future<void> _seleccionarFecha({required bool esDesde}) async {
    final ReportesProvider provider = context.read<ReportesProvider>();
    final DateTime? fechaInicial =
        esDesde ? provider.filtro.desde : provider.filtro.hasta;
    final DateTime? fecha = await _mostrarPickerFecha(esDesde, fechaInicial);
    if (fecha != null) {
      await provider.aplicarFiltro(
        desde: esDesde ? fecha : provider.filtro.desde,
        hasta: esDesde ? provider.filtro.hasta : fecha,
      );
    }
  }

  Future<DateTime?> _mostrarPickerFecha(
    bool esDesde,
    DateTime? fechaInicial,
  ) {
    DateTime seleccionada = fechaInicial ?? DateTime.now();
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  Text(
                    esDesde ? 'Fecha desde' : 'Fecha hasta',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        Navigator.of(context).pop(seleccionada),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
              Container(height: 1, color: CupertinoColors.separator),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: seleccionada,
                  maximumDate: esDesde ? null : DateTime.now(),
                  onDateTimeChanged: (fecha) => seleccionada = fecha,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportarInventario() async {
    try {
      await context.read<ReportesProvider>().exportarInventarioCsv();
      await _mostrarMensaje('Inventario exportado a CSV correctamente.');
    } catch (_) {
      await _mostrarMensaje('No se pudo exportar el inventario.');
    }
  }

  Future<void> _exportarHistorial() async {
    try {
      await context.read<ReportesProvider>().exportarHistorialCsv();
      await _mostrarMensaje('Historial exportado a CSV correctamente.');
    } catch (_) {
      await _mostrarMensaje('No se pudo exportar el historial.');
    }
  }

  Future<void> _mostrarMensaje(String mensaje) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReportesProvider provider = context.watch<ReportesProvider>();
    final filtro = provider.filtro;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Historial y reportes'),
      ),
      child: SafeArea(
        child: provider.cargando && provider.historial.isEmpty
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _TarjetaValorInventario(provider: provider),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('Alertas de stock bajo'),
                    children: provider.alertas.isEmpty
                        ? const [
                            CupertinoListTile(
                              title: Text(
                                'Sin alertas de stock',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ),
                          ]
                        : provider.alertas
                            .map(
                              (producto) => CupertinoListTile(
                                title: Text(producto.nombre),
                                subtitle:
                                    Text('Código: ${producto.codigo}'),
                                trailing: Text(
                                  '${producto.stock} / mín. '
                                  '${producto.stockMinimo}',
                                  style: const TextStyle(
                                    color: TemaApp.colorPeligro,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('Filtros del historial'),
                    children: [
                      CupertinoListTile(
                        title: const Text('Producto'),
                        trailing: Text(
                          filtro.productoId == null
                              ? 'Todos'
                              : _nombreProducto(filtro.productoId!),
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        onTap: _seleccionarProducto,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            CupertinoSlidingSegmentedControl<String>(
                          groupValue: _valorTipoFiltro(filtro.tipo),
                          onValueChanged: (valor) {
                            if (valor != null) {
                              provider.aplicarFiltro(
                                tipo: _tipoDesdeValor(valor),
                              );
                            }
                          },
                          children: const {
                            'todos': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Todos'),
                            ),
                            'entrada': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Entradas'),
                            ),
                            'salida': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Salidas'),
                            ),
                            'ajuste': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('Ajustes'),
                            ),
                          },
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('Fecha desde'),
                        trailing: Text(
                          filtro.desde == null
                              ? 'Todas'
                              : Formatters.fecha(filtro.desde!),
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        onTap: () => _seleccionarFecha(esDesde: true),
                      ),
                      CupertinoListTile(
                        title: const Text('Fecha hasta'),
                        trailing: Text(
                          filtro.hasta == null
                              ? 'Todas'
                              : Formatters.fecha(filtro.hasta!),
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        onTap: () => _seleccionarFecha(esDesde: false),
                      ),
                      if (filtro.productoId != null ||
                          filtro.tipo != null ||
                          filtro.desde != null ||
                          filtro.hasta != null)
                        CupertinoButton(
                          onPressed: provider.limpiarFiltros,
                          child: const Text(
                            'Limpiar filtros',
                            style: TextStyle(
                              color: TemaApp.colorPeligro,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  CupertinoFormSection.insetGrouped(
                    header: Text(
                      'Historial de movimientos (${provider.historial.length})',
                    ),
                    children: provider.historial.isEmpty
                        ? const [
                            CupertinoListTile(
                              title: Text(
                                'No hay movimientos con estos filtros',
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ),
                          ]
                        : provider.historial
                            .map((movimiento) => _FilaMovimiento(
                                movimiento: movimiento))
                            .toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        CupertinoButton(
                          color: TemaApp.colorPrimario,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _exportarInventario,
                          child: const Text(
                            'Exportar inventario a CSV',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _exportarHistorial,
                          child: const Text(
                            'Exportar historial a CSV',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _nombreProducto(int id) {
    final productos = context.read<ProductosProvider>().todosLosProductos;
    return productos.where((p) => p.id == id).map((p) => p.nombre).firstOrNull ??
        'Producto';
  }

  String _valorTipoFiltro(TipoMovimiento? tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'entrada';
      case TipoMovimiento.salida:
        return 'salida';
      case TipoMovimiento.ajuste:
        return 'ajuste';
      case null:
        return 'todos';
    }
  }

  TipoMovimiento? _tipoDesdeValor(String valor) {
    switch (valor) {
      case 'entrada':
        return TipoMovimiento.entrada;
      case 'salida':
        return TipoMovimiento.salida;
      case 'ajuste':
        return TipoMovimiento.ajuste;
      default:
        return null;
    }
  }
}

class _TarjetaValorInventario extends StatelessWidget {
  const _TarjetaValorInventario({required this.provider});

  final ReportesProvider provider;

  @override
  Widget build(BuildContext context) {
    final reporte = provider.reporte;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.colorTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: reporte == null
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: TemaApp.colorExito,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Valor del inventario',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.moneda(reporte.valorTotal),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimación: existencias × precio de compra registrado',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${reporte.totalProductosActivos} productos activos · '
                  '${reporte.alertasStockBajo} con stock bajo',
                  style: TextStyle(
                    fontSize: 13,
                    color: reporte.alertasStockBajo > 0
                        ? TemaApp.colorPeligro
                        : CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({required this.movimiento});

  final Movimiento movimiento;

  IconData get _icono {
    switch (movimiento.tipo) {
      case TipoMovimiento.entrada:
        return CupertinoIcons.arrow_down_circle_fill;
      case TipoMovimiento.salida:
        return CupertinoIcons.arrow_up_circle_fill;
      case TipoMovimiento.ajuste:
        return CupertinoIcons.arrow_2_squarepath;
    }
  }

  Color get _color {
    switch (movimiento.tipo) {
      case TipoMovimiento.entrada:
        return TemaApp.colorExito;
      case TipoMovimiento.salida:
        return TemaApp.colorPeligro;
      case TipoMovimiento.ajuste:
        return TemaApp.colorAdvertencia;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icono, color: _color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.productoNombre ?? 'Producto',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movimiento.tipo.etiqueta} · ${movimiento.motivo}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                Text(
                  '${Formatters.fechaHora(movimiento.fechaHora)} · '
                  '${movimiento.responsable}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                movimiento.tipo == TipoMovimiento.ajuste
                    ? 'Conteo: ${movimiento.cantidad}'
                    : '${movimiento.tipo == TipoMovimiento.entrada ? '+' : '-'}'
                        '${movimiento.cantidad}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${movimiento.stockAnterior} → ${movimiento.stockResultante}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
