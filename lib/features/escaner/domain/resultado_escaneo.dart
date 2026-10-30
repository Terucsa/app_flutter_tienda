import '../../productos/domain/producto.dart';

/// Resultado de un escaneo o búsqueda manual de un código.
class ResultadoEscaneo {
  const ResultadoEscaneo.encontrado(this.producto)
      : encontrado = true,
        codigoBuscado = null;

  const ResultadoEscaneo.noEncontrado(this.codigoBuscado)
      : encontrado = false,
        producto = null;

  final bool encontrado;
  final Producto? producto;
  final String? codigoBuscado;
}
