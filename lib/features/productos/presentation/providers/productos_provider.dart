import 'package:flutter/foundation.dart';

import '../../domain/categoria.dart';
import '../../domain/producto.dart';
import '../../domain/producto_repository.dart';
import '../../domain/producto_usecases.dart';

enum FiltroEstadoProducto { todos, activos, inactivos }

class ProductosProvider extends ChangeNotifier {
  ProductosProvider(this._repository, this._useCases);

  final ProductoRepository _repository;
  final ProductoUseCases _useCases;

  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  String _busqueda = '';
  FiltroEstadoProducto _filtroEstado = FiltroEstadoProducto.todos;
  bool _cargando = false;

  List<Producto> get todosLosProductos => List.unmodifiable(_productos);
  List<Categoria> get categorias => List.unmodifiable(_categorias);
  String get busqueda => _busqueda;
  FiltroEstadoProducto get filtroEstado => _filtroEstado;
  bool get cargando => _cargando;

  List<Producto> get productosFiltrados {
    return _productos.where((producto) {
      if (_filtroEstado == FiltroEstadoProducto.activos && !producto.activo) {
        return false;
      }
      if (_filtroEstado == FiltroEstadoProducto.inactivos && producto.activo) {
        return false;
      }
      if (_busqueda.trim().isEmpty) return true;
      final String texto = _busqueda.trim().toLowerCase();
      return producto.codigo.toLowerCase().contains(texto) ||
          producto.nombre.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _repository.obtenerProductos(),
        _repository.obtenerCategorias(),
      ]);
      _productos = resultados[0] as List<Producto>;
      _categorias = resultados[1] as List<Categoria>;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> actualizarBusqueda(String valor) async {
    _busqueda = valor;
    notifyListeners();
  }

  void cambiarFiltroEstado(FiltroEstadoProducto filtro) {
    _filtroEstado = filtro;
    notifyListeners();
  }

  Future<Producto?> obtenerProducto(int id) async {
    final Producto? local =
        _productos.where((p) => p.id == id).firstOrNull;
    if (local != null) return local;
    return _repository.obtenerPorId(id);
  }

  Future<void> crearProducto({
    required String codigo,
    required String nombre,
    String? descripcion,
    required int categoriaId,
    required double precioCompra,
    required double precioVenta,
    required int stockInicial,
    required int stockMinimo,
    String? fotoPath,
  }) async {
    await _useCases.crearProducto(
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      categoriaId: categoriaId,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      stockInicial: stockInicial,
      stockMinimo: stockMinimo,
      fotoPath: fotoPath,
    );
    await cargar();
  }

  Future<void> actualizarProducto(
    Producto productoActual, {
    required String codigo,
    required String nombre,
    String? descripcion,
    required int categoriaId,
    required double precioCompra,
    required double precioVenta,
    required int stockMinimo,
    String? fotoPath,
  }) async {
    await _useCases.actualizarProducto(
      productoActual,
      codigo: codigo,
      nombre: nombre,
      descripcion: descripcion,
      categoriaId: categoriaId,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      stockMinimo: stockMinimo,
      fotoPath: fotoPath,
    );
    await cargar();
  }

  Future<void> alternarActivo(Producto producto) async {
    await _useCases.cambiarEstado(producto.id!, !producto.activo);
    await cargar();
  }
}
