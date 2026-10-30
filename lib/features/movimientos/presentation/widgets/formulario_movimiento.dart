import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../../core/errors/inventario_exception.dart';
import '../../../inicio/presentation/providers/inicio_provider.dart';
import '../../../productos/domain/producto.dart';
import '../../../productos/presentation/providers/productos_provider.dart';
import '../../domain/movimiento.dart';
import '../providers/movimientos_provider.dart';

/// Formulario completo de registro de movimientos:
/// entradas, salidas y ajustes por conteo físico.
class FormularioMovimiento extends StatefulWidget {
  const FormularioMovimiento({super.key, this.productoId});

  final int? productoId;

  @override
  State<FormularioMovimiento> createState() => _FormularioMovimientoState();
}

class _FormularioMovimientoState extends State<FormularioMovimiento> {
  Producto? _producto;
  TipoMovimiento _tipo = TipoMovimiento.entrada;
  String _motivo = 'Compra';
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _cantidadContadaController =
      TextEditingController();
  final TextEditingController _justificacionController = TextEditingController();
  final TextEditingController _responsableController =
      TextEditingController(text: 'Admin');
  bool _registrando = false;

  List<String> get _motivos => _tipo == TipoMovimiento.entrada
      ? const ['Compra', 'Devolución']
      : const ['Venta', 'Daño'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.productoId != null) {
        final ProductosProvider provider = context.read<ProductosProvider>();
        final Producto? producto =
            await provider.obtenerProducto(widget.productoId!);
        if (mounted) setState(() => _producto = producto);
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _cantidadContadaController.dispose();
    _justificacionController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarProducto() async {
    final ProductosProvider provider = context.read<ProductosProvider>();
    await provider.cargar();
    final List<Producto> productos = provider.todosLosProductos;
    if (productos.isEmpty) {
      await _mostrarError('No hay productos registrados.');
      return;
    }
    if (!mounted) return;

    int indiceInicial = 0;
    final int? idActual = _producto?.id;
    if (idActual != null) {
      final int existente = productos.indexWhere((p) => p.id == idActual);
      if (existente >= 0) indiceInicial = existente;
    }

    final Producto? seleccionado = await showCupertinoModalPopup<Producto>(
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
                    'Seleccionar producto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CupertinoButton(
                    onPressed: () =>
                        Navigator.of(context).pop(productos[indiceInicial]),
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
                  children: productos
                      .map((producto) => Center(
                            child: Text(
                              '${producto.nombre} (${producto.codigo})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (seleccionado != null) {
      setState(() => _producto = seleccionado);
    }
  }

  Future<void> _registrar() async {
    final Producto? producto = _producto;
    if (producto == null) {
      await _mostrarError('Seleccione un producto.');
      return;
    }

    final MovimientosProvider provider = context.read<MovimientosProvider>();
    setState(() => _registrando = true);
    try {
      final Movimiento movimiento;
      if (_tipo == TipoMovimiento.ajuste) {
        final int? cantidadContada =
            int.tryParse(_cantidadContadaController.text.trim());
        if (cantidadContada == null || cantidadContada < 0) {
          await _mostrarError(
            'La cantidad contada debe ser un número mayor o igual a cero.',
          );
          return;
        }
        if (_justificacionController.text.trim().isEmpty) {
          await _mostrarError(
            'El ajuste requiere una justificación obligatoria.',
          );
          return;
        }
        movimiento = await provider.registrarAjuste(
          productoId: producto.id!,
          cantidadContada: cantidadContada,
          justificacion: _justificacionController.text,
          responsable: _responsableController.text,
        );
      } else {
        final int? cantidad =
            int.tryParse(_cantidadController.text.trim());
        if (cantidad == null || cantidad <= 0) {
          await _mostrarError('La cantidad debe ser mayor que cero.');
          return;
        }
        movimiento = await provider.registrarEntradaSalida(
          productoId: producto.id!,
          tipo: _tipo,
          cantidad: cantidad,
          motivo: _motivo,
          responsable: _responsableController.text,
        );
      }

      if (mounted) {
        context.read<ProductosProvider>().cargar();
        context.read<InicioProvider>().cargarResumen();
      }
      if (mounted) {
        await _mostrarExito(movimiento);
        if (mounted) Navigator.of(context).pop(true);
      }
    } on InventarioException catch (error) {
      if (mounted) await _mostrarError(error.mensaje);
    } catch (_) {
      if (mounted) await _mostrarError('No se pudo registrar el movimiento.');
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _mostrarExito(Movimiento movimiento) async {
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
          'Movimiento de ${movimiento.tipo.etiqueta.toLowerCase()} '
          'registrado correctamente.\n'
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

  @override
  Widget build(BuildContext context) {
    final Producto? producto = _producto;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        CupertinoFormSection.insetGrouped(
          header: const Text('Producto'),
          children: [
            CupertinoListTile(
              title: Text(
                producto?.nombre ?? 'Seleccionar producto',
                style: producto == null
                    ? const TextStyle(color: CupertinoColors.secondaryLabel)
                    : null,
              ),
              subtitle: producto == null
                  ? null
                  : Text(
                      'Código: ${producto.codigo} · '
                      'Stock actual: ${producto.stock}',
                    ),
              trailing: const Icon(CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey),
              onTap: _seleccionarProducto,
            ),
          ],
        ),
        CupertinoFormSection.insetGrouped(
          header: const Text('Tipo de movimiento'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSlidingSegmentedControl<TipoMovimiento>(
                groupValue: _tipo,
                onValueChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      _tipo = valor;
                      _motivo = _motivos.first;
                    });
                  }
                },
                children: const {
                  TipoMovimiento.entrada: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Entrada'),
                  ),
                  TipoMovimiento.salida: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Salida'),
                  ),
                  TipoMovimiento.ajuste: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Ajuste'),
                  ),
                },
              ),
            ),
          ],
        ),
        if (_tipo == TipoMovimiento.ajuste)
          CupertinoFormSection.insetGrouped(
            header: const Text('Conteo físico'),
            children: [
              CupertinoTextFormFieldRow(
                controller: _cantidadContadaController,
                placeholder: 'Cantidad contada',
                prefix: const Text('Contada'),
                keyboardType: TextInputType.number,
              ),
              CupertinoTextFormFieldRow(
                controller: _justificacionController,
                placeholder: 'Justificación obligatoria',
                prefix: const Text('Justificación'),
                maxLines: 3,
              ),
            ],
          )
        else
          CupertinoFormSection.insetGrouped(
            header: const Text('Detalle del movimiento'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _motivo,
                  onValueChanged: (valor) {
                    if (valor != null) setState(() => _motivo = valor);
                  },
                  children: {
                    for (final texto in _motivos)
                      texto: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(texto),
                      ),
                  },
                ),
              ),
              CupertinoTextFormFieldRow(
                controller: _cantidadController,
                placeholder: 'Cantidad',
                prefix: const Text('Cantidad'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        CupertinoFormSection.insetGrouped(
          header: const Text('Responsable'),
          children: [
            CupertinoTextFormFieldRow(
              controller: _responsableController,
              placeholder: 'Nombre del responsable',
              prefix: const Text('Responsable'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoButton(
            color: TemaApp.colorExito,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: _registrando ? null : _registrar,
            child: _registrando
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Confirmar movimiento',
                    style: TextStyle(
                      fontSize: 16,
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
