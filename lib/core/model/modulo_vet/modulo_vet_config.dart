class ModuloVetConfig {
  List<String> alergias;
  // Cada vet: {'nombre': '', 'telefono': '', 'numColegiado': ''}
  List<Map<String, String>> veterinarios;
  String? seguroMedico;
  String? telUrgencias;

  ModuloVetConfig({
    this.alergias = const [],
    this.veterinarios = const [],
    this.seguroMedico,
    this.telUrgencias,
  });

  Map<String, dynamic> toMap() => {
        'alergias': alergias,
        'veterinarios': veterinarios,
        'seguroMedico': seguroMedico,
        'telUrgencias': telUrgencias,
      };

  factory ModuloVetConfig.fromMap(Map<String, dynamic> map) {
    // Nueva estructura
    final rawList = map['veterinarios'] as List?;
    List<Map<String, String>> vetes;

    if (rawList != null && rawList.isNotEmpty) {
      vetes = rawList
          .map((v) => Map<String, String>.from((v as Map).map(
                (k, val) => MapEntry(k.toString(), val?.toString() ?? ''),
              )))
          .toList();
    } else {
      // Migración desde estructura antigua de un solo vet
      final nombre = (map['nombreVete'] as String?) ?? '';
      vetes = nombre.isNotEmpty
          ? [
              {
                'nombre': nombre,
                'telefono': (map['telVete'] as String?) ?? '',
                'numColegiado': (map['numColegiado'] as String?) ?? '',
              }
            ]
          : [];
    }

    return ModuloVetConfig(
      alergias: List<String>.from(map['alergias'] ?? []),
      veterinarios: vetes,
      seguroMedico: map['seguroMedico'],
      telUrgencias: map['telUrgencias'],
    );
  }
}
