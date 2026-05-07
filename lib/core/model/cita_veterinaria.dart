class CitaVeterinaria {
  String id;
  DateTime fecha;
  String motivo;
  String? veterinario;
  String? notas;
  bool notificacionActiva;
  int? idNotificacion;

  CitaVeterinaria({
    required this.id,
    required this.fecha,
    required this.motivo,
    this.veterinario,
    this.notas,
    this.notificacionActiva = true,
    this.idNotificacion,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'motivo': motivo,
        'veterinario': veterinario,
        'notas': notas,
        'notificacionActiva': notificacionActiva,
        'idNotificacion': idNotificacion,
      };

  factory CitaVeterinaria.fromMap(Map<String, dynamic> map, String documentId) {
    return CitaVeterinaria(
      id: documentId,
      fecha: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      motivo: map['motivo'] ?? '',
      veterinario: map['veterinario'],
      notas: map['notas'],
      notificacionActiva: map['notificacionActiva'] ?? true,
      idNotificacion: map['idNotificacion'],
    );
  }
}
