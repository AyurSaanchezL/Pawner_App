import 'dart:developer' as dev;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/core/model/familia.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/core/model/modulo_comida/horario_model.dart';
import 'package:pawner_app/core/model/modulo_comida/modulo_comida_config.dart';
import 'package:pawner_app/core/model/modulo_vet/cita_veterinaria.dart';
import 'package:pawner_app/core/model/modulo_vet/evento_salud.dart';
import 'package:pawner_app/core/model/modulo_vet/modulo_vet_config.dart';
import 'package:pawner_app/core/model/recordatorio.dart';
import 'package:pawner_app/firebase_options.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

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

  // Stream de una mascota específica
  Stream<Mascota> streamMascota(String familiaID, String mascotaID) {
    return _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Mascotas')
        .doc(mascotaID)
        .snapshots()
        .map((doc) => Mascota.fromJson(doc.data()!, doc.id));
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

  // ELIMINAR MASCOTA — cascade: borra todas las subcolecciones y recordatorios vinculados.
  // Devuelve los IDs de notificación local que el caller debe cancelar.
  Future<List<int>> eliminarMascota(String familiaID, String mascotaID) async {
    final notifIds = <int>[];
    final batch = _db.batch();

    // Citas veterinarias (notificaciones one-time)
    final citasSnap = await _modVetDoc(familiaID, mascotaID).collection('Citas').get();
    for (final doc in citasSnap.docs) {
      final cita = CitaVeterinaria.fromMap(doc.data(), doc.id);
      if (cita.idNotificacion != null) notifIds.add(cita.idNotificacion!);
      batch.delete(doc.reference);
    }

    // Eventos de salud (sin notificación)
    final eventosSnap = await _modVetDoc(familiaID, mascotaID).collection('EventosSalud').get();
    for (final doc in eventosSnap.docs) {
      batch.delete(doc.reference);
    }

    // Platos (sin notificación)
    final platosSnap = await _db
        .doc(_modComidaPath(familiaID, mascotaID))
        .collection('Platos')
        .get();
    for (final doc in platosSnap.docs) {
      batch.delete(doc.reference);
    }

    // Horarios de comida (notificaciones recurrentes)
    final horariosSnap = await _db
        .doc(_modComidaPath(familiaID, mascotaID))
        .collection('Horarios')
        .get();
    for (final doc in horariosSnap.docs) {
      final horario = HorarioComida.fromMap(doc.data(), doc.id);
      notifIds.add(horario.idNotificacion);
      batch.delete(doc.reference);
    }

    // Recordatorios de familia vinculados a esta mascota
    final recsSnap = await _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .where('mascotaID', isEqualTo: mascotaID)
        .get();
    for (final doc in recsSnap.docs) {
      batch.delete(doc.reference);
    }

    // El documento de la mascota
    batch.delete(
      _db.collection('Familias').doc(familiaID).collection('Mascotas').doc(mascotaID),
    );

    await batch.commit();
    return notifIds;
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

  // Comprueba si un código de invitación ya existe en alguna familia
  Future<bool> _codigoInvitacionExiste(String codigo) async {
    final query = await _db
        .collection('Familias')
        .where('codigoInvitacion', isEqualTo: codigo)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Genera un código garantizando que no colisiona con ninguno existente
  Future<String> _generarCodigoUnico() async {
    String codigo;
    do {
      codigo = generarCodigoInvitacion();
    } while (await _codigoInvitacionExiste(codigo));
    return codigo;
  }

  // CREAR FAMILIA
  Future<void> crearFamilia(String nombreFamilia, Usuario usuarioActual) async {
    final docFamilia = _db.collection('Familias').doc();
    final codigo = await _generarCodigoUnico();

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

  // READ
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

  // One-shot fetch de todas las mascotas de una familia
  Future<List<Mascota>> getMascotas(String familiaID) async {
    final snap = await _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Mascotas')
        .get();
    return snap.docs.map((doc) => Mascota.fromJson(doc.data(), doc.id)).toList();
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
    final nuevoCodigo = await _generarCodigoUnico();
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

  DocumentReference _modVetDoc(String familiaID, String mascotaID) =>
      _db.collection('Familias').doc(familiaID)
          .collection('Mascotas').doc(mascotaID)
          .collection('Modulos').doc('mod_vet');

  // Guardar configuración del módulo veterinario (Perfil Médico)
  Future<void> saveModuloVetConfig(
    String familiaID,
    String mascotaID,
    ModuloVetConfig config,
  ) async {
    await _modVetDoc(familiaID, mascotaID)
        .set(config.toMap(), SetOptions(merge: true));
  }

  // Obtener configuración del módulo veterinario
  Future<ModuloVetConfig?> getModuloVetConfig(
    String familiaID,
    String mascotaID,
  ) async {
    final doc = await _modVetDoc(familiaID, mascotaID).get();
    if (!doc.exists) return null;
    return ModuloVetConfig.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<ModuloVetConfig?> streamModuloVetConfig(
    String familiaID,
    String mascotaID,
  ) {
    return _modVetDoc(familiaID, mascotaID)
        .snapshots()
        .map((doc) => doc.exists ? ModuloVetConfig.fromMap(doc.data() as Map<String, dynamic>) : null);
  }

  // One-shot fetch de todas las citas de una mascota
  Future<List<CitaVeterinaria>> getCitasVeterinarias(String familiaID, String mascotaID) async {
    final snap = await _modVetDoc(familiaID, mascotaID).collection('Citas').get();
    return snap.docs.map((doc) => CitaVeterinaria.fromMap(doc.data(), doc.id)).toList();
  }

  Stream<List<CitaVeterinaria>> streamCitasVeterinarias(
    String familiaID,
    String mascotaID,
  ) {
    return _modVetDoc(familiaID, mascotaID)
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
    final citaDoc = _modVetDoc(familiaID, mascotaID).collection('Citas').doc();
    final recDoc = _db.collection('Familias').doc(familiaID).collection('Recordatorios').doc();

    cita.id = citaDoc.id;
    cita.recordatorioID = recDoc.id;

    final recordatorio = Recordatorio(
      recordatorioID: recDoc.id,
      titulo: cita.motivo,
      descripcion: cita.veterinario,
      fechaHora: cita.fecha,
      familiaID: familiaID,
      mascotaID: mascotaID,
      moduloID: 'mod_vet',
    );

    final batch = _db.batch();
    batch.set(citaDoc, cita.toMap());
    batch.set(recDoc, recordatorio.toMap());
    await batch.commit();
  }

  Future<void> updateCitaVeterinaria(
    String familiaID,
    String mascotaID,
    CitaVeterinaria cita,
  ) async {
    await _modVetDoc(familiaID, mascotaID)
        .collection('Citas')
        .doc(cita.id)
        .update(cita.toMap());
  }

  Future<void> deleteCitaVeterinaria(
    String familiaID,
    String mascotaID,
    String citaId,
  ) async {
    await _modVetDoc(familiaID, mascotaID)
        .collection('Citas')
        .doc(citaId)
        .delete();
  }

  // Implementación para eliminar cita y su recordatorio asociado
  Future<void> deleteCitaVeterinariaWithReminder(
    String familiaID,
    String mascotaID,
    String citaId,
    String recordatorioId, // Se asume que se pasa el ID del recordatorio asociado
  ) async {
    WriteBatch batch = _db.batch();

    // 1. Eliminar la cita de la subcolección Citas
    batch.delete(
      _modVetDoc(familiaID, mascotaID)
          .collection('Citas')
          .doc(citaId),
    );

    // 2. Eliminar el recordatorio de la colección global de Recordatorios
    batch.delete(
      _db.collection('Familias').doc(familiaID).collection('Recordatorios').doc(recordatorioId),
    );

    await batch.commit();
  }

  // Método para actualizar solo el estado de notificación de una cita
  Future<void> updateCitaNotificationStatus(
    String familiaID,
    String mascotaID,
    String citaId,
    bool notificacionActiva,
    int? idNotificacion, // ID de la notificación programada (opcional)
  ) async {
    // Primero, actualizamos el estado en Firestore
    await _modVetDoc(familiaID, mascotaID)
        .collection('Citas')
        .doc(citaId)
        .update({'notificacionActiva': notificacionActiva});

    // La lógica de cancelar/programar notificación real se maneja en el UI (veterinario_screen.dart)
    // ya que interactúa con NotificationService y tiene la lógica de tiempo.
    // Este método solo actualiza el estado en la base de datos.
  }

  // Stream de eventos de salud (Historial)
  Stream<List<EventoSalud>> streamEventosSalud(
    String familiaID,
    String mascotaID,
  ) {
    return _modVetDoc(familiaID, mascotaID)
        .collection('EventosSalud')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventoSalud.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Añadir evento de salud
  Future<void> addEventoSalud(
    String familiaID,
    String mascotaID,
    EventoSalud evento,
  ) async {
    final doc = _modVetDoc(familiaID, mascotaID)
        .collection('EventosSalud')
        .doc();
    evento.id = doc.id;
    await doc.set(evento.toMap());
  }

  // Eliminar evento de salud
  Future<void> deleteEventoSalud(
    String familiaID,
    String mascotaID,
    String eventoId,
  ) async {
    await _modVetDoc(familiaID, mascotaID)
        .collection('EventosSalud')
        .doc(eventoId)
        .delete();
  }

  // --- RECORDATORIOS (nivel Familia) ---

  Future<void> addRecordatorio(String familiaID, Recordatorio recordatorio) async {
    final doc = _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .doc();
    recordatorio.recordatorioID = doc.id;
    await doc.set(recordatorio.toMap());
  }

  Stream<List<Recordatorio>> streamRecordatoriosFamilia(String familiaID) {
    return _db
        .collection('Familias')
        .doc(familiaID)
        .collection('Recordatorios')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Recordatorio.fromMap(doc.data(), doc.id))
              .where((r) => !r.completado && r.fechaHora.isAfter(DateTime.now().subtract(const Duration(days: 1))))
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
