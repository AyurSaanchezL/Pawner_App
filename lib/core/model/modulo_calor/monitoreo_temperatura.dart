class MonitoreoTemperatura {
  String id;
  String mascotaID;
  DateTime fecha;
  double temperaturaActual;
  double temperaturaOptimaMin;
  double temperaturaOptimaMax;
  String?
  tipo; // Lámara de calor, Almohadilla térmica, Calentador submergible, etc.
  bool dentibroPrendido;
  String? notas;

  MonitoreoTemperatura({
    required this.id,
    required this.mascotaID,
    required this.fecha,
    required this.temperaturaActual,
    required this.temperaturaOptimaMin,
    required this.temperaturaOptimaMax,
    this.tipo,
    this.dentibroPrendido = true,
    this.notas,
  });

  bool get temperaturaEnRango =>
      temperaturaActual >= temperaturaOptimaMin &&
      temperaturaActual <= temperaturaOptimaMax;

  Map<String, dynamic> toMap() => {
    'id': id,
    'mascotaID': mascotaID,
    'fecha': fecha.toIso8601String(),
    'temperaturaActual': temperaturaActual,
    'temperaturaOptimaMin': temperaturaOptimaMin,
    'temperaturaOptimaMax': temperaturaOptimaMax,
    'tipo': tipo,
    'dentibroPrendido': dentibroPrendido,
    'notas': notas,
  };

  factory MonitoreoTemperatura.fromMap(Map<String, dynamic> map, String id) {
    return MonitoreoTemperatura(
      id: id,
      mascotaID: map['mascotaID'] ?? '',
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'])
          : DateTime.now(),
      temperaturaActual: (map['temperaturaActual'] ?? 0).toDouble(),
      temperaturaOptimaMin: (map['temperaturaOptimaMin'] ?? 20).toDouble(),
      temperaturaOptimaMax: (map['temperaturaOptimaMax'] ?? 30).toDouble(),
      tipo: map['tipo'],
      dentibroPrendido: map['dentibroPrendido'] ?? true,
      notas: map['notas'],
    );
  }
}
