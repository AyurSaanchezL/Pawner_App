class SesionLimpieza {
  String id;
  String mascotaID;
  String tipo; // Baño, Cepillado, Limpieza de orejas, Corte de uñas, etc.
  DateTime fecha;
  String? notas;
  double? duracionMinutos;
  bool completada;
  String? productoUsado; // Champú, cortaúñas, etc.

  SesionLimpieza({
    required this.id,
    required this.mascotaID,
    required this.tipo,
    required this.fecha,
    this.notas,
    this.duracionMinutos,
    this.completada = false,
    this.productoUsado,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mascotaID': mascotaID,
    'tipo': tipo,
    'fecha': fecha.toIso8601String(),
    'notas': notas,
    'duracionMinutos': duracionMinutos,
    'completada': completada,
    'productoUsado': productoUsado,
  };

  factory SesionLimpieza.fromMap(Map<String, dynamic> map, String id) {
    return SesionLimpieza(
      id: id,
      mascotaID: map['mascotaID'] ?? '',
      tipo: map['tipo'] ?? 'Baño',
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'])
          : DateTime.now(),
      notas: map['notas'],
      duracionMinutos: map['duracionMinutos']?.toDouble(),
      completada: map['completada'] ?? false,
      productoUsado: map['productoUsado'],
    );
  }
}
