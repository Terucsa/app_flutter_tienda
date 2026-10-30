import 'package:flutter/foundation.dart';

import '../../domain/movimiento.dart';
import '../../domain/registrar_movimiento_usecase.dart';

class MovimientosProvider extends ChangeNotifier {
  MovimientosProvider(this._useCase);

  final RegistrarMovimientoUseCase _useCase;

  bool _procesando = false;
  Movimiento? _ultimoMovimiento;

  bool get procesando => _procesando;
  Movimiento? get ultimoMovimiento => _ultimoMovimiento;

  Future<Movimiento> registrarEntradaSalida({
    required int productoId,
    required TipoMovimiento tipo,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    _procesando = true;
    notifyListeners();
    try {
      final Movimiento movimiento = await _useCase.registrarEntradaSalida(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        responsable: responsable,
      );
      _ultimoMovimiento = movimiento;
      return movimiento;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  Future<Movimiento> registrarAjuste({
    required int productoId,
    required int cantidadContada,
    required String justificacion,
    required String responsable,
  }) async {
    _procesando = true;
    notifyListeners();
    try {
      final Movimiento movimiento = await _useCase.registrarAjuste(
        productoId: productoId,
        cantidadContada: cantidadContada,
        justificacion: justificacion,
        responsable: responsable,
      );
      _ultimoMovimiento = movimiento;
      return movimiento;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }
}
