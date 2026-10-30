class Producto {
  const Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
    this.categoriaNombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    required this.stockMinimo,
    this.fotoPath,
    required this.activo,
    required this.fechaCreacion,
  });

  final int? id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final int categoriaId;
  final String? categoriaNombre;
  final double precioCompra;
  final double precioVenta;
  final int stock;
  final int stockMinimo;
  final String? fotoPath;
  final bool activo;
  final DateTime fechaCreacion;

  bool get stockBajo => stock <= stockMinimo;

  factory Producto.fromMap(Map<String, dynamic> mapa) {
    return Producto(
      id: mapa['id'] as int?,
      codigo: mapa['codigo'] as String,
      nombre: mapa['nombre'] as String,
      descripcion: mapa['descripcion'] as String?,
      categoriaId: mapa['categoria_id'] as int,
      categoriaNombre: mapa['categoria_nombre'] as String?,
      precioCompra: (mapa['precio_compra'] as num).toDouble(),
      precioVenta: (mapa['precio_venta'] as num).toDouble(),
      stock: mapa['stock_actual'] as int,
      stockMinimo: mapa['stock_minimo'] as int,
      fotoPath: mapa['foto_path'] as String?,
      activo: (mapa['activo'] as int) == 1,
      fechaCreacion: DateTime.parse(mapa['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock_actual': stock,
      'stock_minimo': stockMinimo,
      'foto_path': fotoPath,
      'activo': activo ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    int? categoriaId,
    double? precioCompra,
    double? precioVenta,
    int? stock,
    int? stockMinimo,
    String? fotoPath,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      fotoPath: fotoPath ?? this.fotoPath,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
