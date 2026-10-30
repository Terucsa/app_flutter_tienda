class InventarioException implements Exception {
  const InventarioException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
