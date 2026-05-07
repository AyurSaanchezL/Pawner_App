import 'dart:developer' as dev;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/core/model/familia.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/plato_model.dart';
import 'package:pawner_app/core/model/horario_model.dart';
import 'package:pawner_app/core/model/modulo_comida_config.dart';
import 'package:pawner_app/core/model/cita_veterinaria.dart';
import 'package:pawner_app/core/model/recordatorio.dart';
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

  // ACTUALIZAR MASCOTA
  Future<void> actualizarMascota(Mascota mascota) async {
    await _db
        .collection('Familias')
        .doc(mascota.familiaID)
        .collection('Mascotas')
        .doc(mascota.mascotaID)
        .update(mascota.toJson());
  }

  // ELIMINAR MASCOTA
  Future<void> eliminarMascota(String familiaID, String mascotaID) async {
    await _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Mascotas')
        .doc(mascotaID)
        .delete();
  }

  static Future<void> conectarFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Generador de código aleatorio (6 caracteres alfanuméricos)
  String generarCodigoInvitacion() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
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
  Stream<List<Usuario>> readUsuarios() => _db
      .collection('Usuarios')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Usuario.fromJson(doc.data(), doc.id))
            .toList(),
      );

  // UPDATE
  Future<void> updateUsuario(Usuario u) async {
    final docUsuario = _db.collection('Usuarios').doc(u.usuarioID);
    dev.log(u.toJson(u.usuarioID).toString());
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

  // --- NUEVOS MÉTODOS PARA DETALLE DE FAMILIA ---

  // Obtener una familia por ID
  Future<Familia?> getFamilia(String familiaID) async {
    final doc = await _db.collection('Familias').doc(familiaID).get();
    if (!doc.exists) return null;
    return Familia.fromJson(doc.data()!, doc.id);
  }

  
  // Obtener nombre de la familia del usuario actual
  Future<String> obtenerNombreFamilia() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return "Sin nombre";

    Usuario usuario = await getCurrentUser(u);

    if (usuario.familiaID == null || usuario.familiaID!.isEmpty) {
      return "Sin nombre";
    }

    var famDoc = await _db
        .collection('Familias')
        .doc(usuario.familiaID)
        .get();

    return famDoc.data()?['nombre'] ?? "Sin nombre";
  }

  // Stream de mascotas de una familia
  Stream<List<Mascota>> streamMascotas(String familiaID) {
    return _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Mascotas')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Mascota.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream de miembros (usuarios) de una familia
  Stream<List<Usuario>> streamMiembros(String familiaID) {
    return _db
        .collection('Usuarios')
        .where('familiaID', isEqualTo: familiaID)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Usuario.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Abandonar una familia con lógica robusta
  Future<void> abandonarFamilia(Usuario usuario) async {
    final String? familiaID = usuario.familiaID;
    if (familiaID == null) return;

    WriteBatch batch = _db.batch();

    if (usuario.rol == UserRol.admin) {
      // 1. Buscar otros miembros de la familia
      final miembrosQuery = await _db
          .collection('Usuarios')
          .where('familiaID', isEqualTo: familiaID)
          .get();

      final otrosMiembros = miembrosQuery.docs
          .where((doc) => doc.id != usuario.usuarioID)
          .toList();

      if (otrosMiembros.isNotEmpty) {
        // ESCENARIO A: Hay más personas -> Promover al primero que encontremos
        final nuevoAdminDoc = otrosMiembros.first;

        // Actualizar el rol del nuevo admin
        batch.update(nuevoAdminDoc.reference, {'rol': UserRol.admin.name});

        // Actualizar la referencia de admin en el documento de la Familia
        batch.update(_db.collection('Familias').doc(familiaID), {
          'adminID': nuevoAdminDoc.id,
        });
      } else {
        // ESCENARIO B: Es el único -> Borrado total (Familia + Mascotas)

        // 1. Borrar subcolección de mascotas
        final mascotasQuery = await _db
            .collection('Familias')
            .doc(familiaID)
            .collection('Mascotas')
            .get();

        for (var doc in mascotasQuery.docs) {
          batch.delete(doc.reference);
        }

        // 2. Borrar documento de la familia
        batch.delete(_db.collection('Familias').doc(familiaID));
      }
    }

    // En todos los casos, el usuario actual se desvincula
    batch.update(_db.collection('Usuarios').doc(usuario.usuarioID), {
      'familiaID': null,
      'rol': null,
    });

    await batch.commit();
  }

  // Regenerar el código de invitación de una familia
  Future<void> regenerarCodigoFamilia(String familiaID) async {
    final nuevoCodigo = generarCodigoInvitacion();
    await _db.collection('Familias').doc(familiaID).update({
      'codigoInvitacion': nuevoCodigo,
    });
  }

  // Eliminar un miembro de la familia (solo por el administrador)
  Future<void> eliminarMiembroFamilia(String usuarioID) async {
    await _db.collection('Usuarios').doc(usuarioID).update({
      'familiaID': null,
      'rol': null,
    });
  }

  // --- MÓDULO COMIDA ---

  String _modComidaPath(String familiaID, String mascotaID) =>
      'Familias/$familiaID/Mascotas/$mascotaID/Modulos/mod_comida';

  // Stream de platos
  Stream<List<Plato>> streamPlatos(String familiaID, String mascotaID) {
    return _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Platos')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Plato.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Añadir plato
  Future<void> addPlato(String familiaID, String mascotaID, Plato plato) async {
    final doc = _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Platos')
        .doc();
    plato.id = doc.id;
    await doc.set(plato.toMap());
  }

  // Eliminar plato
  Future<void> deletePlato(String familiaID, String mascotaID, String platoId) async {
    await _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Platos')
        .doc(platoId)
        .delete();
  }

  // Stream de horarios
  Stream<List<HorarioComida>> streamHorarios(String familiaID, String mascotaID) {
    return _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Horarios')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HorarioComida.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Toggle horario activo
  Future<void> toggleHorarioActivo(
    String familiaID,
    String mascotaID,
    String horarioId,
    bool activo,
  ) async {
    await _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Horarios')
        .doc(horarioId)
        .update({'activo': activo});
  }

  // Crear o actualizar horario
  Future<void> saveHorario(
    String familiaID,
    String mascotaID,
    HorarioComida horario,
  ) async {
    final doc = _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Horarios')
        .doc(horario.id);
    await doc.set(horario.toMap());
  }

  // Eliminar horario
  Future<void> deleteHorario(String familiaID, String mascotaID, String horarioId) async {
    await _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .collection('Horarios')
        .doc(horarioId)
        .delete();
  }

  // Guardar configuración del módulo comida
  Future<void> saveModuloComidaConfig(
    String familiaID,
    String mascotaID,
    ModuloComidaConfig config,
  ) async {
    await _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .set(config.toMap());
  }

  // Obtener configuración del módulo comida
  Future<ModuloComidaConfig?> getModuloComidaConfig(
    String familiaID,
    String mascotaID,
  ) async {
    final doc = await _db
        .collection(_modComidaPath(familiaID, mascotaID))
        .doc('data')
        .get();
    if (!doc.exists) return null;
    return ModuloComidaConfig.fromMap(doc.data()!);
  }

  // --- MÓDULO VETERINARIO ---

  String _modVetPath(String familiaID, String mascotaID) =>
      'Familias/$familiaID/Mascotas/$mascotaID/Modulos/mod_vet';

  Stream<List<CitaVeterinaria>> streamCitasVeterinarias(
    String familiaID,
    String mascotaID,
  ) {
    return _db
        .collection(_modVetPath(familiaID, mascotaID))
        .doc('data')
        .collection('Citas')
        .orderBy('fecha')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CitaVeterinaria.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addCitaVeterinaria(
    String familiaID,
    String mascotaID,
    CitaVeterinaria cita,
  ) async {
    final doc = _db
        .collection(_modVetPath(familiaID, mascotaID))
        .doc('data')
        .collection('Citas')
        .doc();
    cita.id = doc.id;
    await doc.set(cita.toMap());

    // Crear recordatorio global para el dashboard
    final recordatorioDoc = _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .doc();
    final recordatorio = Recordatorio(
      recordatorioID: recordatorioDoc.id,
      titulo: cita.motivo,
      descripcion: cita.veterinario,
      fechaHora: cita.fecha,
      familiaID: familiaID,
      mascotaID: mascotaID,
      moduloID: 'mod_vet',
    );
    await recordatorioDoc.set(recordatorio.toMap());
  }

  Future<void> updateCitaVeterinaria(
    String familiaID,
    String mascotaID,
    CitaVeterinaria cita,
  ) async {
    await _db
        .collection(_modVetPath(familiaID, mascotaID))
        .doc('data')
        .collection('Citas')
        .doc(cita.id)
        .update(cita.toMap());
  }

  Future<void> deleteCitaVeterinaria(
    String familiaID,
    String mascotaID,
    String citaId,
  ) async {
    await _db
        .collection(_modVetPath(familiaID, mascotaID))
        .doc('data')
        .collection('Citas')
        .doc(citaId)
        .delete();
  }

  // --- RECORDATORIOS (nivel Familia) ---

  Stream<List<Recordatorio>> streamRecordatoriosFamilia(String familiaID) {
    return _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recordatorio.fromMap(doc.data(), doc.id))
              .where((r) => r.fechaHora.isAfter(DateTime.now().subtract(const Duration(days: 1))))
              .toList()
            ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora)),
        );
  }

  Future<void> toggleRecordatorioCompletado(
    String familiaID,
    String recordatorioID,
    bool completado,
  ) async {
    await _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .doc(recordatorioID)
        .update({'completado': completado});
  }

  Future<void> deleteRecordatorio(String familiaID, String recordatorioID) async {
    await _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .doc(recordatorioID)
        .delete();
  }
}
