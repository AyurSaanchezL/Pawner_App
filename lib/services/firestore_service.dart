import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/firebase_options.dart';

class FirestoreService {
  static Future<void> conectarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // SEARCH
  Future<Usuario> getCurrentUser(User u) async {
    final doc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(u.uid)
        .get();
    return Usuario.fromJson(doc.data()!, doc.id);
  }

  // CREATE
  Future<void> addUsuario(Usuario u, String uid) async {
    final docUsuario = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uid);

    final json = u.toJson(uid);

    await docUsuario.set(json);
  }

  // READ
  Stream<List<Usuario>> readUsuarios() => FirebaseFirestore.instance
      .collection('Usuarios')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Usuario.fromJson(doc.data(), doc.id))
            .toList(),
      );

  // UPDATE
  Future<void> updateUsuario(Usuario u) async {
    final docUsuario = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(u.usuarioID);

    await docUsuario.update(u.toJson(u.usuarioID));
  }

  // UPDATE - Solo email (para sync después de confirmación)
  Future<void> updateEmailOnly(String uid, String newEmail) async {
    final docUsuario = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uid);

    await docUsuario.update({'email': newEmail});
  }

  // DELETE
  Future<void> deleteUsuario(Usuario u) async {
    final docUsuario = FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(u.usuarioID);

    // TODO habría que mirar el hecho de eliminar el usuario también de Auth

    await docUsuario.delete();
  }
}
