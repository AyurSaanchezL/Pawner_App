class HorarioComida {
  String id;
  String hora; // HH:mm
  int idNotificacion;
  bool activo;
  String? platoId;

  HorarioComida({
    required this.id,
    required this.hora,
    required this.idNotificacion,
    required this.activo,
    this.platoId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'hora': hora,
        'idNotificacion': idNotificacion,
        'activo': activo,
        'platoId': platoId,
      };

  factory HorarioComida.fromMap(Map<String, dynamic> map, String documentId) {
    return HorarioComida(
      id: documentId,
      hora: map['hora'] ?? '08:00',
      idNotificacion: map['idNotificacion'] ?? 0,
      activo: map['activo'] ?? true,
      platoId: map['platoId'],
    );
  }
}
