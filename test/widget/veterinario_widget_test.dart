import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pawner_app/core/model/modulo_vet/cita_veterinaria.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/screens/modulos/veterinario/veterinario_screen.dart';
import 'package:pawner_app/services/firestore_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Mascota _mascota() => Mascota(
  mascotaID: 'pet-1',
  nombre: 'Rocky',
  especie: 'Perro',
  raza: 'Labrador',
  chip: '123',
  peso: 25.0,
  fechaNacimiento: DateTime(2020, 5, 1),
  genero: 'Macho',
  esterilizado: true,
  observaciones: '',
  fotoUrl: '',
  familiaID: 'fam-1',
  modulos: ['Veterinario'],
);

CitaVeterinaria _cita({
  String motivo = 'Vacuna rabia',
  String? veterinario,
  String? notas,
  bool completada = false,
  bool notificacionActiva = true,
  DateTime? fecha,
}) => CitaVeterinaria(
  id: 'cita-1',
  fecha: fecha ?? DateTime(2026, 10, 1, 10, 30),
  motivo: motivo,
  veterinario: veterinario,
  notas: notas,
  completada: completada,
  notificacionActiva: notificacionActiva,
);

// ── CitaDetailSheet ───────────────────────────────────────────────────────────

void main() {
  group('CitaDetailSheet', () {
    setUpAll(() async {
      await initializeDateFormatting('es', null);
    });

    testWidgets('muestra motivo y fecha correctamente', (tester) async {
      final cita = _cita(motivo: 'Revisión anual');
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Revisión anual'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
    });

    testWidgets('muestra veterinario cuando está presente', (tester) async {
      final cita = _cita(veterinario: 'Clínica Pawner');
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Clínica Pawner'), findsOneWidget);
    });

    testWidgets('oculta la fila veterinario cuando es null', (tester) async {
      final cita = _cita(veterinario: null);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Veterinario / Clínica'), findsNothing);
    });

    testWidgets('muestra notas cuando están presentes', (tester) async {
      final cita = _cita(notas: 'Traer cartilla');
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Traer cartilla'), findsOneWidget);
    });

    testWidgets('oculta la fila notas cuando es null', (tester) async {
      final cita = _cita(notas: null);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Notas'), findsNothing);
    });

    testWidgets('recordatorio activo muestra "Activado"', (tester) async {
      final cita = _cita(notificacionActiva: true);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Activado'), findsOneWidget);
    });

    testWidgets('recordatorio inactivo muestra "Desactivado"', (tester) async {
      final cita = _cita(notificacionActiva: false);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Desactivado'), findsOneWidget);
    });

    testWidgets('estado completada muestra "Completada"', (tester) async {
      final cita = _cita(completada: true);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Completada'), findsOneWidget);
    });

    testWidgets('estado pendiente muestra "Pendiente"', (tester) async {
      final cita = _cita(completada: false);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => CitaDetailSheet(cita: cita, mascota: _mascota()),
          ),
        ),
      );
      expect(find.text('Pendiente'), findsOneWidget);
    });

    testWidgets('botón Cerrar dispara Navigator.pop', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  // isScrollControlled evita el overflow en el viewport 800×600 del test
                  isScrollControlled: true,
                  builder: (_) =>
                      CitaDetailSheet(cita: _cita(), mascota: _mascota()),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
          navigatorObservers: [_PopObserver(onPop: () => popped = true)],
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
    });
  });

  // ── AddCitaSheet ─────────────────────────────────────────────────────────────

  group('AddCitaSheet', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService fakeFs;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeFs = FirestoreService(fakeFirestore);
    });

    Widget buildSheet({VoidCallback? onSaved}) => _wrap(
      AddCitaSheet(
        mascota: _mascota(),
        onSaved: onSaved ?? () {},
        fsOverride: fakeFs,
      ),
    );

    testWidgets('muestra el título "Nueva Cita"', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      expect(find.text('Nueva Cita'), findsOneWidget);
    });

    testWidgets('muestra los hint texts de los 3 campos de texto', (
      tester,
    ) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      expect(find.text('Motivo (ej: Vacuna, Revisión)'), findsOneWidget);
      expect(find.text('Clínica / Veterinario'), findsOneWidget);
      expect(find.text('Notas adicionales'), findsOneWidget);
    });

    testWidgets('submit sin motivo muestra "Campo obligatorio"', (
      tester,
    ) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      // El botón está debajo del viewport (600px); lo invocamos directamente.
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Agendar Cita'),
      );
      btn.onPressed?.call();
      await tester.pump();
      expect(find.text('Campo obligatorio'), findsOneWidget);
    });

    testWidgets(
      '"Agendar Cita" está habilitado cuando el formulario no está cargando',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pump();
        final btn = find.widgetWithText(ElevatedButton, 'Agendar Cita');
        expect(tester.widget<ElevatedButton>(btn).onPressed, isNotNull);
      },
    );

    testWidgets(
      'muestra 5 ChoiceChips de timing cuando la notificación está activa',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pump();
        for (final label in [
          '1h antes',
          '5h antes',
          '1 día antes',
          '1 semana antes',
          'Personalizado',
        ]) {
          expect(
            find.text(label),
            findsOneWidget,
            reason: 'Chip "$label" debe estar visible',
          );
        }
      },
    );

    testWidgets('ocultar chips de timing al apagar el switch de notificación', (
      tester,
    ) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      // El switch empieza en ON; lo apagamos
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('1h antes'), findsNothing);
      expect(find.text('¿Cuándo recordarte?'), findsNothing);
    });

    testWidgets(
      'seleccionar "Personalizado" muestra el selector de fecha personalizada',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pump();
        await tester.tap(find.text('Personalizado'));
        await tester.pump();
        expect(find.text('Seleccionar fecha y hora'), findsOneWidget);
      },
    );

    testWidgets('ActionChips aparecen si vetConfig tiene veterinarios', (
      tester,
    ) async {
      await fakeFirestore
          .collection('Familias')
          .doc('fam-1')
          .collection('Mascotas')
          .doc('pet-1')
          .collection('Modulos')
          .doc('mod_vet')
          .set({
            'veterinarios': [
              {
                'nombre': 'Dr. García',
                'telefono': '600111222',
                'numColegiado': '',
              },
            ],
            'alergias': [],
          });

      await tester.pumpWidget(buildSheet());
      await tester.pump(); // dispara initState Future
      await tester.pump(); // resuelve el .then() con setState
      expect(find.text('Dr. García'), findsOneWidget);
    });

    testWidgets('tap en ActionChip rellena el campo veterinario', (
      tester,
    ) async {
      await fakeFirestore
          .collection('Familias')
          .doc('fam-1')
          .collection('Mascotas')
          .doc('pet-1')
          .collection('Modulos')
          .doc('mod_vet')
          .set({
            'veterinarios': [
              {'nombre': 'Clínica Test', 'telefono': '', 'numColegiado': ''},
            ],
            'alergias': [],
          });

      await tester.pumpWidget(buildSheet());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Clínica Test'));
      await tester.pump();

      // El segundo TextFormField (veterinario) debe tener el nombre del vet
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[1].controller?.text, 'Clínica Test');
    });

    testWidgets('submit con motivo válido llama a onSaved', (tester) async {
      var saved = false;
      await tester.pumpWidget(buildSheet(onSaved: () => saved = true));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Vacuna rabia');
      // El botón está debajo del viewport; lo invocamos directamente.
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Agendar Cita'),
      );
      btn.onPressed?.call();
      // pumpAndSettle haría timeout porque el SnackBar tiene un timer de 4s.
      // Con un solo pump basta: FakeFirestore resuelve en la cola de microtasks
      // y onSaved() se llama antes del primer frame.
      await tester.pump();
      expect(saved, isTrue);
    });
  });

  // ── Observer helper ───────────────────────────────────────────────────────────

  // ignore: avoid_implementing_value_types
}

class _PopObserver extends NavigatorObserver {
  final VoidCallback onPop;
  _PopObserver({required this.onPop});

  @override
  void didPop(Route route, Route? previousRoute) => onPop();
}
