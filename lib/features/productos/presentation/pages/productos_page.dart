import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../app/tema.dart';
import '../../domain/producto.dart';
import '../providers/productos_provider.dart';
import '../widgets/producto_card.dart';
import 'producto_detalle_page.dart';
import 'producto_form_page.dart';

/// Listado general de productos con búsqueda y filtros.
/// Aquí se listan productos activos e inactivos.
class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargar();
    });
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

  void _irCrear() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const ProductoFormPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductosProvider provider = context.watch<ProductosProvider>();
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Productos'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _irCrear,
          child: const Text(
            'Crear',
            style: TextStyle(
              color: TemaApp.colorPrimario,
              fontSize: 16,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CupertinoSearchTextField(
                placeholder: 'Buscar por código o nombre',
                onChanged: provider.actualizarBusqueda,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSlidingSegmentedControl<FiltroEstadoProducto>(
                groupValue: provider.filtroEstado,
                onValueChanged: (filtro) {
                  if (filtro != null) {
                    provider.cambiarFiltroEstado(filtro);
                  }
                },
                children: const {
                  FiltroEstadoProducto.todos: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Todos'),
                  ),
                  FiltroEstadoProducto.activos: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Activos'),
                  ),
                  FiltroEstadoProducto.inactivos: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Inactivos'),
                  ),
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.cargando && provider.todosLosProductos.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : provider.productosFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron productos',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: provider.productosFiltrados.length,
                          itemBuilder: (context, indice) {
                            final Producto producto =
                                provider.productosFiltrados[indice];
                            return ProductoCard(
                              producto: producto,
                              onDetalle: () => _irDetalle(producto),
                              onEditar: () => _irEditar(producto),
                              onAlternarActivo: () => context
                                  .read<ProductosProvider>()
                                  .alternarActivo(producto),
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
