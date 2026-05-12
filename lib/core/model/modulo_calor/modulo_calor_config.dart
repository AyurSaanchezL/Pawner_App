class ModuloCalorConfig {
  double temperaturaOptimaMin;
  double temperaturaOptimaMax;
  String tipo; // Lámara de calor, Almohadilla térmica, Calentador submergible
  bool notificacionesActivas;
  bool monitoreoActivo;

  ModuloCalorConfig({
    required this.temperaturaOptimaMin,
    required this.temperaturaOptimaMax,
    required this.tipo,
    this.notificacionesActivas = true,
    this.monitoreoActivo = true,
  });

  Map<String, dynamic> toMap() => {
    'temperaturaOptimaMin': temperaturaOptimaMin,
    'temperaturaOptimaMax': temperaturaOptimaMax,
    'tipo': tipo,
    'notificacionesActivas': notificacionesActivas,
    'monitoreoActivo': monitoreoActivo,
  };

  factory ModuloCalorConfig.fromMap(Map<String, dynamic> map) {
    return ModuloCalorConfig(
      temperaturaOptimaMin: (map['temperaturaOptimaMin'] ?? 25).toDouble(),
      temperaturaOptimaMax: (map['temperaturaOptimaMax'] ?? 30).toDouble(),
      tipo: map['tipo'] ?? 'Lámara de calor',
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      monitoreoActivo: map['monitoreoActivo'] ?? true,
    );
  }

  // Rangos recomendados por especie
  static ModuloCalorConfig getDefaultForSpecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'tortuga':
        return ModuloCalorConfig(
          temperaturaOptimaMin: 25,
          temperaturaOptimaMax: 30,
          tipo: 'Lámara de calor',
        );
      case 'serpiente':
        return ModuloCalorConfig(
          temperaturaOptimaMin: 26,
          temperaturaOptimaMax: 32,
          tipo: 'Almohadilla térmica',
        );
      case 'lagarto':
        return ModuloCalorConfig(
          temperaturaOptimaMin: 24,
          temperaturaOptimaMax: 30,
          tipo: 'Lámara de calor',
        );
      case 'cocodrilo':
        return ModuloCalorConfig(
          temperaturaOptimaMin: 28,
          temperaturaOptimaMax: 35,
          tipo: 'Lámara de calor',
        );
      case 'pez':
      case 'peces':
        return ModuloCalorConfig(
          temperaturaOptimaMin: 22,
          temperaturaOptimaMax: 28,
          tipo: 'Calentador submergible',
        );
      default:
        return ModuloCalorConfig(
          temperaturaOptimaMin: 20,
          temperaturaOptimaMax: 28,
          tipo: 'Lámara de calor',
        );
    }
  }
}
