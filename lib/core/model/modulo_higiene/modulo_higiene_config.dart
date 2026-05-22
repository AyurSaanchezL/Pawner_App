class ModuloHigieneConfig {
  bool configurado;
  int frecuenciaDias;
  bool notificacionActiva;
  int? idNotificacion;
  DateTime? proximoAviso;
  List<String> utensilios;
  String? instrucciones;

  ModuloHigieneConfig({
    this.configurado = false,
    required this.frecuenciaDias,
    this.notificacionActiva = false,
    this.idNotificacion,
    this.proximoAviso,
    this.utensilios = const [],
    this.instrucciones,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'configurado': configurado,
      'frecuenciaDias': frecuenciaDias,
      'notificacionActiva': notificacionActiva,
      'utensilios': utensilios,
    };
    if (idNotificacion != null) map['idNotificacion'] = idNotificacion;
    if (proximoAviso != null) map['proximoAviso'] = proximoAviso!.toIso8601String();
    if (instrucciones != null) map['instrucciones'] = instrucciones;
    return map;
  }

  factory ModuloHigieneConfig.fromMap(Map<String, dynamic> map) {
    return ModuloHigieneConfig(
      configurado: map['configurado'] ?? false,
      frecuenciaDias: map['frecuenciaDias'] ?? 0,
      notificacionActiva: map['notificacionActiva'] ?? false,
      idNotificacion: map['idNotificacion'] as int?,
      proximoAviso: map['proximoAviso'] != null
          ? DateTime.parse(map['proximoAviso'])
          : null,
      utensilios: List<String>.from(map['utensilios'] ?? []),
      instrucciones: map['instrucciones'] as String?,
    );
  }
}
