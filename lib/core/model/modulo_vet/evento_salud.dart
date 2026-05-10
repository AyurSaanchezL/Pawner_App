class EventoSalud {
  String id;
  String tipo;
  String descripcion;
  DateTime fecha;
  String? adjuntoUrl;
  DateTime? proximaDosis;

  EventoSalud({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.adjuntoUrl,
    this.proximaDosis,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tipo': tipo,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'adjuntoUrl': adjuntoUrl,
        'proximaDosis': proximaDosis?.toIso8601String(),
      };

  factory EventoSalud.fromMap(Map<String, dynamic> map, String documentId) {
    return EventoSalud(
      id: documentId,
      tipo: map['tipo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fecha: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      adjuntoUrl: map['adjuntoUrl'],
      proximaDosis: map['proximaDosis'] != null
          ? DateTime.parse(map['proximaDosis'])
          : null,
    );
  }
}
