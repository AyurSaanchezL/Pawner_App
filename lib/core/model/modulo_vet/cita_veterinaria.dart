class CitaVeterinaria {
  String id;
  DateTime fecha;
  String motivo;
  String? veterinario;
  String? notas;
  bool completada;
  bool notificacionActiva;
  int? idNotificacion;
  String? recordatorioID;
  DateTime? notifFechaHora; // cuándo se dispara realmente la notificación

  CitaVeterinaria({
    required this.id,
    required this.fecha,
    required this.motivo,
    this.veterinario,
    this.notas,
    this.completada = false,
    this.notificacionActiva = true,
    this.idNotificacion,
    this.recordatorioID,
    this.notifFechaHora,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'motivo': motivo,
        'veterinario': veterinario,
        'notas': notas,
        'completada': completada,
        'notificacionActiva': notificacionActiva,
        'idNotificacion': idNotificacion,
        'recordatorioID': recordatorioID,
        'notifFechaHora': notifFechaHora?.toIso8601String(),
      };

  factory CitaVeterinaria.fromMap(Map<String, dynamic> map, String documentId) {
    return CitaVeterinaria(
      id: documentId,
      fecha: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      motivo: map['motivo'] ?? '',
      veterinario: map['veterinario'],
      notas: map['notas'],
      completada: map['completada'] ?? false,
      notificacionActiva: map['notificacionActiva'] ?? true,
      idNotificacion: map['idNotificacion'],
      recordatorioID: map['recordatorioID'],
      notifFechaHora: map['notifFechaHora'] != null ? DateTime.parse(map['notifFechaHora']) : null,
    );
  }
}
