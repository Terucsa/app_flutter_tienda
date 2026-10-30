class Formatters {
  Formatters._();

  static String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');

  static String moneda(double valor) =>
      'Q ${valor.toStringAsFixed(2)}';

  static String fecha(DateTime fecha) =>
      '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year}';

  static String fechaHora(DateTime fechaHora) =>
      '${fecha(fechaHora)} ${hora(fechaHora)}';

  static String hora(DateTime fecha) =>
      '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';
}
