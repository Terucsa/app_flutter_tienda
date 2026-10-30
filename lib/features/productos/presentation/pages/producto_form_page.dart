import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../../core/errors/inventario_exception.dart';
import '../../domain/categoria.dart';
import '../../domain/producto.dart';
import '../providers/productos_provider.dart';

/// Formulario de creación y edición de productos.
class ProductoFormPage extends StatefulWidget {
  const ProductoFormPage({super.key, this.producto});

  final Producto? producto;

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioCompraController;
  late final TextEditingController _precioVentaController;
  late final TextEditingController _stockMinimoController;
  late final TextEditingController _stockInicialController;

  int? _categoriaId;
  String? _fotoPath;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final Producto? producto = widget.producto;
    _codigoController = TextEditingController(text: producto?.codigo ?? '');
    _nombreController = TextEditingController(text: producto?.nombre ?? '');
    _descripcionController =
        TextEditingController(text: producto?.descripcion ?? '');
    _precioCompraController =
        TextEditingController(text: producto == null ? '' : _numero(producto.precioCompra));
    _precioVentaController =
        TextEditingController(text: producto == null ? '' : _numero(producto.precioVenta));
    _stockMinimoController =
        TextEditingController(text: producto == null ? '' : '${producto.stockMinimo}');
    _stockInicialController = TextEditingController();
    _categoriaId = producto?.categoriaId;
    _fotoPath = producto?.fotoPath;
  }

  static String _numero(double valor) {
    return valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toString();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockMinimoController.dispose();
    _stockInicialController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarCategoria(List<Categoria> categorias) async {
    if (categorias.isEmpty) {
      await _mostrarError('No hay categorías registradas.');
      return;
    }
    int indiceInicial = categorias.indexWhere((c) => c.id == _categoriaId);
    if (indiceInicial < 0) indiceInicial = 0;

    final Categoria? seleccionada = await showCupertinoModalPopup<Categoria>(
      context: context,
      builder: (context) {
        return Container(
          height: 280,
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
                    'Seleccionar categoría',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(
                      categorias[indiceInicial],
                    ),
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
                  onSelectedItemChanged: (indice) => indiceInicial = indice,
                  children: categorias
                      .map((categoria) => Center(child: Text(categoria.nombre)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (seleccionada != null) {
      setState(() => _categoriaId = seleccionada.id);
    }
  }

  Future<void> _seleccionarFoto() async {
    final String? accion = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Fotografía del producto'),
        message: const Text('La fotografía es opcional.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('galeria'),
            child: const Text('Elegir de la galería'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('camara'),
            child: const Text('Tomar fotografía'),
          ),
          if (_fotoPath != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop('eliminar'),
              child: const Text('Eliminar fotografía'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );

    if (accion == null || !mounted) return;

    try {
      if (accion == 'eliminar') {
        setState(() => _fotoPath = null);
        return;
      }
      final ImagePicker picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(
        source: accion == 'camara'
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 80,
      );
      if (imagen != null) {
        setState(() => _fotoPath = imagen.path);
      }
    } catch (_) {
      if (mounted) {
        await _mostrarError('No se pudo acceder a la fotografía.');
      }
    }
  }

  Future<void> _guardar() async {
    final ProductosProvider provider = context.read<ProductosProvider>();
    final int? categoriaId = _categoriaId;
    final double? precioCompra =
        double.tryParse(_precioCompraController.text.trim());
    final double? precioVenta =
        double.tryParse(_precioVentaController.text.trim());
    final int? stockMinimo =
        int.tryParse(_stockMinimoController.text.trim());
    final int? stockInicial =
        int.tryParse(_stockInicialController.text.trim());

    if (categoriaId == null) {
      await _mostrarError('Seleccione una categoría.');
      return;
    }
    if (precioCompra == null || precioVenta == null) {
      await _mostrarError('Los precios deben ser valores numéricos.');
      return;
    }
    if (stockMinimo == null) {
      await _mostrarError('El stock mínimo debe ser un número entero.');
      return;
    }
    if (!_esEdicion && stockInicial == null) {
      await _mostrarError('El stock inicial debe ser un número entero.');
      return;
    }

    setState(() => _guardando = true);
    try {
      if (_esEdicion) {
        await provider.actualizarProducto(
          widget.producto!,
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          categoriaId: categoriaId,
          precioCompra: precioCompra,
          precioVenta: precioVenta,
          stockMinimo: stockMinimo,
          fotoPath: _fotoPath,
        );
      } else {
        await provider.crearProducto(
          codigo: _codigoController.text,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text,
          categoriaId: categoriaId,
          precioCompra: precioCompra,
          precioVenta: precioVenta,
          stockInicial: stockInicial!,
          stockMinimo: stockMinimo,
          fotoPath: _fotoPath,
        );
      }
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: TemaApp.colorExito,
              size: 44,
            ),
            content: Text(
              _esEdicion
                  ? 'Producto actualizado correctamente.'
                  : 'Producto registrado correctamente.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } on InventarioException catch (error) {
      if (mounted) await _mostrarError(error.mensaje);
    } catch (_) {
      if (mounted) await _mostrarError('No se pudo guardar el producto.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
    final ProductosProvider provider = context.watch<ProductosProvider>();
    final List<Categoria> categorias = provider.categorias;
    final String nombreCategoria = categorias
        .where((c) => c.id == _categoriaId)
        .map((c) => c.nombre)
        .firstOrNull ??
        'Seleccionar categoría';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('Datos del producto'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _codigoController,
                  placeholder: 'Ej. PROD-016',
                  prefix: const Text('Código'),
                  textInputAction: TextInputAction.next,
                ),
                CupertinoTextFormFieldRow(
                  controller: _nombreController,
                  placeholder: 'Nombre del producto',
                  prefix: const Text('Nombre'),
                  textInputAction: TextInputAction.next,
                ),
                CupertinoTextFormFieldRow(
                  controller: _descripcionController,
                  placeholder: 'Descripción (opcional)',
                  prefix: const Text('Descripción'),
                  maxLines: 3,
                ),
                CupertinoListTile(
                  title: const Text('Categoría'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombreCategoria,
                        style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                  onTap: () => _seleccionarCategoria(categorias),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('Precios'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _precioCompraController,
                  placeholder: '0.00',
                  prefix: const Text('Compra'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                CupertinoTextFormFieldRow(
                  controller: _precioVentaController,
                  placeholder: '0.00',
                  prefix: const Text('Venta'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('Existencias'),
              children: [
                if (!_esEdicion)
                  CupertinoTextFormFieldRow(
                    controller: _stockInicialController,
                    placeholder: '0',
                    prefix: const Text('Stock inicial'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                CupertinoTextFormFieldRow(
                  controller: _stockMinimoController,
                  placeholder: '0',
                  prefix: const Text('Stock mínimo'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('Fotografía (opcional)'),
              children: [
                CupertinoListTile(
                  title: const Text('Fotografía'),
                  subtitle: _fotoPath == null
                      ? const Text('Sin fotografía')
                      : const Text('Fotografía seleccionada'),
                  trailing: _fotoPath == null
                      ? const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.systemGrey,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_fotoPath!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                  onTap: _seleccionarFoto,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: TemaApp.colorPrimario,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Guardar producto',
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
