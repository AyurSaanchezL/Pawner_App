import 'package:flutter_test/flutter_test.dart';
import 'package:pawner_app/screens/modulos/veterinario/veterinario_screen.dart';

void main() {
  final cita = DateTime(2026, 8, 15, 10, 30); // 15-ago-2026 10:30

  group('computeNotifDateTime', () {
    test('1h antes → cita - 1 hora', () {
      expect(
        computeNotifDateTime(NotifTiming.horasBefore1, cita),
        DateTime(2026, 8, 15, 9, 30),
      );
    });

    test('5h antes → cita - 5 horas', () {
      expect(
        computeNotifDateTime(NotifTiming.horasBefore5, cita),
        DateTime(2026, 8, 15, 5, 30),
      );
    });

    test('5h antes cruza medianoche correctamente', () {
      final citaMedianoche = DateTime(2026, 8, 15, 3, 0);
      expect(
        computeNotifDateTime(NotifTiming.horasBefore5, citaMedianoche),
        DateTime(2026, 8, 14, 22, 0),
      );
    });

    test('1 día antes → cita - 24 horas', () {
      expect(
        computeNotifDateTime(NotifTiming.diaBefore, cita),
        DateTime(2026, 8, 14, 10, 30),
      );
    });

    test('1 semana antes → cita - 7 días', () {
      expect(
        computeNotifDateTime(NotifTiming.semanaBefore, cita),
        DateTime(2026, 8, 8, 10, 30),
      );
    });

    test('personalizado con fecha → devuelve esa fecha', () {
      final custom = DateTime(2026, 8, 13, 8, 0);
      expect(
        computeNotifDateTime(NotifTiming.personalizado, cita, custom: custom),
        custom,
      );
    });

    test('personalizado sin fecha → null', () {
      expect(
        computeNotifDateTime(NotifTiming.personalizado, cita),
        isNull,
      );
    });

    test('el enum tiene exactamente 5 valores', () {
      expect(NotifTiming.values.length, 5);
    });
  });
}
