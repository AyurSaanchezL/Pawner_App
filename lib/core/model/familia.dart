import 'package:cloud_firestore/cloud_firestore.dart';

class Familia {
  String familiaID;
  String nombre;
  String adminID;
  String codigoInvitacion;
  DateTime creadoEn;

  Familia({
    required this.familiaID,
    required this.nombre,
    required this.adminID,
    required this.codigoInvitacion,
    required this.creadoEn,
  });

  Map<String, dynamic> toJson() => {
    'familiaID': familiaID,
    'nombre': nombre,
    'adminID': adminID,
    'codigoInvitacion': codigoInvitacion,
    'creadoEn': Timestamp.fromDate(creadoEn),
  };

  factory Familia.fromJson(Map<String, dynamic> json, String id) {
    return Familia(
      familiaID: id,
      nombre: json['nombre'] ?? '',
      adminID: json['adminID'] ?? '',
      codigoInvitacion: json['codigoInvitacion'] ?? '',
      creadoEn: (json['creadoEn'] as Timestamp).toDate(),
    );
  }
}
