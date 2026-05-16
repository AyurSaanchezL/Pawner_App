class Recordatorio {
  String recordatorioID;
  String titulo;
  String? descripcion;
  DateTime fechaHora;
  bool completado;
  String familiaID;
  String? mascotaID;
  String? moduloID;

  Recordatorio({
    required this.recordatorioID,
    required this.titulo,
    this.descripcion,
    required this.fechaHora,
    this.completado = false,
    required this.familiaID,
    this.mascotaID,
    this.moduloID,
  });

  Map<String, dynamic> toJson() => {
    'recordatorioID': recordatorioID,
    'titulo': titulo,
    'descripcion': descripcion,
    'fechaHora': fechaHora.toIso8601String(),
    'completado': completado,
    'familiaID': familiaID,
    'mascotaID': mascotaID,
    'moduloID': moduloID,
  };

  factory Recordatorio.fromJson(Map<String, dynamic> map, String id) {
    return Recordatorio(
      recordatorioID: id,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'],
      fechaHora: DateTime.parse(
        map['fechaHora'] ?? DateTime.now().toIso8601String(),
      ),
      completado: map['completado'] ?? false,
      familiaID: map['familiaID'] ?? '',
      mascotaID: map['mascotaID'],
      moduloID: map['moduloID'],
    );
  }
}
