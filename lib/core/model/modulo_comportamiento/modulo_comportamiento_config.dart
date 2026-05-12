class ModuloComportamientoConfig {
  List<String> categoriasActivas; // Agresión, Ansiedad, Juego, Obediencia, etc.
  bool notificacionesActivas;
  bool registroAutomatico;
  int diasHistorialGuardado; // Cuántos días guardar historial

  ModuloComportamientoConfig({
    required this.categoriasActivas,
    required this.notificacionesActivas,
    this.registroAutomatico = true,
    this.diasHistorialGuardado = 365,
  });

  Map<String, dynamic> toMap() => {
    'categoriasActivas': categoriasActivas,
    'notificacionesActivas': notificacionesActivas,
    'registroAutomatico': registroAutomatico,
    'diasHistorialGuardado': diasHistorialGuardado,
  };

  factory ModuloComportamientoConfig.fromMap(Map<String, dynamic> map) {
    return ModuloComportamientoConfig(
      categoriasActivas: List<String>.from(
        map['categoriasActivas'] ??
            [
              'Agresión',
              'Ansiedad',
              'Juego',
              'Obediencia',
              'Socialización',
              'Miedos',
            ],
      ),
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      registroAutomatico: map['registroAutomatico'] ?? true,
      diasHistorialGuardado: map['diasHistorialGuardado'] ?? 365,
    );
  }

  static List<String> getCategoriasPorEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'perro':
        return [
          'Agresión',
          'Ansiedad',
          'Juego',
          'Obediencia',
          'Socialización',
          'Miedos',
          'Destrozo',
          'Ladridos',
        ];
      case 'gato':
        return [
          'Agresión',
          'Ansiedad',
          'Juego',
          'Arañazos',
          'Miedos',
          'Comportamiento territorial',
          'Movimiento excesivo',
        ];
      case 'pájaro':
        return [
          'Agresión',
          'Ansiedad',
          'Vocalizaciones',
          'Arrancarse plumas',
          'Juego',
          'Socialización',
        ];
      case 'conejo':
        return [
          'Agresión',
          'Ansiedad',
          'Juego',
          'Apatía',
          'Miedos',
          'Comportamiento territorial',
        ];
      default:
        return [
          'Positivo',
          'Negativo',
          'Neutral',
          'Miedos',
          'Agresión',
          'Juego',
        ];
    }
  }
}
