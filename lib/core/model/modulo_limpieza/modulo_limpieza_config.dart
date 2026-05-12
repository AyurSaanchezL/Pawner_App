class ModuloLimpiezaConfig {
  List<String>
  tiposActivos; // Baño, Cepillado, Limpieza de orejas, Corte de uñas
  bool notificacionesActivas;
  Map<String, int> frecuenciaDiasRecomendados; // tipo -> días entre limpiezas
  bool enviarRecordatorios;

  ModuloLimpiezaConfig({
    required this.tiposActivos,
    required this.notificacionesActivas,
    required this.frecuenciaDiasRecomendados,
    this.enviarRecordatorios = true,
  });

  Map<String, dynamic> toMap() => {
    'tiposActivos': tiposActivos,
    'notificacionesActivas': notificacionesActivas,
    'frecuenciaDiasRecomendados': frecuenciaDiasRecomendados,
    'enviarRecordatorios': enviarRecordatorios,
  };

  factory ModuloLimpiezaConfig.fromMap(Map<String, dynamic> map) {
    final frecuencia =
        map['frecuenciaDiasRecomendados'] ??
        {
          'Baño': 30,
          'Cepillado': 2,
          'Limpieza de orejas': 14,
          'Corte de uñas': 30,
        };

    return ModuloLimpiezaConfig(
      tiposActivos: List<String>.from(
        map['tiposActivos'] ??
            ['Baño', 'Cepillado', 'Limpieza de orejas', 'Corte de uñas'],
      ),
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      frecuenciaDiasRecomendados: Map<String, int>.from(frecuencia),
      enviarRecordatorios: map['enviarRecordatorios'] ?? true,
    );
  }

  static Map<String, int> getDefaultFrecuencia(String especie) {
    // Frecuencias recomendadas por tipo de animal
    switch (especie.toLowerCase()) {
      case 'perro':
        return {
          'Baño': 30,
          'Cepillado': 2,
          'Limpieza de orejas': 14,
          'Corte de uñas': 30,
        };
      case 'gato':
        return {
          'Baño': 60, // Gatos se asean solos
          'Cepillado': 3,
          'Limpieza de orejas': 30,
          'Corte de uñas': 21,
        };
      case 'conejo':
        return {'Cepillado': 3, 'Limpieza de orejas': 30, 'Corte de uñas': 28};
      case 'hurón':
        return {'Baño': 14, 'Cepillado': 7, 'Limpieza de orejas': 14};
      default:
        return {'Baño': 30, 'Cepillado': 7, 'Limpieza de orejas': 30};
    }
  }
}
