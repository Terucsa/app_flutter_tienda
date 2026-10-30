import '../../movimientos/domain/movimiento.dart';

class FiltroHistorial {
  const FiltroHistorial({
    this.productoId,
    this.tipo,
    this.desde,
    this.hasta,
  });

  final int? productoId;
  final TipoMovimiento? tipo;
  final DateTime? desde;
  final DateTime? hasta;

  FiltroHistorial copyWith({
    int? productoId,
    TipoMovimiento? tipo,
    DateTime? desde,
    DateTime? hasta,
  }) {
    return FiltroHistorial(
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
    );
  }
}
