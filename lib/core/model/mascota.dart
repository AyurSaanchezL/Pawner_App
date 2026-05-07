class Mascota {
  String mascotaID;
  String nombre;
  String especie;
  String raza;
  String chip;
  double peso;
  DateTime fechaNacimiento;
  String genero; // 'Macho' o 'Hembra'
  bool esterilizado;
  String observaciones;
  String fotoUrl;
  String familiaID;

  Mascota({
    required this.mascotaID,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.chip,
    required this.peso,
    required this.fechaNacimiento,
    required this.genero,
    required this.esterilizado,
    required this.observaciones,
    required this.fotoUrl,
    required this.familiaID,
  });

  Map<String, dynamic> toJson() => {
        'mascotaID': mascotaID,
        'nombre': nombre,
        'especie': especie,
        'raza': raza,
        'chip': chip,
        'peso': peso,
        'fechaNacimiento': fechaNacimiento.toIso8601String(),
        'genero': genero,
        'esterilizado': esterilizado,
        'observaciones': observaciones,
        'fotoUrl': fotoUrl,
        'familiaID': familiaID,
      };

  factory Mascota.fromJson(Map<String, dynamic> json, String id) {
    return Mascota(
      mascotaID: id,
      nombre: json['nombre'] ?? '',
      especie: json['especie'] ?? '',
      raza: json['raza'] ?? '',
      chip: json['chip'] ?? '',
      peso: (json['peso'] ?? 0.0).toDouble(),
      fechaNacimiento: DateTime.parse(json['fechaNacimiento']),
      genero: json['genero'] ?? 'Macho',
      esterilizado: json['esterilizado'] ?? false,
      observaciones: json['observaciones'] ?? '',
      fotoUrl: json['fotoUrl'] ?? '',
      familiaID: json['familiaID'] ?? '',
    );
  }
}
