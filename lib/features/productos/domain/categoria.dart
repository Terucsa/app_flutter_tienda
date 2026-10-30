class Categoria {
  const Categoria({this.id, required this.nombre});

  final int? id;
  final String nombre;

  factory Categoria.fromMap(Map<String, dynamic> mapa) {
    return Categoria(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() => {'nombre': nombre};

  @override
  String toString() => nombre;
}
