# Plan de Implementación: Cambio de Correo Electrónico

> **Fecha de creación**: 23 de abril de 2026  
> **Última actualización**: 23 de abril de 2026  
> **Aplicación**: Pawner App (Flutter + Firebase)

---

## 📋 Resumen Ejecutivo

Se ha implementado un sistema completo para que el usuario pueda cambiar su correo electrónico. El flujo requiere que el usuario ingrese su **contraseña actual** para confirmar su identidad, y luego recibe un **correo de verificación** en su nueva dirección para completar el cambio.

---

## 🛠️ Archivos Creados y Modificados

### 1. Nuevo Archivo: `change_email_screen.dart`

**Ubicación**: `lib/screens/session/change_email_screen.dart`

**Descripción**: Pantalla completa para el cambio de email con los siguientes componentes:

| Componente | Descripción |
|------------|-------------|
| Campo nuevo email | TextFormField con validación de formato |
| Campo contraseña | TextFormField para reautenticación (obligatorio) |
| Botón confirmar | Envía el correo de verificación |
| Información | Box con instrucciones para el usuario |

**Funcionalidades**:
- ✅ Validación de formato de email
- ✅ Verifica que el nuevo email sea diferente al actual
- ✅ Solicita contraseña para reautenticación
- ✅ Muestra diálogo de éxito con instrucciones claras
- ✅ Maneja errores de Firebase Auth (email en uso, contraseña incorrecta)
- ✅ Campo de contraseña con toggle para mostrar/ocultar

**Flujo**:
```
1. Usuario ingresa nuevo email + contraseña actual
2. Tap en "ENVIAR CORREO DE VERIFICACIÓN"
3. AuthService.reauthenticateWithCredential() → verifica identidad
4. AuthService.verifyBeforeUpdateEmail() → envía enlace al NUEVO email
5. Diálogo informativo: "Se ha enviado un correo a tu nueva dirección"
6. Usuario hace clic en enlace → Firebase completa el cambio
7. Listener en main.dart → sincroniza Firestore automáticamente
```

---

### 2. Modificado: `perfil_screen.dart`

**Ubicación**: `lib/screens/usuario/perfil_screen.dart`

**Cambios realizados**:

| Cambio | Descripción |
|--------|-------------|
| Nuevo import | `import 'package:pawner_app/screens/session/change_email_screen.dart';` |
| Botón editar email | Ahora navega a `ChangeEmailScreen` en lugar de editar en línea |

**Código añadido**:
```dart
// Al hacer clic en el botón de editar email:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChangeEmailScreen(
      currentEmail: emailController.text,
    ),
  ),
);
```

---

### 3. Modificado: `firestore_service.dart`

**Ubicación**: `lib/services/firestore_service.dart`

**Cambios realizados**:

| Método | Descripción |
|--------|-------------|
| `updateEmailOnly()` | Nuevo método para actualizar solo el email en Firestore |

**Código añadido**:
```dart
// UPDATE - Solo email (para sync después de confirmación)
Future<void> updateEmailOnly(String uid, String newEmail) async {
  final docUsuario = FirebaseFirestore.instance
      .collection('Usuarios')
      .doc(uid);

  await docUsuario.update({'email': newEmail});
}
```

---

### 4. Modificado: `main.dart`

**Ubicación**: `lib/main.dart`

**Cambios realizados**:

| Cambio | Descripción |
|--------|-------------|
| Nuevos imports | `firebase_auth` y `cloud_firestore` |
| `_setupEmailSyncListener()` | Nuevo método que escucha cambios en Auth |
| `_syncEmailWithFirestore()` | Sincroniza el email en Firestore cuando cambia en Auth |

**Código añadido**:
```dart
// Listener para sincronizar email en Firestore cuando cambie en Auth
void _setupEmailSyncListener() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      final currentEmail = user.email;
      if (currentEmail != null) {
        await _syncEmailWithFirestore(user.uid, currentEmail);
      }
    }
  });
}

// Sincroniza el email del usuario en Firestore con el de Auth
Future<void> _syncEmailWithFirestore(String uid, String authEmail) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(uid)
        .get();

    if (docSnapshot.exists) {
      final firestoreEmail = docSnapshot.data()?['email'] as String?;
      if (firestoreEmail != null && firestoreEmail.toLowerCase() != authEmail.toLowerCase()) {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(uid)
            .update({'email': authEmail});
      }
    }
  } catch (e) {
    // Silenciar errores de sync - no bloquea la app
  }
}
```

---

## 📄 Flujo Completo de Cambio de Email

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Usuario hace clic en botón editar email en Perfil          │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. Se abre ChangeEmailScreen con:                              │
│    - Correo actual (solo lectura)                              │
│    - Nuevo correo electrónico (input)                         │
│    - Contraseña actual (input, requerida)                      │
│    - Botón "ENVIAR CORREO DE VERIFICACIÓN"                    │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. Usuario ingresa:                                             │
│    - Nuevo email: nuevo@correo.com                              │
│    - Contraseña: ********                                       │
│    - Tap en "ENVIAR CORREO DE VERIFICACIÓN"                   │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. AuthService.changeEmail():                                   │
│    a) Reautenticar con contraseña                              │
│       → EmailAuthProvider.credential()                         │
│       → currentUser.reauthenticateWithCredential()            │
│    b) Enviar verificación al NUEVO email                       │
│       → currentUser.verifyBeforeUpdateEmail(newEmail)         │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Firebase envía correo de verificación a:                   │
│    nuevo@correo.com                                            │
│    (El email NO cambia todavía en Auth)                       │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. Mostrar diálogo de éxito:                                    │
│    "Se ha enviado un correo de verificación a tu nueva        │
│     dirección. Debes hacer clic en el enlace para completar    │
│     el cambio. Mientras no confirmes, seguirás usando tu     │
│     correo actual."                                             │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. Usuario recibe email en nuevo@correo.com                    │
│    → Hace clic en enlace de confirmación                       │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. Firebase actualiza el email en Auth automáticamente        │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. Listener en main.dart detecta cambio:                       │
│    authStateChanges() → dispara _syncEmailWithFirestore()     │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 10. Firestore se sincroniza:                                    │
│     update({'email': nuevo@correo.com})                        │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ 11. Usuario abre la app → Ver nuevo email en perfil            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Seguridad Implementada

| Medida | Descripción |
|--------|-------------|
| **Reautenticación obligatoria** | Firebase requiere contraseña para cambiar email |
| **Verificación en nuevo email** | El enlace se envía a la nueva dirección, no a la actual |
| **No cambia inmediatamente** | El cambio solo se completa tras hacer clic en el correo |
| **Sync automático** | Firestore se actualiza cuando Auth confirma el cambio |

---

## ⚠️ Errores Manejados

| Código de error | Mensaje mostrado |
|-----------------|------------------|
| `invalid-email` | "El correo electrónico no es válido" |
| `email-already-in-use` | "Este correo electrónico ya está en uso" |
| `wrong-password` | "La contraseña es incorrecta" |
| `user-mismatch` | "Las credenciales no coinciden" |
| `invalid-credential` | "Las credenciales no son válidas" |
| Otro | "Error al cambiar el correo. Inténtalo de nuevo." |

---

## ✅ Checklist de Implementación

- [x] 1. Verificar que `AuthService.changeEmail()` funciona correctamente
- [x] 2. Crear `ChangeEmailScreen` con validación de formulario
- [x] 3. Conectar `ChangeEmailScreen` desde `PerfilUsuarioScreen`
- [x] 4. Añadir listener en `main.dart` para sync automático
- [x] 5. Añadir método `updateEmailOnly()` en `FirestoreService`
- [x] 6. Manejar errores de forma amigable
- [ ] 7. Testing del flujo completo

---

## 📚 Referencias

- [AuthService](lib/services/auth_service.dart) - Servicio de autenticación
- [FirestoreService](lib/services/firestore_service.dart) - Servicio de base de datos
- [ChangeEmailScreen](lib/screens/session/change_email_screen.dart) - Nueva pantalla
- [PerfilUsuarioScreen](lib/screens/usuario/perfil_screen.dart) - Pantalla de perfil
- [main.dart](lib/main.dart) - Entry point con listener de sync
- [Modelo Usuario](lib/core/model/usuario.dart) - Modelo de datos de usuario

> **Nota**: Este método envía el correo de verificación al **nuevo email**. El cambio se completa cuando el usuario hace clic en el enlace.

---

### Fase 2: Crear Pantalla de Confirmación de Cambio de Email

**Nueva pantalla**: `lib/screens/session/change_email_screen.dart`

| Campo | Descripción |
|-------|-------------|
| `newEmail` | TextField para el nuevo correo electrónico |
| `currentPassword` | TextField para confirmar identidad |

**Validaciones necesarias:**
- ✅ Formato de email válido
- ✅ Email diferente al actual
- ✅ Email no está en uso (Firebase thrown error)
- ✅ Contraseña correcta (requerida para reautenticación)

---

### Fase 3: Modificar PerfilUsuarioScreen

**Archivo**: [lib/screens/usuario/perfil_screen.dart](lib/screens/usuario/perfil_screen.dart)

**Cambios requeridos:**

1. **Descomentar y conectar el método de cambio de email**:
   ```dart
   // Currently (línea ~340):
   // AuthService().changeEmail(newEmail: u.email, userPassword: ??);
   
   // Should be:
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => ChangeEmailScreen(currentEmail: u.email),
     ),
   );
   ```

2. **Añadir indicador visual** cuando el email no está verificado:
   ```dart
   // Mostrar badge si email no verificado
   if (!currentUser!.emailVerified) {
     return Icon(Icons.warning, color: Colors.orange);
   }
   ```

---

### Fase 4: Sincronizar Firestore después de Confirmación

**Problema detectado**: Cuando el usuario confirma el email desde el correo, la app necesita:

1. **Detectar el cambio**: Escuchar cambios en `authStateChanges`
2. **Actualizar Firestore**: Sincronizar el nuevo email en el documento del usuario

**Implementación sugerida** en `AuthService` o `main.dart`:

```dart
// En main.dart - Añadir listener
firebaseAuth.authStateChanges().listen((User? user) {
  if (user != null) {
    // Verificar si el email cambió y actualizar Firestore
    _syncEmailWithFirestore(user);
  }
});
```

---

### Fase 5: Manejar Estados de Error

| Escenario | Manejo |
|-----------|--------|
| Email ya en uso | Mostrar error: "Este correo ya está registrado" |
| Contraseña incorrecta | Mostrar error: "Contraseña incorrecta" |
| Email inválido | Validación de formato en tiempo real |
| Error de red | Retry con mensaje apropiado |

---

## 🛠️ Archivos a Modificar

| Archivo | Acción |
|---------|--------|
| [lib/services/auth_service.dart](lib/services/auth_service.dart) | ✅ Ya implementado (verificar que funciona) |
| [lib/screens/session/change_email_screen.dart](lib/screens/session/) | **CREAR** - Nueva pantalla |
| [lib/screens/usuario/perfil_screen.dart](lib/screens/usuario/perfil_screen.dart) | **MODIFICAR** - Conectar UI |
| [lib/main.dart](lib/main.dart) | **MODIFICAR** - Añadir sync listener |
| [lib/services/firestore_service.dart](lib/services/firestore_service.dart) | **AÑADIR** - Método updateEmailOnly |

---

## 📄 Flujo Completo de Cambio de Email

```
1. Usuario hace clic en "Cambiar email" en PerfilUsuarioScreen
        ↓
2. Se abre ChangeEmailScreen con:
   - Campo: Nuevo email
   - Campo: Contraseña actual (para reautenticación)
   - Botón: "Confirmar cambio"
        ↓
3. Usuario ingresa nuevo email y contraseña → Tap "Confirmar"
        ↓
4. AuthService.changeEmail(newEmail, password):
   a) Reautenticar con contraseña actual
   b) Enviar correo de verificación al NUEVO email
        ↓
5. Mostrar mensaje: "Se ha enviado un correo de verificación 
   a tu nueva dirección. Haz clic en el enlace para confirmar."
        ↓
6. Usuario recibe email → Hace clic en enlace de confirmación
        ↓
7. Firebase actualiza el email en Auth automáticamente
        ↓
8. Listener en main.dart detecta cambio → Actualiza Firestore
        ↓
9. Usuario abre app → Ver nuevo email en perfil
```

---

## ⚠️ Consideraciones Importantes

1. **Firebase Auth**: El método `verifyBeforeUpdateEmail()` requiere que el nuevo email sea válido y no esté ya en uso.

2. **Seguridad**: La contraseña actual es **obligatoria** para reautenticar — no hay forma de evitar esto en Firebase.

3. **Tiempo de confirmación**: El usuario debe hacer clic en el correo enviado a la **nueva dirección** — no se cambia inmediatamente.

4. **Fallback**: Si el usuario no confirma, el email **no se cambia** en Firebase Auth (comportamiento de seguridad de Firebase).

---

## ✅ Checklist de Implementación

- [ ] 1. Verificar que `AuthService.changeEmail()` funciona correctamente
- [ ] 2. Crear `ChangeEmailScreen` con validación de formulario
- [ ] 3. Conectar `ChangeEmailScreen` desde `PerfilUsuarioScreen`
- [ ] 4. Añadir listener en `main.dart` para sync automático
- [ ] 5. Añadir método `updateEmailOnly()` en `FirestoreService`
- [ ] 6. Manejar errores de forma amigable
- [ ] 7. Testing del flujo completo

---

## 📚 Referencias

- [AuthService](lib/services/auth_service.dart) - Servicio de autenticación
- [FirestoreService](lib/services/firestore_service.dart) - Servicio de base de datos
- [PerfilUsuarioScreen](lib/screens/usuario/perfil_screen.dart) - Pantalla de perfil
- [Modelo Usuario](lib/core/model/usuario.dart) - Modelo de datos de usuario