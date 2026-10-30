import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../../../core/utils/formatters.dart';
import '../../../escaner/presentation/pages/escaner_page.dart';
import '../../../productos/domain/producto.dart';
import '../../../productos/presentation/pages/producto_detalle_page.dart';
import '../../../productos/presentation/pages/producto_form_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../../productos/presentation/providers/productos_provider.dart';
import '../../../productos/presentation/widgets/producto_card.dart';
import '../../../reportes/presentation/pages/historial_reportes_page.dart';
import '../providers/inicio_provider.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  String _busquedaCodigo = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InicioProvider>().cargarResumen();
      context.read<ProductosProvider>().cargar();
    });
  }

  List<Producto> _productosVisibles(List<Producto> todos) {
    final String texto = _busquedaCodigo.trim().toLowerCase();
    return todos.where((producto) {
      if (!producto.activo) return false;
      if (texto.isEmpty) return true;
      return producto.codigo.toLowerCase().contains(texto);
    }).toList();
  }

  void _irDetalle(Producto producto) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ProductoDetallePage(productoId: producto.id!),
      ),
    );
  }

  void _irEditar(Producto producto) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ProductoFormPage(producto: producto),
      ),
    );
  }

  Future<void> _alternarActivo(Producto producto) async {
    final ProductosProvider productosProvider =
        context.read<ProductosProvider>();
    await productosProvider.alternarActivo(producto);
    if (mounted) {
      context.read<InicioProvider>().cargarResumen();
    }
  }

  void _irCrearProducto() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const ProductoFormPage(),
      ),
    );
  }

  void _irProductos() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => const ProductosPage()),
    );
  }

  void _irEscaner() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => const EscanerPage()),
    );
  }

  void _irHistorial() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const HistorialReportesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Inventario Inteligente'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _irHistorial,
          child: const Icon(
            CupertinoIcons.chart_bar_alt_fill,
            color: TemaApp.colorPrimario,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: CupertinoSearchTextField(
                placeholder: 'Buscar por código (activos)',
                onChanged: (valor) => setState(() => _busquedaCodigo = valor),
              ),
            ),
            _ResumenInicio(onTap: _irHistorial),
            _BotonesAccesoRapido(
              onCrear: _irCrearProducto,
              onProductos: _irProductos,
              onEscanear: _irEscaner,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Productos activos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<ProductosProvider>(
                builder: (context, productosProvider, _) {
                  if (productosProvider.cargando &&
                      productosProvider.todosLosProductos.isEmpty) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  final List<Producto> visibles =
                      _productosVisibles(productosProvider.todosLosProductos);
                  if (visibles.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay productos activos',
                        style: TextStyle(color: CupertinoColors.secondaryLabel),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: visibles.length,
                    itemBuilder: (context, indice) {
                      final Producto producto = visibles[indice];
                      return ProductoCard(
                        producto: producto,
                        onDetalle: () => _irDetalle(producto),
                        onEditar: () => _irEditar(producto),
                        onAlternarActivo: () => _alternarActivo(producto),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenInicio extends StatelessWidget {
  const _ResumenInicio({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Consumer<InicioProvider>(
      builder: (context, inicioProvider, _) {
        final resumen = inicioProvider.resumen;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaApp.colorTarjeta,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
            child: resumen == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.money_dollar_circle,
                            color: TemaApp.colorExito,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Valor del inventario: '
                            '${Formatters.moneda(resumen.valorInventario)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _DatoResumen(
                            icono: CupertinoIcons.cube_box,
                            valor: '${resumen.productosActivos}',
                            etiqueta: 'activos',
                          ),
                          _DatoResumen(
                            icono: CupertinoIcons.cube_box_fill,
                            valor: '${resumen.totalProductos}',
                            etiqueta: 'registrados',
                          ),
                          _DatoResumen(
                            icono: CupertinoIcons.exclamationmark_triangle,
                            valor: '${resumen.alertasStockBajo}',
                            etiqueta: 'alertas',
                            color: resumen.alertasStockBajo > 0
                                ? TemaApp.colorPeligro
                                : TemaApp.colorExito,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DatoResumen extends StatelessWidget {
  const _DatoResumen({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color = CupertinoColors.label,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonesAccesoRapido extends StatelessWidget {
  const _BotonesAccesoRapido({
    required this.onCrear,
    required this.onProductos,
    required this.onEscanear,
  });

  final VoidCallback onCrear;
  final VoidCallback onProductos;
  final VoidCallback onEscanear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _BotonRapido(
              icono: CupertinoIcons.add_circled,
              texto: 'Crear producto',
              onPressed: onCrear,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BotonRapido(
              icono: CupertinoIcons.list_bullet,
              texto: 'Todos los productos',
              onPressed: onProductos,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BotonRapido(
              icono: CupertinoIcons.qrcode_viewfinder,
              texto: 'Escanear QR',
              onPressed: onEscanear,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRapido extends StatelessWidget {
  const _BotonRapido({
    required this.icono,
    required this.texto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      color: TemaApp.colorPrimario,
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: CupertinoColors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: CupertinoColors.white),
          ),
        ],
      ),
    );
  }
}
