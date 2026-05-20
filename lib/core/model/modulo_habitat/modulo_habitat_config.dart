class HabitatConfig {
  final String tipoHabitat;
  Map<String, dynamic> parametrosIdeales;
  int intervaloLimpieza;
  String preferencias;

  HabitatConfig({
    required this.tipoHabitat,
    required this.parametrosIdeales,
    required this.intervaloLimpieza,
    this.preferencias = '',
  });

  Map<String, dynamic> toJson() => {
    'tipoHabitat': tipoHabitat,
    'parametrosIdeales': parametrosIdeales,
    'intervaloLimpieza': intervaloLimpieza,
    'preferencias': preferencias,
  };

  factory HabitatConfig.fromJson(Map<String, dynamic> json) {
    return HabitatConfig(
      tipoHabitat: json['tipoHabitat'],
      parametrosIdeales: Map<String, dynamic>.from(json['parametrosIdeales']),
      intervaloLimpieza: json['intervaloLimpieza'],
      preferencias: json['preferencias'],
    );
  }
}
