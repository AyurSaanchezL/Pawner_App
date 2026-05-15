import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawner_app/core/model/modulo_comida/horario_model.dart';
import 'package:pawner_app/core/model/modulo_comida/modulo_comida_config.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/services/notification_service.dart';

class ComidaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la subcolección base de ModComida
  DocumentReference _getModComidaRef(String familiaId, String mascotaId) {
    return _firestore
        .collection('Familias')
        .doc(familiaId)
        .collection('Mascotas')
        .doc(mascotaId)
        .collection('Modulos')
        .doc('mod_comida');
  }

  // === CONFIGURACIÓN ===

  Stream<ModuloComidaConfig> getConfig(String familiaId, String mascotaId) {
    return _getModComidaRef(familiaId, mascotaId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return ModuloComidaConfig.fromMap(data['config'] ?? {});
      } else {
        return ModuloComidaConfig(
          categoriasActivas: ['Seca', 'Húmeda', 'Natural'],
          notificacionesActivas: true,
          umbralHoras: 1,
        );
      }
    });
  }

  Future<void> saveConfig(
    String familiaId,
    String mascotaId,
    ModuloComidaConfig config,
  ) async {
    await _getModComidaRef(familiaId, mascotaId).set({
      'config': config.toMap(),
      'categoriasActivas': config.categoriasActivas,
    }, SetOptions(merge: true));
  }

  // === PLATOS ===

  Stream<List<Plato>> getPlatos(String familiaId, String mascotaId) {
    return _getModComidaRef(familiaId, mascotaId)
        .collection('Platos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Plato.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addPlato(String familiaId, String mascotaId, Plato plato) async {
    final docRef = _getModComidaRef(familiaId, mascotaId).collection('Platos').doc();
    plato.id = docRef.id;
    await docRef.set(plato.toMap());
  }

  // === HORARIOS ===

  Stream<List<HorarioComida>> getHorarios(String familiaId, String mascotaId) {
    return _getModComidaRef(familiaId, mascotaId)
        .collection('Horarios')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HorarioComida.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addHorario(String familiaId, String mascotaId, HorarioComida horario, {required String mascotaNombre}) async {
    final docRef = _getModComidaRef(familiaId, mascotaId).collection('Horarios').doc();
    horario.id = docRef.id;
    await docRef.set(horario.toMap());

    if (horario.activo) {
      final partes = horario.hora.split(':');
      if (partes.length == 2) {
        final hour = int.parse(partes[0]);
        final minute = int.parse(partes[1]);
        await NotificationService().scheduleFixedTimeNotification(
          id: horario.idNotificacion,
          hour: hour,
          minute: minute,
          mascotaNombre: mascotaNombre,
        );
      }
    }
  }

  Future<void> toggleHorario(String familiaId, String mascotaId, HorarioComida horario, {required String mascotaNombre}) async {
    horario.activo = !horario.activo;

    await _getModComidaRef(familiaId, mascotaId)
        .collection('Horarios')
        .doc(horario.id)
        .update({'activo': horario.activo});

    if (horario.activo) {
      final partes = horario.hora.split(':');
      if (partes.length == 2) {
        final hour = int.parse(partes[0]);
        final minute = int.parse(partes[1]);
        await NotificationService().scheduleFixedTimeNotification(
          id: horario.idNotificacion,
          hour: hour,
          minute: minute,
          mascotaNombre: mascotaNombre,
        );
      }
    } else {
      await NotificationService().cancel(horario.idNotificacion);
    }
  }
}
