class EjercicioAdiestramiento {
  String id;
  String mascotaID;
  String nombre;
  String descripcion;
  String dificultad; // Fácil, Medio, Difícil
  String objetivo; // Obediencia, Confianza, Relajación, etc.
  DateTime fechaInicio;
  DateTime? fechaTermino;
  bool completado;
  int progreso; // 0-100
  String? notas;

  EjercicioAdiestramiento({
    required this.id,
    required this.mascotaID,
    required this.nombre,
    required this.descripcion,
    required this.dificultad,
    required this.objetivo,
    required this.fechaInicio,
    this.fechaTermino,
    this.completado = false,
    this.progreso = 0,
    this.notas,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mascotaID': mascotaID,
    'nombre': nombre,
    'descripcion': descripcion,
    'dificultad': dificultad,
    'objetivo': objetivo,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaTermino': fechaTermino?.toIso8601String(),
    'completado': completado,
    'progreso': progreso,
    'notas': notas,
  };

  factory EjercicioAdiestramiento.fromMap(Map<String, dynamic> map, String id) {
    return EjercicioAdiestramiento(
      id: id,
      mascotaID: map['mascotaID'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      dificultad: map['dificultad'] ?? 'Medio',
      objetivo: map['objetivo'] ?? 'General',
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.parse(map['fechaInicio'])
          : DateTime.now(),
      fechaTermino: map['fechaTermino'] != null
          ? DateTime.parse(map['fechaTermino'])
          : null,
      completado: map['completado'] ?? false,
      progreso: map['progreso'] ?? 0,
      notas: map['notas'],
    );
  }
}
