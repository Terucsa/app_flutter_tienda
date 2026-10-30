import 'package:flutter/foundation.dart';

import '../../domain/inicio_repository.dart';
import '../../domain/resumen_inicio.dart';

class InicioProvider extends ChangeNotifier {
  InicioProvider(this._repository);

  final InicioRepository _repository;

  ResumenInicio? _resumen;
  bool _cargando = false;

  ResumenInicio? get resumen => _resumen;
  bool get cargando => _cargando;

  Future<void> cargarResumen() async {
    _cargando = true;
    notifyListeners();
    try {
      _resumen = await _repository.obtenerResumen();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
