# Pawner_App

Pawner App es una aplicación Flutter diseñada para organizar el cuidado de mascotas en familia. La app integra Firebase para autenticación, datos en tiempo real, notificaciones y sincronización de usuarios; además usa Cloudinary para subir fotos y `flutter_local_notifications` para recordatorios locales.

## Funcionalidades principales

- Autenticación con Firebase Auth.
- Gestión de familias y roles de usuario (admin/miembro).
- Registro, edición y eliminación de mascotas.
- Módulo de comida: platos, horarios, recordatorios y notificaciones.
- Módulo de paseos: registro de paseos, objetivo diario y recordatorios automáticos.
- Módulo veterinario: citas, historial de salud, datos médicos y alertas.
- Módulo de hábitat: configuración del hábitat, parámetros ideales y limpieza programada.
- Módulo de higiene: rutinas de baño y limpieza personal, historial de higiene y recordatorios.
- Sincronización de email entre Firebase Auth y Firestore.
- Notificaciones push y locales combinadas: FCM + notificaciones en segundo plano.
- Subida de imágenes con Cloudinary.

## Módulos implementados

1. **Familia y usuarios**
   - Crear familia.
   - Unirse a familia.
   - Ver miembros.
   - Administrar roles.

2. **Mascotas**
   - Listado de mascotas por familia.
   - Perfil detallado de mascota.
   - Editar y eliminar mascota.

3. **Comida**
   - Crear platos.
   - Configurar horarios.
   - Activar/desactivar recordatorios.
   - Notificaciones en hora fija.

4. **Paseo**
   - Añadir paseos con duración, observaciones e imagen.
   - Contador diario de paseos.
   - Programación automática de recordatorios.
   - Edición y eliminación de paseos.

5. **Veterinario**
   - Registrar citas veterinarias.
   - Sincronizar recordatorios con citas.
   - Historial de eventos de salud.
   - Perfil médico de la mascota.

6. **Hábitat**
   - Configurar tipo de hábitat.
   - Añadir parámetros ideales.
   - Definir preferencias adicionales.
   - Programar limpieza cada N días.

7. **Higiene**
   - Registrar rutinas de higiene y baño para cada mascota.
   - Agendar recordatorios de limpieza personal.
   - Consultar historial de baños y servicios de higiene.
   - Configurar preferencias de higiene por mascota.

## Estructura del proyecto

- `lib/main.dart`: inicialización de Firebase, Crashlytics, notificaciones y arranque de la app.
- `lib/screens/`: UI y navegación.
- `lib/screens/modulos/higiene/`: pantallas y componentes del módulo de higiene.
- `lib/services/`: lógica de negocio, acceso a Firebase y notificaciones.
- `lib/core/model/`: modelos de datos para mascota, usuario, módulos y recordatorios.
- `lib/core/components/`: componentes comunes de UI.
- `lib/firebase_options.dart`: configuración de Firebase generada.

## Dependencias clave

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `firebase_crashlytics`
- `flutter_local_notifications`, `timezone`, `time_zone_plus`
- `cloudinary_flutter`, `image_picker`
- `flutter_dotenv`
- `http`, `intl`, `url_launcher`
- `share_plus`, `numberpicker`
- `lucide_icons`

## PRIMEROS PASOS

1. Comprueba que tienes Flutter instalado y actualizado.
2. Clona el repositorio localmente.
3. Copia o crea el archivo `.env` con las variables de entorno necesarias.
4. Añade la configuración de Firebase para Android e iOS:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Ejecuta los comandos iniciales:
   ```bash
   flutter pub get
   flutter run
   ```

## Configuración y ejecución

1. Abre el proyecto en tu editor.
2. Confirma que el archivo `.env` existe.
3. Comprueba que los archivos de Firebase están en su lugar.
4. Inicia la app en un emulador o dispositivo real.
   ```bash
   flutter run
   ```

## Flujo de inicio

1. `lib/main.dart` inicializa Flutter, carga `.env`, Firebase, Crashlytics y notificaciones.
2. `FirstScreen` comprueba el estado de sesión de Firebase Auth.
3. Si el usuario ya está logueado, se dirige a `DashboardScreen`; si no, abre el login.

## Notificaciones

- `lib/services/notification_service.dart` administra:
  - notificaciones locales programadas.
  - recordatorios de comida.
  - recordatorios de paseo.
  - recordatorio de limpieza de hábitat.
  - permisos y token FCM.

- `lib/screens/usuario/dashboard_screen.dart` sincroniza notificaciones al cargar datos del usuario.

## Datos y Firestore

- Estructura principal:
  - `Familias/{familiaID}`
  - `Usuarios/{usuarioID}`
  - `Familias/{familiaID}/Mascotas/{mascotaID}`
  - Subcolecciones de módulos de mascotas: `mod_comida`, `mod_paseo`, `mod_vet`, `mod_habitat`, `mod_higiene`.

## Archivos clave

- `lib/services/firestore_service.dart`
- `lib/services/notification_service.dart`
- `lib/screens/usuario/dashboard_screen.dart`
- `lib/screens/mascota/detalle_mascota.dart`
- `lib/screens/modulos/comida/comida_screen.dart`
- `lib/screens/modulos/paseo/paseo_screen.dart`
- `lib/screens/modulos/veterinario/veterinario_screen.dart`
- `lib/screens/modulos/habitat/habitat_screen.dart`
- `lib/screens/modulos/higiene/higiene_screen.dart`

 
