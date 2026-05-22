class RegistroBano {
  String id;
  DateTime fecha;
  int calidad;
  String? notas;
  String? urlFoto;

  RegistroBano({
    required this.id,
    required this.fecha,
    required this.calidad,
    this.notas,
    this.urlFoto,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'fecha': fecha.toIso8601String(),
      'calidad': calidad,
    };
    if (notas != null) map['notas'] = notas;
    if (urlFoto != null) map['urlFoto'] = urlFoto;
    return map;
  }

  factory RegistroBano.fromMap(Map<String, dynamic> map, String documentId) {
    return RegistroBano(
      id: documentId,
      fecha: DateTime.parse(map['fecha'] ?? DateTime.now().toIso8601String()),
      calidad: map['calidad'] ?? 1,
      notas: map['notas'] as String?,
      urlFoto: map['urlFoto'] as String?,
    );
  }
}
