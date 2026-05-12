class PaseoConfig {
  int numPaseosObjetivo;
  int intervaloRecordatoriosHoras; // Intervalo en horas para recordatorios

  PaseoConfig(this.numPaseosObjetivo, {this.intervaloRecordatoriosHoras = 4});

  Map<String, dynamic> toJson() => {
    'numPaseosObjetivo': numPaseosObjetivo,
    'intervaloRecordatoriosHoras': intervaloRecordatoriosHoras,
  };

  factory PaseoConfig.fromJson(Map<String, dynamic> json) {
    return PaseoConfig(
      json['numPaseosObjetivo'],
      intervaloRecordatoriosHoras: json['intervaloRecordatoriosHoras'] ?? 4,
    );
  }
}
