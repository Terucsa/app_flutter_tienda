import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../../core/errors/inventario_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../inicio/presentation/providers/inicio_provider.dart';
import '../../../movimientos/domain/movimiento.dart';
import '../../../movimientos/presentation/pages/movimiento_page.dart';
import '../../../movimientos/presentation/providers/movimientos_provider.dart';
import '../../../reportes/presentation/providers/reportes_provider.dart';
import '../../domain/producto.dart';
import '../providers/productos_provider.dart';
import '../widgets/etiqueta_codigos_widget.dart';

/// Detalle del producto: datos, existencias, etiquetas escaneables,
/// formulario rápido de entrada/salida y exportación CSV.
class ProductoDetallePage extends StatefulWidget {
  const ProductoDetallePage({super.key, required this.productoId});

  final int productoId;

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  Producto? _producto;
  TipoMovimiento _tipo = TipoMovimiento.entrada;
  String _motivo = 'Compra';
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _responsableController =
      TextEditingController(text: 'Admin');
  bool _registrando = false;
  bool _exportando = false;

  List<String> get _motivos =>
      _tipo == TipoMovimiento.entrada ? const ['Compra', 'Devolución'] : const ['Venta', 'Daño'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarProducto());
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _cargarProducto() async {
    final ProductosProvider provider = context.read<ProductosProvider>();
    final Producto? producto =
        await provider.obtenerProducto(widget.productoId);
    if (mounted) {
      setState(() => _producto = producto);
    }
  }

  Future<void> _registrarMovimientoRapido() async {
    final Producto? producto = _producto;
    if (producto == null) return;

    final int? cantidad = int.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad <= 0) {
      await _mostrarError('Ingrese una cantidad mayor que cero.');
      return;
    }

    setState(() => _registrando = true);
    final MovimientosProvider movimientosProvider =
        context.read<MovimientosProvider>();
    try {
      final Movimiento movimiento =
          await movimientosProvider.registrarEntradaSalida(
        productoId: producto.id!,
        tipo: _tipo,
        cantidad: cantidad,
        motivo: _motivo,
        responsable: _responsableController.text,
      );
      await _cargarProducto();
      if (mounted) {
        context.read<ProductosProvider>().cargar();
        context.read<InicioProvider>().cargarResumen();
      }
      if (mounted) {
        await _mostrarMovimientoExitoso(movimiento);
        _cantidadController.clear();
      }
    } on InventarioException catch (error) {
      if (mounted) await _mostrarError(error.mensaje);
    } catch (_) {
      if (mounted) await _mostrarError('No se pudo registrar el movimiento.');
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _mostrarMovimientoExitoso(Movimiento movimiento) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: TemaApp.colorExito,
          size: 44,
        ),
        content: Text(
          'Movimiento registrado.\n'
          'Stock anterior: ${movimiento.stockAnterior}\n'
          'Stock resultante: ${movimiento.stockResultante}',
          textAlign: TextAlign.center,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarError(String mensaje) async {
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Atención'),
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

  void _irMovimientoCompleto(Producto producto) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => MovimientoPage(productoId: producto.id),
      ),
    );
  }

  Future<void> _exportarCsv() async {
    setState(() => _exportando = true);
    try {
      await context.read<ReportesProvider>().exportarInventarioCsv();
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            content: const Text('Inventario exportado a CSV correctamente.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) await _mostrarError('No se pudo exportar el CSV.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Producto? producto = _producto;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(producto?.nombre ?? 'Detalle del producto'),
      ),
      child: SafeArea(
        child: producto == null
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _FichaProducto(producto: producto),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('Etiquetas (código de barras y QR)'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: EtiquetaCodigosWidget(producto: producto),
                      ),
                    ],
                  ),
                  _FormularioRapidoMovimiento(
                    tipo: _tipo,
                    motivo: _motivo,
                    motivos: _motivos,
                    cantidadController: _cantidadController,
                    responsableController: _responsableController,
                    registrando: _registrando,
                    onTipoCambiado: (tipo) => setState(() {
                      _tipo = tipo;
                      _motivo = _motivos.first;
                    }),
                    onMotivoCambiado: (motivo) =>
                        setState(() => _motivo = motivo),
                    onRegistrar: _registrarMovimientoRapido,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: CupertinoButton(
                      color: TemaApp.colorPrimario,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => _irMovimientoCompleto(producto),
                      child: const Text(
                        'Registrar movimiento completo (con ajuste)',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _exportando ? null : _exportarCsv,
                      child: _exportando
                          ? const CupertinoActivityIndicator()
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.doc_text),
                                SizedBox(width: 6),
                                Text('Exportar inventario a CSV'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FichaProducto extends StatelessWidget {
  const _FichaProducto({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final Color colorStock =
        producto.stockBajo ? TemaApp.colorPeligro : TemaApp.colorExito;

    return CupertinoFormSection.insetGrouped(
      header: const Text('Información del producto'),
      children: [
        CupertinoListTile(
          title: Text(producto.nombre),
          subtitle: Text('Código: ${producto.codigo}'),
          leading: producto.fotoPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(producto.fotoPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  CupertinoIcons.cube_box,
                  size: 32,
                  color: TemaApp.colorPrimario,
                ),
        ),
        if (producto.descripcion != null)
          CupertinoListTile(
            title: const Text('Descripción'),
            subtitle: Text(producto.descripcion!),
          ),
        CupertinoListTile(
          title: const Text('Categoría'),
          trailing: Text(producto.categoriaNombre ?? '—'),
        ),
        CupertinoListTile(
          title: const Text('Precio de compra'),
          trailing: Text(Formatters.moneda(producto.precioCompra)),
        ),
        CupertinoListTile(
          title: const Text('Precio de venta'),
          trailing: Text(Formatters.moneda(producto.precioVenta)),
        ),
        CupertinoListTile(
          title: const Text('Stock actual'),
          trailing: Text(
            '${producto.stock} unidades',
            style: TextStyle(color: colorStock, fontWeight: FontWeight.w700),
          ),
        ),
        CupertinoListTile(
          title: const Text('Stock mínimo'),
          trailing: Text('${producto.stockMinimo} unidades'),
        ),
        CupertinoListTile(
          title: const Text('Estado'),
          trailing: Text(
            producto.activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: producto.activo
                  ? TemaApp.colorExito
                  : CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        if (producto.stockBajo)
          Container(
            width: double.infinity,
            color: TemaApp.colorPeligro.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: TemaApp.colorPeligro,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alerta: stock igual o inferior al mínimo.',
                    style: TextStyle(color: TemaApp.colorPeligro),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FormularioRapidoMovimiento extends StatelessWidget {
  const _FormularioRapidoMovimiento({
    required this.tipo,
    required this.motivo,
    required this.motivos,
    required this.cantidadController,
    required this.responsableController,
    required this.registrando,
    required this.onTipoCambiado,
    required this.onMotivoCambiado,
    required this.onRegistrar,
  });

  final TipoMovimiento tipo;
  final String motivo;
  final List<String> motivos;
  final TextEditingController cantidadController;
  final TextEditingController responsableController;
  final bool registrando;
  final ValueChanged<TipoMovimiento> onTipoCambiado;
  final ValueChanged<String> onMotivoCambiado;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('Movimiento rápido (entrada o salida)'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CupertinoSlidingSegmentedControl<TipoMovimiento>(
            groupValue: tipo,
            onValueChanged: (valor) {
              if (valor != null) onTipoCambiado(valor);
            },
            children: const {
              TipoMovimiento.entrada: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Entrada'),
              ),
              TipoMovimiento.salida: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Salida'),
              ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: motivo,
            onValueChanged: (valor) {
              if (valor != null) onMotivoCambiado(valor);
            },
            children: {
              for (final texto in motivos)
                texto: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(texto),
                ),
            },
          ),
        ),
        CupertinoTextFormFieldRow(
          controller: cantidadController,
          placeholder: 'Cantidad',
          prefix: const Text('Cantidad'),
          keyboardType: TextInputType.number,
        ),
        CupertinoTextFormFieldRow(
          controller: responsableController,
          placeholder: 'Responsable',
          prefix: const Text('Responsable'),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: CupertinoButton(
            color: TemaApp.colorExito,
            borderRadius: BorderRadius.circular(12),
            onPressed: registrando ? null : onRegistrar,
            child: registrando
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Registrar movimiento',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
