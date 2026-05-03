import 'package:pawner_app/core/constants.dart';

class Usuario {
  String usuarioID;
  String nombre;
  String email;
  String fotoUrl;
  UserRol? rol; // ENUM { admin, miembro }
  String? familiaID;

  Usuario(
    this.usuarioID,
    this.nombre,
    this.email,
    this.fotoUrl,
    this.rol,
    this.familiaID,
  );

  Map<String, dynamic> toJson(String id) => {
    'usuarioID': id,
    'nombre': nombre,
    'email': email,
    'fotoUrl': fotoUrl,
    'rol': rol!.name,
    'familiaID': familiaID,
  };

  factory Usuario.fromJson(Map<String, dynamic> json, String idFirebase) {
    var rol = json['rol'];
    if (rol != null) {
      for (UserRol r in UserRol.values) {
        if (r.name == rol) {
          rol = r;
        }
      }
    }
    return Usuario(
      idFirebase,
      json['nombre'],
      json['email'],
      json['fotoUrl'],
      rol,
      json['familiaID'],
    );
  }
}
