enum TipoMovimiento {
  entrada('ENTRADA', 'Entrada'),
  salida('SALIDA', 'Salida'),
  ajuste('AJUSTE', 'Ajuste');

  const TipoMovimiento(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static TipoMovimiento desdeCodigo(String? codigo) {
    return TipoMovimiento.values.firstWhere(
      (tipo) => tipo.codigo == codigo,
      orElse: () => TipoMovimiento.entrada,
    );
  }
}

class Movimiento {
  const Movimiento({
    this.id,
    required this.productoId,
    this.productoNombre,
    this.productoCodigo,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockResultante,
    required this.motivo,
    required this.responsable,
    required this.fechaHora,
  });

  final int? id;
  final int productoId;
  final String? productoNombre;
  final String? productoCodigo;
  final TipoMovimiento tipo;
  final int cantidad;
  final int stockAnterior;
  final int stockResultante;
  final String motivo;
  final String responsable;
  final DateTime fechaHora;

  factory Movimiento.fromMap(Map<String, dynamic> mapa) {
    return Movimiento(
      id: mapa['id'] as int?,
      productoId: mapa['producto_id'] as int,
      productoNombre: mapa['producto_nombre'] as String?,
      productoCodigo: mapa['producto_codigo'] as String?,
      tipo: TipoMovimiento.desdeCodigo(mapa['tipo'] as String?),
      cantidad: mapa['cantidad'] as int,
      stockAnterior: mapa['stock_anterior'] as int,
      stockResultante: mapa['stock_resultante'] as int,
      motivo: mapa['motivo'] as String,
      responsable: mapa['responsable'] as String,
      fechaHora: DateTime.parse(mapa['fecha_hora'] as String),
    );
  }
}
