class ResumenInicio {
  const ResumenInicio({
    required this.totalProductos,
    required this.productosActivos,
    required this.alertasStockBajo,
    required this.valorInventario,
  });

  final int totalProductos;
  final int productosActivos;
  final int alertasStockBajo;
  final double valorInventario;
}
