class ReporteInventario {
  const ReporteInventario({
    required this.valorTotal,
    required this.totalProductosActivos,
    required this.alertasStockBajo,
  });

  final double valorTotal;
  final int totalProductosActivos;
  final int alertasStockBajo;
}
