import 'package:flutter_test/flutter_test.dart';
import 'package:pawner_app/core/model/modulo_vet/cita_veterinaria.dart';
import 'package:pawner_app/core/model/modulo_vet/modulo_vet_config.dart';
import 'package:pawner_app/core/model/recordatorio.dart';

void main() {
  // ------------------------------------------------------------------ CitaVeterinaria
  group('CitaVeterinaria', () {
    final fecha = DateTime(2026, 9, 1, 11, 0);
    final notifFecha = DateTime(2026, 8, 31, 11, 0);

    CitaVeterinaria _cita({String? recID, DateTime? notifFechaHora}) =>
        CitaVeterinaria(
          id: 'cita-123',
          fecha: fecha,
          motivo: 'Revisión anual',
          veterinario: 'Clínica Pawner',
          notas: 'Traer cartilla de vacunación',
          completada: false,
          notificacionActiva: true,
          idNotificacion: 42,
          recordatorioID: recID,
          notifFechaHora: notifFechaHora,
        );

    test('toMap/fromMap roundtrip preserva todos los campos', () {
      final original = _cita(recID: 'rec-456', notifFechaHora: notifFecha);
      final roundtrip = CitaVeterinaria.fromMap(original.toMap(), 'cita-123');

      expect(roundtrip.id, original.id);
      expect(roundtrip.fecha, original.fecha);
      expect(roundtrip.motivo, original.motivo);
      expect(roundtrip.veterinario, original.veterinario);
      expect(roundtrip.notas, original.notas);
      expect(roundtrip.completada, original.completada);
      expect(roundtrip.notificacionActiva, original.notificacionActiva);
      expect(roundtrip.idNotificacion, original.idNotificacion);
      expect(roundtrip.recordatorioID, original.recordatorioID);
      expect(roundtrip.notifFechaHora, original.notifFechaHora);
    });

    test('fromMap tolera recordatorioID y notifFechaHora nulos', () {
      final map = _cita().toMap();
      map.remove('recordatorioID');
      map.remove('notifFechaHora');
      final cita = CitaVeterinaria.fromMap(map, 'cita-abc');
      expect(cita.recordatorioID, isNull);
      expect(cita.notifFechaHora, isNull);
    });

    test('fromMap usa DateTime.now() si fecha es nula', () {
      final map = _cita().toMap()..remove('fecha');
      final before = DateTime.now();
      final cita = CitaVeterinaria.fromMap(map, 'x');
      expect(cita.fecha.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('toMap serializa notifFechaHora como ISO8601', () {
      final map = _cita(notifFechaHora: notifFecha).toMap();
      expect(map['notifFechaHora'], notifFecha.toIso8601String());
    });

    test('cita completada se serializa y recupera', () {
      final original = CitaVeterinaria(
        id: 'x', fecha: fecha, motivo: 'test', completada: true, notificacionActiva: false,
      );
      final rt = CitaVeterinaria.fromMap(original.toMap(), 'x');
      expect(rt.completada, isTrue);
      expect(rt.notificacionActiva, isFalse);
    });
  });

  // ------------------------------------------------------------------ ModuloVetConfig
  group('ModuloVetConfig', () {
    test('toMap/fromMap roundtrip preserva lista de veterinarios', () {
      final config = ModuloVetConfig(
        alergias: ['Polen', 'Penicilina'],
        veterinarios: [
          {'nombre': 'Dr. García', 'telefono': '600111222', 'numColegiado': 'COL-001'},
          {'nombre': 'Clínica Pawner', 'telefono': '911000000', 'numColegiado': ''},
        ],
        seguroMedico: 'AXA Plus',
        telUrgencias: '112',
      );

      final rt = ModuloVetConfig.fromMap(config.toMap());

      expect(rt.alergias, ['Polen', 'Penicilina']);
      expect(rt.veterinarios.length, 2);
      expect(rt.veterinarios[0]['nombre'], 'Dr. García');
      expect(rt.veterinarios[1]['numColegiado'], '');
      expect(rt.seguroMedico, 'AXA Plus');
      expect(rt.telUrgencias, '112');
    });

    test('migración de estructura antigua (un solo vet) a lista', () {
      final oldMap = <String, dynamic>{
        'nombreVete': 'Dr. López',
        'telVete': '600999888',
        'numColegiado': 'COL-99',
        'alergias': <dynamic>[],
      };

      final config = ModuloVetConfig.fromMap(oldMap);

      expect(config.veterinarios.length, 1);
      expect(config.veterinarios[0]['nombre'], 'Dr. López');
      expect(config.veterinarios[0]['telefono'], '600999888');
      expect(config.veterinarios[0]['numColegiado'], 'COL-99');
    });

    test('estructura antigua sin nombreVete → lista vacía', () {
      final oldMap = <String, dynamic>{'alergias': <dynamic>[]};
      final config = ModuloVetConfig.fromMap(oldMap);
      expect(config.veterinarios, isEmpty);
    });

    test('lista de veterinarios vacía se roundtripea correctamente', () {
      final config = ModuloVetConfig(alergias: [], veterinarios: []);
      expect(ModuloVetConfig.fromMap(config.toMap()).veterinarios, isEmpty);
    });

    test('fromMap con valores de tipo mixto en veterinarios no lanza error', () {
      final map = <String, dynamic>{
        'alergias': <dynamic>[],
        'veterinarios': [
          {'nombre': 42, 'telefono': null, 'numColegiado': true},
        ],
      };
      expect(() => ModuloVetConfig.fromMap(map), returnsNormally);
      final config = ModuloVetConfig.fromMap(map);
      expect(config.veterinarios[0]['nombre'], '42');
      expect(config.veterinarios[0]['telefono'], '');
    });
  });

  // ------------------------------------------------------------------ Recordatorio
  group('Recordatorio', () {
    final fecha = DateTime(2026, 10, 5, 9, 0);

    test('toMap/fromMap roundtrip preserva todos los campos', () {
      final original = Recordatorio(
        recordatorioID: 'rec-001',
        titulo: 'Cita vacuna',
        descripcion: 'Vacuna de la rabia',
        fechaHora: fecha,
        completado: false,
        familiaID: 'familia-abc',
        mascotaID: 'mascota-xyz',
        moduloID: 'mod_vet',
      );

      final rt = Recordatorio.fromMap(original.toMap(), 'rec-001');

      expect(rt.recordatorioID, 'rec-001');
      expect(rt.titulo, 'Cita vacuna');
      expect(rt.descripcion, 'Vacuna de la rabia');
      expect(rt.fechaHora, fecha);
      expect(rt.completado, isFalse);
      expect(rt.mascotaID, 'mascota-xyz');
      expect(rt.moduloID, 'mod_vet');
    });

    test('fromMap tolera descripcion, mascotaID y moduloID nulos', () {
      final map = <String, dynamic>{
        'titulo': 'Test',
        'fechaHora': fecha.toIso8601String(),
        'completado': false,
        'familiaID': 'fam-1',
      };
      final r = Recordatorio.fromMap(map, 'rec-2');
      expect(r.descripcion, isNull);
      expect(r.mascotaID, isNull);
      expect(r.moduloID, isNull);
    });

    test('recordatorio completado se serializa y recupera', () {
      final r = Recordatorio(
        recordatorioID: 'x', titulo: 't', fechaHora: fecha,
        completado: true, familiaID: 'f',
      );
      expect(Recordatorio.fromMap(r.toMap(), 'x').completado, isTrue);
    });
  });

  // ------------------------------------------------------------------ Lógica de negocio transversal
  group('Cuerpo de notificación', () {
    // La lógica está en _AddCitaSheetState._guardar() — la replicamos aquí
    // para verificar el comportamiento de truncado.
    String buildNotifBody(String motivo, String notas) {
      return notas.isNotEmpty
          ? '$motivo · ${notas.length > 60 ? '${notas.substring(0, 60)}…' : notas}'
          : motivo;
    }

    test('sin notas → solo motivo', () {
      expect(buildNotifBody('Vacuna rabia', ''), 'Vacuna rabia');
    });

    test('notas cortas → motivo + notas completas', () {
      expect(
        buildNotifBody('Revisión', 'Traer cartilla'),
        'Revisión · Traer cartilla',
      );
    });

    test('notas largas → truncadas a 60 chars con …', () {
      final notas = 'A' * 80;
      final body = buildNotifBody('Rev', notas);
      expect(body, 'Rev · ${'A' * 60}…');
    });

    test('notas de exactamente 60 chars → no se truncan', () {
      final notas = 'B' * 60;
      final body = buildNotifBody('Rev', notas);
      expect(body, 'Rev · ${'B' * 60}');
    });
  });
}
