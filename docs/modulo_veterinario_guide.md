# Guía End-to-End — Módulo Veterinario (`mod_vet`)

> **Audiencia:** Agentes IA y programadores del equipo.  
> **Objetivo:** Entender completamente cómo está construido `mod_vet` para replicar la misma filosofía al implementar nuevos módulos (paseos, higiene, peso, medicamentos…).

---

## 1. Filosofía general del módulo

Cada módulo de Pawner sigue el mismo contrato:

1. **Un documento de configuración** en `Mascotas/{id}/Modulos/{moduloID}` que contiene ajustes persistentes del módulo para esa mascota.
2. **Subcolecciones de datos** bajo ese documento para los registros operativos (citas, horarios, eventos…).
3. **Una pantalla principal** con tabs que separan la vista activa, el historial y la configuración/perfil.
4. **Bottom sheets** para crear/editar registros sin salir de la pantalla principal.
5. **Notificaciones locales** opcionales vinculadas a cada registro, con ID propio almacenado en Firestore para poder cancelarlas desde cualquier dispositivo.

---

## 2. Estructura de datos en Firestore

```
Familias/{familiaID}
  └─ Mascotas/{mascotaID}
       └─ Modulos/
            └─ mod_vet                          ← documento: ModuloVetConfig
                 ├─ Citas/{citaID}              ← subcolección
                 └─ EventosSalud/{eventoID}     ← subcolección
  └─ Recordatorios/{recordatorioID}            ← nivel familia, no mascota
```

**Regla crítica:** nunca acceder a datos de un módulo sin el `familiaID`. Siempre se navega por la jerarquía `Familias → Mascotas → Modulos`.

El helper privado en `FirestoreService` que encapsula la referencia raíz del módulo:

```dart
DocumentReference _modVetDoc(String familiaID, String mascotaID) =>
    _db.collection('Familias').doc(familiaID)
        .collection('Mascotas').doc(mascotaID)
        .collection('Modulos').doc('mod_vet');
```

Todos los métodos del módulo vet en `FirestoreService` parten de `_modVetDoc`.

---

## 3. Modelos (`lib/core/model/modulo_vet/`)

### 3.1 `ModuloVetConfig` — configuración del módulo

Almacenado directamente en el documento `mod_vet`.

```dart
class ModuloVetConfig {
  List<String> alergias;
  List<Map<String, String>> veterinarios; // [{nombre, telefono, numColegiado}]
  String? seguroMedico;
  String? telUrgencias;
}
```

Se guarda con `SetOptions(merge: true)` para no destruir campos que el agente no conoce.

### 3.2 `CitaVeterinaria` — cita pendiente o completada

```dart
class CitaVeterinaria {
  String id;
  DateTime fecha;              // fecha y hora de la cita
  String motivo;
  String? veterinario;
  String? notas;
  bool completada;             // false → tab Citas | true → tab Historial
  bool notificacionActiva;     // controla si hay aviso programado
  int? idNotificacion;         // ID único en NotificationService (null si no aplica)
  String? recordatorioID;      // ID del doc en Familias/.../Recordatorios
  DateTime? notifFechaHora;    // cuándo se disparará el aviso (≠ fecha de cita)
}
```

**Invariantes importantes:**
- `idNotificacion` es `null` si y solo si `notificacionActiva == false` en el momento de creación y si el tiempo de aviso ya había pasado.
- `notifFechaHora` es `null` si el aviso no se pudo programar (tiempo pasado) o si el usuario desactivó las notificaciones.
- `completada` mueve la cita del tab "Citas" al tab "Historial" sin eliminarla.

### 3.3 `EventoSalud` — entrada de historial libre

```dart
class EventoSalud {
  String id;
  String tipo;          // "Vacuna", "Revisión", "Cirugía", etc.
  String descripcion;
  DateTime fecha;
  String? adjuntoUrl;   // URL de Cloudinary (opcional)
  DateTime? proximaDosis;
}
```

Los eventos **no tienen notificaciones**. Son registros pasados o informativos, no acciones futuras.

---

## 4. `FirestoreService` — métodos del módulo vet

### Configuración del módulo

| Método | Retorno | Descripción |
|---|---|---|
| `saveModuloVetConfig(familiaID, mascotaID, config)` | `Future<void>` | Guarda con `merge:true`. Nunca sobreescribe campos ausentes. |
| `getModuloVetConfig(familiaID, mascotaID)` | `Future<ModuloVetConfig?>` | One-shot. Uso: carga inicial del formulario de edición. |
| `streamModuloVetConfig(familiaID, mascotaID)` | `Stream<ModuloVetConfig?>` | Tiempo real. Uso: tab Perfil. |

### Citas

| Método | Retorno | Descripción |
|---|---|---|
| `getCitasVeterinarias(familiaID, mascotaID)` | `Future<List<CitaVeterinaria>>` | One-shot. Usado por el sync de notificaciones en dashboard. |
| `streamCitasVeterinarias(familiaID, mascotaID)` | `Stream<List<CitaVeterinaria>>` | Tiempo real, ordenado por `fecha` asc. Uso: tabs Citas e Historial. |
| `addCitaVeterinaria(familiaID, mascotaID, cita)` | `Future<void>` | **WriteBatch**: crea la cita y su `Recordatorio` en la familia atómicamente. |
| `updateCitaVeterinaria(familiaID, mascotaID, cita)` | `Future<void>` | Actualiza el documento completo. |
| `deleteCitaVeterinaria(familiaID, mascotaID, citaId)` | `Future<void>` | Solo borra la cita. Para citas sin recordatorio. |
| `deleteCitaVeterinariaWithReminder(familiaID, mascotaID, citaId, recordatorioId)` | `Future<void>` | **WriteBatch**: borra cita y su recordatorio familiar atómicamente. |

### Eventos de salud

| Método | Retorno | Descripción |
|---|---|---|
| `streamEventosSalud(familiaID, mascotaID)` | `Stream<List<EventoSalud>>` | Tiempo real, ordenado por `fecha` desc. |
| `addEventoSalud(familiaID, mascotaID, evento)` | `Future<void>` | CRUD estándar. |
| `deleteEventoSalud(familiaID, mascotaID, eventoId)` | `Future<void>` | CRUD estándar. |

---

## 5. Arquitectura de `VeterinarioScreen`

### 5.1 Estructura de la pantalla

```
VeterinarioScreen (StatefulWidget)
│
├─ State: _VeterinarioScreenState (with SingleTickerProviderStateMixin)
│    ├─ _tabController: TabController (3 tabs)
│    ├─ _fs: FirestoreService
│    └─ _notifications: NotificationService
│
├─ build() → StreamBuilder<Mascota>  ← siempre usa datos live de la mascota
│    └─ Scaffold
│         ├─ AppBar (transparente + TabBar)
│         ├─ TabBarView
│         │    ├─ Tab 0: _buildCitasTab()
│         │    ├─ Tab 1: _buildHistorialTab()
│         │    └─ Tab 2: _buildPerfilTab()
│         └─ FloatingActionButton (oculto en tab Perfil)
│
├─ Bottom sheets (modal, isScrollControlled: true)
│    ├─ CitaDetailSheet (público — solo lectura)
│    ├─ AddCitaSheet (público — creación, testeable)
│    ├─ _AddEventoSheet (privado)
│    └─ _EditPerfilSheet (privado)
```

### 5.2 Por qué el `build` envuelve todo en un `StreamBuilder<Mascota>`

La pantalla recibe una `Mascota` como parámetro, pero los datos de la mascota pueden cambiar mientras el usuario está en la pantalla (otro miembro edita el peso, por ejemplo). En lugar de guardar `widget.mascota` en estado local, se suscribe a `streamMascota` y usa `snapshotMascota.data ?? widget.mascota` como fallback mientras carga.

```dart
return StreamBuilder<Mascota>(
  stream: _fs.streamMascota(widget.mascota.familiaID, widget.mascota.mascotaID),
  builder: (context, snapshotMascota) {
    final currentMascota = snapshotMascota.data ?? widget.mascota;
    // ... toda la UI usa currentMascota, no widget.mascota
  },
);
```

**Este patrón debe replicarse en todos los módulos** para que la UI refleje siempre el estado actual de Firestore.

### 5.3 AppBar con tabs — patrón estético

```dart
AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  surfaceTintColor: Colors.transparent,   // elimina el tinte de Material 3
  leading: IconButton(
    icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
    onPressed: () => Navigator.pop(context),
  ),
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Icono temático del módulo en círculo lavanda
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.lightSecondary.withAlpha(70),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.stethoscope, size: 16, color: AppColors.secondary),
      ),
      const SizedBox(width: 10),
      Text("Salud · ${currentMascota.nombre}", ...),
    ],
  ),
  bottom: TabBar(
    indicatorColor: AppColors.secondary,
    indicatorWeight: 3,
    dividerColor: Colors.transparent,   // elimina la línea bajo el TabBar
    labelColor: AppColors.secondary,
    unselectedLabelColor: Colors.grey,
    ...
  ),
)
```

### 5.4 FAB contextual por tab

El FAB se oculta en el tab de configuración/perfil y cambia su acción según el tab activo:

```dart
floatingActionButton: AnimatedBuilder(
  animation: _tabController,
  builder: (context, child) {
    if (_tabController.index == 2) return const SizedBox.shrink(); // oculto en Perfil
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 0) {
          _showAddCitaSheet(currentMascota);    // Tab Citas
        } else {
          _showAddEventoSheet(currentMascota);  // Tab Historial
        }
      },
      backgroundColor: AppColors.homeScreenOrange,
      child: const Icon(LucideIcons.plus, color: Colors.white),
    );
  },
)
```

---

## 6. Tab Citas — flujo completo

### 6.1 Fuente de datos

```dart
StreamBuilder<List<CitaVeterinaria>>(
  stream: _fs.streamCitasVeterinarias(familiaID, mascotaID),
  builder: (context, snapshot) {
    final citas = snapshot.data!.where((c) => !c.completada).toList();
    // ...
  },
)
```

El stream devuelve TODAS las citas ordenadas por fecha. El filtro `!c.completada` es en cliente.

### 6.2 Anatomía de `_buildCitaCard`

La card tiene dos zonas:

**Zona superior** — información de la cita:
```
[Badge fecha]  [Motivo bold]
               [🕓 HH:mm]
               [📍 Clínica (opcional)]    [✓ Botón completar]
```

- Badge: contenedor lavanda (52px ancho), día en bold 22px + mes abreviado 10px
- El botón ✓ marca `cita.completada = true` y llama a `updateCitaVeterinaria`. La cita desaparece del tab Citas y aparece en Historial automáticamente por el stream.

**Zona inferior** (franja `AppColors.homeScreenBackground`):
```
[🔔 Recordatorio activo / Sin aviso]    [Switch]  [🗑]
```

- El Switch llama a `_toggleNotificacion(cita, value, mascota)`.
- El icono de papelera llama a `_eliminarCita`.

**Tap en la card completa** abre `CitaDetailSheet` vía `showModalBottomSheet`.

### 6.3 Crear una cita — `AddCitaSheet`

El flujo de `_guardar()`:

```
1. Validar formulario (motivo obligatorio)
2. Construir fechaHora = fecha + hora seleccionadas
3. Calcular notifDateTime:
   a. Si notificaciones desactivadas → null
   b. Si timing seleccionado y la fecha calculada ya pasó → null
   c. Si fecha calculada es futura → válida
4. idNotificacion:
   - Solo se genera si notificacionActiva == true Y notifDateTime != null
   - Generado con: DateTime.now().millisecondsSinceEpoch % 100000
5. Construir CitaVeterinaria con:
   - notificacionActiva = _notificacionActiva && notifDateTime != null
   - idNotificacion = (generado o null)
   - notifFechaHora = notifDateTime (o null)
6. FirestoreService.addCitaVeterinaria() → WriteBatch (cita + Recordatorio)
7. Si notifDateTime válido → NotificationService.scheduleOneTimeNotification()
8. SnackBar:
   - Éxito normal: "¡Cita agendada con éxito!"
   - Notif no programada: "¡Cita agendada! El recordatorio no se programó (fecha ya pasada)"
```

**Por qué `idNotificacion` se calcula después de `notifDateTime`:**
Si se generara antes, quedaría un ID no-nulo en Firestore aunque no haya notificación real. Eso causaría que el toggle mostrara "Activado" (tiene ID) pero sin aviso real programado.

### 6.4 Timing del aviso — `NotifTiming`

```dart
enum NotifTiming { horasBefore1, horasBefore5, diaBefore, semanaBefore, personalizado }

DateTime? computeNotifDateTime(NotifTiming timing, DateTime citaDateTime, {DateTime? custom}) {
  switch (timing) {
    case NotifTiming.horasBefore1:  return citaDateTime.subtract(Duration(hours: 1));
    case NotifTiming.horasBefore5:  return citaDateTime.subtract(Duration(hours: 5));
    case NotifTiming.diaBefore:     return citaDateTime.subtract(Duration(days: 1));
    case NotifTiming.semanaBefore:  return citaDateTime.subtract(Duration(days: 7));
    case NotifTiming.personalizado: return custom;
  }
}
```

En el formulario el usuario puede elegir un chip de timing o "Personalizado" (abre un date/time picker). Si elige "Personalizado" pero no selecciona fecha, `custom` es `null` y `notifDateTime` queda `null`.

---

## 7. Lógica de notificaciones — detalle crítico

### 7.1 Crear cita con notificación

```
notifDateTime válido (futuro)
  → notificacionActiva = true
  → idNotificacion = X
  → notifFechaHora = notifDateTime
  → scheduleOneTimeNotification(id: X, scheduledFor: notifDateTime)
  → Firestore guarda los 3 campos

notifDateTime pasado o null
  → notificacionActiva = false
  → idNotificacion = null
  → notifFechaHora = null
  → NO se llama a scheduleOneTimeNotification
```

### 7.2 Toggle ON desde la card

```dart
void _toggleNotificacion(CitaVeterinaria cita, bool value, Mascota mascota) {
  if (value) {
    final notifTime = cita.notifFechaHora; // NO cae back a cita.fecha
    if (notifTime == null || !notifTime.isAfter(DateTime.now())) {
      // El momento original del aviso ya pasó → rechazar con SnackBar naranja
      // El switch NO cambia de estado
      return;
    }
    // Activar: actualizar estado + Firestore + schedule
  } else {
    // Desactivar: actualizar estado + Firestore + cancel
  }
}
```

**Regla importante:** al activar, se usa `cita.notifFechaHora` (el momento exacto del aviso guardado en Firestore), **nunca** `cita.fecha` (la hora de la cita). Esto evita programar el aviso en la hora de la cita en lugar del momento planeado.

### 7.3 Eliminar cita

```dart
// Si tiene recordatorio familiar asociado → WriteBatch (cita + recordatorio)
if (cita.recordatorioID != null) {
  _fs.deleteCitaVeterinariaWithReminder(familiaID, mascotaID, cita.id, cita.recordatorioID!);
} else {
  _fs.deleteCitaVeterinaria(familiaID, mascotaID, cita.id);
}
// Siempre cancelar la notificación local si existe
if (cita.idNotificacion != null) {
  _notifications.cancel(cita.idNotificacion!);
}
```

### 7.4 Sync cross-device al abrir la app

Las notificaciones son locales (`flutter_local_notifications`), no FCM. Solo el dispositivo que crea la cita la programa inicialmente. Para que todos los miembros las reciban:

`DashboardScreen._loadInitialData()` lanza (fire-and-forget) `_sincronizarNotificaciones(familiaID)`:

```
Para cada mascota de la familia:
  Para cada cita donde:
    - notificacionActiva == true
    - idNotificacion != null
    - notifFechaHora está en el futuro
  → scheduleOneTimeNotification(id, scheduledFor, title, body)
```

`scheduleOneTimeNotification` con el mismo ID sobreescribe si ya existía, por lo que el sync es idempotente. La limitación es que el miembro debe abrir la app al menos una vez antes de que llegue la hora del aviso.

---

## 8. Tab Historial — fuente de datos combinada

El historial mezcla dos colecciones en un mismo `ListView`:

```dart
StreamBuilder<List<EventoSalud>>(
  stream: _fs.streamEventosSalud(...),
  builder: (ctx, snapshotEv) {
    return StreamBuilder<List<CitaVeterinaria>>(
      stream: _fs.streamCitasVeterinarias(...),
      builder: (ctx, snapshotCi) {
        final citasCompletadas = snapshotCi.data!.where((c) => c.completada).toList();
        final items = [...snapshotEv.data!, ...citasCompletadas];
        items.sort((a, b) => fechaB.compareTo(fechaA)); // desc
        // ...
      },
    );
  },
)
```

**Patrón doble StreamBuilder anidado** para combinar dos streams heterogéneos. Solo se renderiza cuando ambos tienen datos.

### 8.1 Eliminar un evento — confirmación obligatoria

Los eventos no tienen notificaciones asociadas, por lo que la eliminación es más sencilla que la de citas. Aun así, se muestra un `AlertDialog` de confirmación antes de borrar:

```dart
void _eliminarEvento(String eventoId, Mascota mascota) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Eliminar Evento"),
      content: const Text("¿Estás seguro de que quieres eliminar este evento?"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        TextButton(
          onPressed: () {
            _fs.deleteEventoSalud(mascota.familiaID, mascota.mascotaID, eventoId);
            Navigator.pop(context);
          },
          child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}
```

A diferencia de `_eliminarCita`, aquí no hay WriteBatch (los eventos no crean `Recordatorio` en la familia) ni cancelación de notificación.

### 8.2 `_buildTimelineItem` — render polimórfico

El método recibe `dynamic item` y `bool isEvento` para extraer los datos correctamente:

```dart
final titulo = isEvento ? evento.tipo : cita.motivo;
final desc   = isEvento ? evento.descripcion : cita.notas ?? "Cita completada";
```

Estéticamente es un timeline vertical: punto azul + línea gris + card blanca.

---

## 9. Tab Perfil — `ModuloVetConfig`

El perfil médico se carga con `streamModuloVetConfig` y se divide en secciones:

| Sección | Widget | Fuente |
|---|---|---|
| Cabecera mascota | `_buildMascotaHeaderCard` | modelo `Mascota` |
| Información crítica | `_buildInfoCard` (peso, seguro) | `Mascota.peso` + `config.seguroMedico` |
| Alergias | `_buildAlergiasCard` | `config.alergias` (List<String>) |
| Contacto veterinario | `_buildVeteCard` | `config.veterinarios` (List<Map>) |
| Urgencias | `_buildEmergencyButton` | `config.telUrgencias` |

El botón de cada veterinario lanza `launchUrl(Uri.parse('tel:...'))`. Requiere en `AndroidManifest.xml`:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.DIAL"/>
    <data android:scheme="tel"/>
  </intent>
</queries>
```

La edición del perfil abre `_EditPerfilSheet` con formularios dinámicos para añadir/quitar veterinarios y alergias.

---

## 10. Clases públicas vs. privadas — convención de visibilidad

En Dart, el prefijo `_` hace una clase o función privada a la biblioteca. Esto afecta directamente a los tests.

| Clase | Visibilidad | Motivo |
|---|---|---|
| `VeterinarioScreen` | Pública | Punto de entrada, navegado desde otras pantallas |
| `CitaDetailSheet` | **Pública** | Necesita ser instanciada en widget tests |
| `AddCitaSheet` | **Pública** | Necesita ser instanciada en widget tests |
| `_AddEventoSheet` | Privada | No tiene tests de widget propios |
| `_EditPerfilSheet` | Privada | No tiene tests de widget propios |
| `_VetEntry` | Privada | Helper interno del formulario de edición |
| `computeNotifDateTime` | **Pública (top-level)** | Reutilizable y testeable de forma aislada |
| `NotifTiming` | **Público (enum top-level)** | Necesario para `computeNotifDateTime` |

**Regla:** si un widget va a ser testeado con `flutter_test`, debe ser público. Si solo se usa dentro del archivo, puede ser privado.

---

## 11. Inyección de dependencia para tests — patrón `fsOverride`

`AddCitaSheet` necesita escribir en Firestore. Para testear sin Firebase real:

```dart
class AddCitaSheet extends StatefulWidget {
  final Mascota mascota;
  final VoidCallback onSaved;
  final FirestoreService? fsOverride; // ← parámetro de inyección

  const AddCitaSheet({required this.mascota, required this.onSaved, this.fsOverride});
}

class _AddCitaSheetState extends State<AddCitaSheet> {
  // Getter: usa override si existe, instancia real si no
  FirestoreService get _fs => widget.fsOverride ?? FirestoreService();
}
```

`FirestoreService` acepta un Firestore inyectable en su constructor:

```dart
class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;
}
```

En el test:

```dart
final fakeFirestore = FakeFirebaseFirestore(); // del paquete fake_cloud_firestore
final fakeFs = FirestoreService(fakeFirestore);
AddCitaSheet(mascota: _mascota(), onSaved: () {}, fsOverride: fakeFs)
```

---

## 12. Widget tests — `veterinario_widget_test.dart`

Archivo: `test/widget/veterinario_widget_test.dart`

### Problemas conocidos del entorno de test y sus soluciones

| Problema | Causa | Solución |
|---|---|---|
| Clase no accesible | Prefijo `_` en el nombre | Quitar el `_` de la clase que se quiere testear |
| `pumpAndSettle` no termina | SnackBar con timer de 4s sigue pidiendo frames | Usar `await tester.pump()` en su lugar |
| `tester.tap()` no encuentra el botón | El botón está debajo del viewport de 600px | Usar `btn.onPressed?.call()` directamente |
| `RenderFlex overflow` en bottom sheet | El contenido supera el alto por defecto del sheet | Pasar `isScrollControlled: true` en el test |
| Locale 'es' no inicializado | `DateFormat` lanza excepción | Llamar `await initializeDateFormatting('es', null)` en `setUpAll` |

### Estructura de los tests

```dart
group('CitaDetailSheet', () {
  setUpAll(() async => await initializeDateFormatting('es', null));

  testWidgets('muestra motivo y fecha', (tester) async {
    await tester.pumpWidget(_wrap(
      Builder(builder: (ctx) => CitaDetailSheet(cita: _cita(), mascota: _mascota())),
    ));
    expect(find.text('Revisión anual'), findsOneWidget);
  });
});

group('AddCitaSheet', () {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService fakeFs;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeFs = FirestoreService(fakeFirestore);
  });

  testWidgets('submit con motivo llama onSaved', (tester) async {
    var saved = false;
    await tester.pumpWidget(buildSheet(onSaved: () => saved = true));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'Vacuna rabia');
    final btn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Agendar Cita'));
    btn.onPressed?.call(); // tap directo porque el botón está fuera del viewport
    await tester.pump(); // pump único: FakeFirestore es síncrono
    expect(saved, isTrue);
  });
});
```

---

## 13. Eliminación en cascada de una mascota

Cuando se elimina una mascota, `FirestoreService.eliminarMascota()` borra en un único `WriteBatch`:

1. Todas las citas (y cancela sus notificaciones locales)
2. Todos los eventos de salud
3. Todos los platos y horarios de comida (y cancela sus notificaciones)
4. Todos los recordatorios familiares vinculados a esa mascota
5. El documento de la mascota

El método devuelve `List<int>` con los IDs de notificación a cancelar. El caller (pantalla) llama a `NotificationService().cancel(id)` por cada uno.

```dart
final notifIds = await fs.eliminarMascota(mascota.familiaID, mascota.mascotaID);
final ns = NotificationService();
for (final id in notifIds) ns.cancel(id);
```

---

## 14. Cómo replicar este módulo para uno nuevo

Al implementar, por ejemplo, `mod_paseos`:

### Paso 1 — Modelos

Crear en `lib/core/model/modulo_paseos/`:
- `paseo_model.dart` — el registro operativo (análogo a `CitaVeterinaria`)
- `modulo_paseos_config.dart` — la configuración del módulo (análogo a `ModuloVetConfig`)

### Paso 2 — FirestoreService

Añadir helper de referencia:
```dart
DocumentReference _modPaseosDoc(String familiaID, String mascotaID) =>
    _db.collection('Familias').doc(familiaID)
        .collection('Mascotas').doc(mascotaID)
        .collection('Modulos').doc('mod_paseos');
```

Añadir métodos: `saveConfig`, `streamConfig`, `streamPaseos`, `addPaseo`, `deletePaseo`, etc.

### Paso 3 — Pantalla principal

Crear `lib/screens/modulos/paseos/paseos_screen.dart` siguiendo la estructura:

```
PaseosScreen (StatefulWidget, recibe Mascota)
  └─ build() → StreamBuilder<Mascota>   ← siempre datos live
       └─ Scaffold
            ├─ AppBar transparente + icono temático + TabBar
            ├─ TabBarView (Registros | Historial | Configuración)
            └─ FAB (oculto en tab Configuración)
```

### Paso 4 — Notificaciones (si aplica)

Si el módulo tiene notificaciones:
- Añadir `idNotificacion` (int?) y `notifFechaHora` (DateTime?) al modelo del registro
- Calcular `notifDateTime` ANTES de generar `idNotificacion`
- Generar `idNotificacion` solo si `notifDateTime != null`
- En el toggle ON: rechazar si `notifFechaHora` es null o pasada, con SnackBar naranja
- Añadir el fetch de este módulo al sync de `_sincronizarNotificaciones` en `DashboardScreen`

### Paso 5 — Tests

Hacer públicas las clases de bottom sheet que se vayan a testear (quitar `_`). Aplicar el patrón `fsOverride` en los StatefulWidgets que usen `FirestoreService`.

### Paso 6 — Cascada al eliminar mascota

Añadir en `FirestoreService.eliminarMascota()` los fetches y deletes de las subcolecciones del nuevo módulo dentro del `WriteBatch` existente.

---

## 15. Bug conocido — notificaciones de horarios de comida

`scheduleFixedTimeNotification` en `NotificationService` usa siempre el ID hardcoded `1`. El `idNotificacion` almacenado en `HorarioComida` en Firestore es un valor generado aleatoriamente que **nunca coincide** con el `1`. Como consecuencia:

- `cancel(horario.idNotificacion)` nunca cancela la notificación real
- Solo puede existir una notificación de horario activa a la vez (la última sobrescribe)
- Los horarios no pueden sincronizarse entre dispositivos

**No replicar este patrón.** Si un módulo nuevo tiene notificaciones recurrentes diarias, `scheduleFixedTimeNotification` debe refactorizarse para aceptar un `id` externo.

---

## 16. Resumen de invariantes a mantener siempre

| Invariante | Descripción |
|---|---|
| `familiaID` como namespace | Nunca acceder a datos de módulo sin el `familiaID` |
| `notificacionActiva ↔ idNotificacion` | Si `notificacionActiva == true`, `idNotificacion` debe ser no-null y viceversa |
| `notifFechaHora` como fuente de verdad | El toggle siempre lee `notifFechaHora`, nunca `fecha` de la cita |
| WriteBatch para operaciones atómicas | Crear/eliminar cita + recordatorio siempre en batch |
| `merge: true` en config | `saveModuloVetConfig` nunca destruye campos desconocidos |
| Clases públicas para tests | Cualquier widget que se testee no puede tener prefijo `_` |
| Fire-and-forget en notificaciones | Nunca bloquear el flujo de guardado por un error de notificación |
| `isScrollControlled: true` en sheets | Todos los `showModalBottomSheet` del módulo deben usar esta opción para evitar overflow |
