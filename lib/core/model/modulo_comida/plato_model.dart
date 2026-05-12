class Plato {
  String id;
  String nombre;
  String tipo; // Seca, Húmeda, Natural, Suplemento
  List<String> ingredientes;
  String? preparacion;

  String? fotoUrl;
  bool esSugerencia;

  Plato({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.ingredientes,
    this.preparacion,
    this.fotoUrl,
    this.esSugerencia = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'ingredientes': ingredientes,
        'preparacion': preparacion,
        'fotoUrl': fotoUrl,
        'esSugerencia': esSugerencia,
      };

  factory Plato.fromMap(Map<String, dynamic> map, String documentId) {
    return Plato(
      id: documentId,
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'Seca',
      ingredientes: List<String>.from(map['ingredientes'] ?? []),
      preparacion: map['preparacion'],
      fotoUrl: map['fotoUrl'],
      esSugerencia: map['esSugerencia'] ?? false,
    );
  }
}
