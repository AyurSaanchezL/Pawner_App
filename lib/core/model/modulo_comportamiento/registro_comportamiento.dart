class RegistroComportamiento {
  String id;
  String mascotaID;
  DateTime fecha;
  String tipo; // Positivo, Negativo, Neutral
  String descripcion;
  String categoria; // Agresión, Ansiedad, Juego, Obediencia, etc.
  double? intensidad; // 1-10
  String? detonante; // Qué causó el comportamiento
  String? resolucion; // Cómo se resolvió
  String? notas;

  RegistroComportamiento({
    required this.id,
    required this.mascotaID,
    required this.fecha,
    required this.tipo,
    required this.descripcion,
    required this.categoria,
    this.intensidad,
    this.detonante,
    this.resolucion,
    this.notas,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mascotaID': mascotaID,
    'fecha': fecha.toIso8601String(),
    'tipo': tipo,
    'descripcion': descripcion,
    'categoria': categoria,
    'intensidad': intensidad,
    'detonante': detonante,
    'resolucion': resolucion,
    'notas': notas,
  };

  factory RegistroComportamiento.fromMap(Map<String, dynamic> map, String id) {
    return RegistroComportamiento(
      id: id,
      mascotaID: map['mascotaID'] ?? '',
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'])
          : DateTime.now(),
      tipo: map['tipo'] ?? 'Neutral',
      descripcion: map['descripcion'] ?? '',
      categoria: map['categoria'] ?? 'General',
      intensidad: map['intensidad']?.toDouble(),
      detonante: map['detonante'],
      resolucion: map['resolucion'],
      notas: map['notas'],
    );
  }
}
