import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/core/model/familia.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/firebase_options.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CREAR MASCOTA
  Future<void> crearMascota(Mascota mascota) async {
    // 1. Creamos la referencia en la subcolección dentro de la familia correspondiente
    final docMascota = _db
        .collection('Familias')
        .doc(mascota.familiaID)
        .collection('Mascotas')
        .doc();
    
    // 2. Actualizamos el objeto mascota con ese ID real generado
    mascota.mascotaID = docMascota.id; 

    // 3. Enviamos el mapa
    await docMascota.set(mascota.toJson());
  }

  static Future<void> conectarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Generador de código aleatorio (6 caracteres alfanuméricos)
  String generarCodigoInvitacion() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  // CREAR FAMILIA
  Future<void> crearFamilia(String nombreFamilia, Usuario usuarioActual) async {
    final docFamilia = _db.collection('Familias').doc();
    final codigo = generarCodigoInvitacion();

    final nuevaFamilia = Familia(
      familiaID: docFamilia.id,
      nombre: nombreFamilia,
      adminID: usuarioActual.usuarioID,
      codigoInvitacion: codigo,
      creadoEn: DateTime.now(),
    );

    // Usamos un WriteBatch para asegurar que todas las operaciones se realicen con éxito
    WriteBatch batch = _db.batch();

    // 1. Crear documento de la familia
    batch.set(docFamilia, nuevaFamilia.toJson());

    // 2. Actualizar usuario (rol admin y familiaID)
    batch.update(_db.collection('Usuarios').doc(usuarioActual.usuarioID), {
      'rol': UserRol.admin.name,
      'familiaID': docFamilia.id,
    });

    await batch.commit();
  }

  // UNIRSE A FAMILIA
  Future<String?> unirseAFamilia(String codigo, Usuario usuarioActual) async {
    // 1. Buscar familia por código
    final query = await _db
        .collection('Familias')
        .where('codigoInvitacion', isEqualTo: codigo.toUpperCase())
        .get();

    if (query.docs.isEmpty) return "Código no válido";

    final familiaDoc = query.docs.first;
    final familiaID = familiaDoc.id;

    WriteBatch batch = _db.batch();

    // 2. Actualizar usuario (rol miembro y familiaID)
    batch.update(_db.collection('Usuarios').doc(usuarioActual.usuarioID), {
      'rol': UserRol.miembro.name,
      'familiaID': familiaID,
    });

    await batch.commit();
    return null; // Éxito
  }

  // SEARCH
  Future<Usuario> getCurrentUser(User u) async {
    final doc = await _db.collection('Usuarios').doc(u.uid).get();
    return Usuario.fromJson(doc.data()!, doc.id);
  }

  // CREATE
  Future<void> addUsuario(Usuario u, String uid) async {
    final docUsuario = _db.collection('Usuarios').doc(uid);
    final json = u.toJson(uid);
    await docUsuario.set(json);
  }

  // READ
  Stream<List<Usuario>> readUsuarios() => _db.collection('Usuarios').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Usuario.fromJson(doc.data(), doc.id))
            .toList(),
      );

  // UPDATE
  Future<void> updateUsuario(Usuario u) async {
    final docUsuario = _db.collection('Usuarios').doc(u.usuarioID);
    await docUsuario.update(u.toJson(u.usuarioID));
  }

  // UPDATE - Solo email (para sync después de confirmación)
  Future<void> updateEmailOnly(String uid, String newEmail) async {
    final docUsuario = _db.collection('Usuarios').doc(uid);
    await docUsuario.update({'email': newEmail});
  }

  // DELETE
  Future<void> deleteUsuario(Usuario u) async {
    final docUsuario = _db.collection('Usuarios').doc(u.usuarioID);
    await docUsuario.delete();
  }
}
