import 'package:cloud_firestore/cloud_firestore.dart';

class Paseo {
  String paseoID;
  String? observaciones;
  int tiempoMinutos;
  Timestamp fechaHora;
  String? urlFoto;

  Paseo({
    required this.paseoID,
    this.observaciones,
    required this.tiempoMinutos,
    required this.fechaHora,
    this.urlFoto,
  });

  Map<String, dynamic> toJson() => {
    'id': paseoID,
    'observaciones': observaciones,
    'tiempoMinutos': tiempoMinutos,
    'fechaHora': fechaHora,
    'urlFoto': urlFoto,
  };

  factory Paseo.fromJson(Map<String, dynamic> json, String idPaseo) {
    return Paseo(
      paseoID: idPaseo,
      observaciones: json['observaciones'] ?? "",
      tiempoMinutos: json['tiempoMinutos'],
      fechaHora: json['fechaHora'],
      urlFoto: json['urlFoto'] ?? "",
    );
  }
}
