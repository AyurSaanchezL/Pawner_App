class ModuloComidaConfig {
  List<String> categoriasActivas;
  bool notificacionesActivas;
  int umbralHoras;

  ModuloComidaConfig({
    required this.categoriasActivas,
    required this.notificacionesActivas,
    required this.umbralHoras,
  });

  Map<String, dynamic> toMap() => {
        'categoriasActivas': categoriasActivas,
        'notificacionesActivas': notificacionesActivas,
        'umbralHoras': umbralHoras,
      };

  factory ModuloComidaConfig.fromMap(Map<String, dynamic> map) {
    return ModuloComidaConfig(
      categoriasActivas: List<String>.from(map['categoriasActivas'] ?? ['Seca', 'Húmeda', 'Natural']),
      notificacionesActivas: map['notificacionesActivas'] ?? true,
      umbralHoras: map['umbralHoras'] ?? 1,
    );
  }
}
