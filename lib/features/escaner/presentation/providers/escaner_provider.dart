import 'package:flutter/foundation.dart';

import '../../../productos/domain/producto.dart';
import '../../domain/escaner_repository.dart';
import '../../domain/resultado_escaneo.dart';

class EscanerProvider extends ChangeNotifier {
  EscanerProvider(this._repository);

  final EscanerRepository _repository;

  bool _buscando = false;
  ResultadoEscaneo? _resultado;
  List<Producto> _resultadosManuales = [];

  bool get buscando => _buscando;
  ResultadoEscaneo? get resultado => _resultado;
  List<Producto> get resultadosManuales => List.unmodifiable(_resultadosManuales);

  Future<ResultadoEscaneo> buscarPorCodigo(String codigo) async {
    _buscando = true;
    notifyListeners();
    try {
      _resultado = await _repository.buscarPorCodigo(codigo);
      return _resultado!;
    } finally {
      _buscando = false;
      notifyListeners();
    }
  }

  Future<void> buscarManual(String texto) async {
    if (texto.trim().isEmpty) {
      _resultadosManuales = [];
      notifyListeners();
      return;
    }
    _buscando = true;
    notifyListeners();
    try {
      _resultadosManuales = await _repository.buscarManual(texto);
    } finally {
      _buscando = false;
      notifyListeners();
    }
  }

  void limpiar() {
    _resultado = null;
    _resultadosManuales = [];
    notifyListeners();
  }
}
