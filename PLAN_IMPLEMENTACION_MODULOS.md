# Plan de Implementación - Módulos Limpieza, Calor y Comportamiento

**Fecha de actualización**: 12 de mayo de 2026  
**Estado General**: ~70% completado (modelos y estructura base listos, falta integración UI y correcciones)

---

## 📋 Resumen Ejecutivo

Se han creado **3 nuevos módulos especializados** para la app Pawner que funcionan con múltiples especies de animales:

1. **Módulo Limpieza** - Higiene y cuidados de pelaje
2. **Módulo Calor** - Control de temperatura (para reptiles, peces, etc.)
3. **Módulo Comportamiento** - Seguimiento de conducta y adiestramiento

### Estructura Completada ✅
- Modelos de datos (7 archivos) con `toMap()/fromMap()`
- Configuraciones por especie en clases estáticas
- Pantallas UI con StreamBuilder y diálogos
- Métodos Firestore en `firestore_service.dart` (18 métodos)
- Imports correctos en todas partes

### Estructura Pendiente ⚠️
- Integración en `detalle_mascota.dart` (navigation)
- Corrección de errores de compilación menores
- Pruebas funcionales end-to-end
- Real-time updates verification

---

## 📁 Archivos Creados

### Modelos de Datos (lib/core/model/)

#### **Módulo Limpieza**
```
lib/core/model/modulo_limpieza/
├── sesion_limpieza.dart              ✅ CREADO
│   └── SesionLimpieza(id, mascotaID, tipo, fecha, notas, duracionMinutos, completada, productoUsado)
│   └── Tipos soportados: Baño, Cepillado, Limpieza de orejas, Corte de uñas
│
└── modulo_limpieza_config.dart       ✅ CREADO
    └── ModuloLimpiezaConfig (tiposActivos, notificacionesActivas, frecuenciaDiasRecomendados)
    └── getDefaultFrecuencia(especie) - Frecuencias recomendadas por especie
        - Perro: Baño(30d), Cepillado(2d), Limpieza orejas(14d), Corte uñas(30d)
        - Gato: Baño(60d), Cepillado(3d), Limpieza orejas(30d), Corte uñas(21d)
        - Conejo, Hurón, etc.
```

#### **Módulo Calor**
```
lib/core/model/modulo_calor/
├── monitoreo_temperatura.dart        ✅ CREADO
│   └── MonitoreoTemperatura(id, mascotaID, fecha, temperaturaActual, 
│                             temperaturaOptimaMin/Max, tipo, dentibroPrendido, notas)
│   └── Propiedad: temperaturaEnRango (bool) - validación automática
│
└── modulo_calor_config.dart          ✅ CREADO
    └── ModuloCalorConfig (temperaturaOptimaMin/Max, tipo, notificacionesActivas, monitoreoActivo)
    └── getDefaultForSpecie(especie) - Rangos por especie
        - Tortuga: 25-30°C (Lámara de calor)
        - Serpiente: 26-32°C (Almohadilla térmica)
        - Lagarto: 24-30°C (Lámara de calor)
        - Cocodrilo: 28-35°C (Lámara de calor)
        - Pez: 22-28°C (Calentador submergible)
```

#### **Módulo Comportamiento**
```
lib/core/model/modulo_comportamiento/
├── registro_comportamiento.dart      ✅ CREADO
│   └── RegistroComportamiento(id, mascotaID, fecha, tipo, descripcion, 
│                               categoria, intensidad, detonante, resolucion, notas)
│   └── tipo: Positivo, Negativo, Neutral
│   └── intensidad: 1-10 scale
│
├── ejercicio_adiestramiento.dart     ✅ CREADO
│   └── EjercicioAdiestramiento(id, mascotaID, nombre, descripcion, dificultad, 
│                                objetivo, fechaInicio, fechaTermino, completado, progreso, notas)
│   └── progreso: 0-100 percentage
│
└── modulo_comportamiento_config.dart ✅ CREADO
    └── ModuloComportamientoConfig (categoriasActivas, notificacionesActivas, 
                                     registroAutomatico, diasHistorialGuardado)
    └── getCategoriasPorEspecie(especie) - Categorías por animal
        - Perro: [Agresión, Ansiedad, Juego, Obediencia, Socialización, Miedos, Destrozo, Ladridos]
        - Gato: [Agresión, Ansiedad, Juego, Arañazos, Miedos, Comportamiento territorial, Movimiento excesivo]
        - Pájaro: [Agresión, Ansiedad, Vocalizaciones, Arrancarse plumas, Juego, Socialización]
        - Conejo: [Agresión, Ansiedad, Juego, Apatía, Miedos, Comportamiento territorial]
```

### Pantallas UI (lib/screens/modulos/)

```
lib/screens/modulos/
├── limpieza/
│   └── limpieza_screen.dart          ✅ CREADO
│       └── Widgets: _buildFrecuenciaRecomendada(), _buildTiposActivosCards(), 
│           _buildHistorialSeccion(), _BuildDialogoNuevaLimpieza
│       └── FloatingActionButton: agregar nueva sesión
│       └── Firestore calls: getConfig, streamSesiones, guardarSesion
│
├── calor/
│   └── calor_screen.dart             ✅ CREADO
│       └── Widgets: _buildRangoOptimo(), _buildConfiguracionEquipo(), 
│           _buildMonitoreoReciente(), _DialogoTemperatura
│       └── FloatingActionButton: registrar temperatura
│       └── Firestore calls: getConfig, streamMonitoreo, guardarMonitoreo
│
└── comportamiento/
    └── comportamiento_screen.dart    ✅ CREADO
        └── Widgets: _buildCategoriasCard(), _buildResumenComportamiento(), 
            _buildHistorialReciente(), _DialogoNuevoRegistro
        └── FloatingActionButton: registrar comportamiento
        └── Firestore calls: getConfig, streamRegistros, guardarRegistro
```

### Métodos Firestore (lib/services/firestore_service.dart)

```
✅ AGREGADOS (18 métodos nuevos):

--- MÓDULO LIMPIEZA (6 métodos) ---
- DocumentReference _modLimpiezaDoc(familiaID, mascotaID)
- Future<ModuloLimpiezaConfig?> getModuloLimpiezaConfig(...)
- Future<void> saveModuloLimpiezaConfig(...)
- Stream<List<SesionLimpieza>> streamSesionesLimpieza(...)
- Future<void> guardarSesionLimpieza(...)
- Future<void> actualizarSesionLimpieza(...)
- Future<void> eliminarSesionLimpieza(...)

--- MÓDULO CALOR (6 métodos) ---
- DocumentReference _modCalorDoc(familiaID, mascotaID)
- Future<ModuloCalorConfig?> getModuloCalorConfig(...)
- Future<void> saveModuloCalorConfig(...)
- Stream<List<MonitoreoTemperatura>> streamMonitoreoTemperatura(...)
- Future<void> guardarMonitoreoTemperatura(...)
- Future<void> actualizarMonitoreoTemperatura(...)
- Future<void> eliminarMonitoreoTemperatura(...)

--- MÓDULO COMPORTAMIENTO (6 métodos) ---
- DocumentReference _modComportamientoDoc(familiaID, mascotaID)
- Future<ModuloComportamientoConfig?> getModuloComportamientoConfig(...)
- Future<void> saveModuloComportamientoConfig(...)
- Stream<List<RegistroComportamiento>> streamRegistrosComportamiento(...)
- Future<void> guardarRegistroComportamiento(...)
- Stream<List<EjercicioAdiestramiento>> streamEjerciciosAdiestramiento(...)
- Future<void> guardarEjercicioAdiestramiento(...)
```

---

## 🔴 Tareas Pendientes (Orden de Prioridad)

### 1. **CRÍTICO: Verificar errores de compilación** (30 min)
   - [ ] Ejecutar `flutter analyze` en toda la app
   - [ ] Revisar `lib/screens/mascota/detalle_mascota.dart` (error de syntax reportado en conversión anterior)
   - [ ] Revisar todas las pantallas nuevas por imports faltantes
   - [ ] Verificar que las clases de modelos tienen `toMap()` y `fromMap()` correctamente

   **Comandos a ejecutar**:
   ```bash
   flutter analyze
   flutter pub get
   ```

### 2. **IMPORTANTE: Integración en detalle_mascota.dart** (45 min)
   - [ ] Abrir `lib/screens/mascota/detalle_mascota.dart`
   - [ ] Agregar 3 nuevos navigation chips para los módulos (similar a "Comida" y "Veterinario")
   - [ ] Implementar Navigation hacia las 3 nuevas pantallas:
     ```dart
     _ChipNavegacion('Limpieza', Icons.cleaning_services, () {
       Navigator.push(context, MaterialPageRoute(
         builder: (_) => LimpiezaScreen(mascota: mascota, familiaID: familiaID)
       ));
     }),
     _ChipNavegacion('Calor', Icons.thermostat, () {
       Navigator.push(context, MaterialPageRoute(
         builder: (_) => CalorScreen(mascota: mascota, familiaID: familiaID)
       ));
     }),
     _ChipNavegacion('Comportamiento', Icons.psychology, () {
       Navigator.push(context, MaterialPageRoute(
         builder: (_) => ComportamientoScreen(mascota: mascota, familiaID: familiaID)
       ));
     }),
     ```
   - [ ] Verificar que `detalle_mascota.dart` está usando StreamBuilder para updates en tiempo real

### 3. **IMPORTANTE: Fixes menores en pantallas** (30 min)
   - [ ] **limpieza_screen.dart**: Revisar que `_BuildDialogoNuevaLimpieza` cierre correctamente dialogs
   - [ ] **calor_screen.dart**: Revisar que `_DialogoTemperatura` maneje validaciones de temperatura
   - [ ] **comportamiento_screen.dart**: Revisar que `_DialogoNuevoRegistro` tiene slider para intensidad (1-10)
   - [ ] Todos los dialogs deben tener botones Cancel/Guardar funcionando

### 4. **IMPORTANTE: Inicialización de configuraciones** (30 min)
   - [ ] Crear función en `firestore_service.dart` para inicializar configs por defecto:
     ```dart
     Future<void> initializeModuleConfigs(
       String familiaID, 
       String mascotaID, 
       String especie
     ) async {
       // Si no existe config de limpieza, crear con defaults de la especie
       if (await getModuloLimpiezaConfig(familiaID, mascotaID) == null) {
         final defaultLimpieza = ModuloLimpiezaConfig(
           tiposActivos: ['Baño', 'Cepillado'],
           notificacionesActivas: true,
           frecuenciaDiasRecomendados: ModuloLimpiezaConfig.getDefaultFrecuencia(especie),
         );
         await saveModuloLimpiezaConfig(familiaID, mascotaID, defaultLimpieza);
       }
       // Similar para calor y comportamiento
     }
     ```
   - [ ] Llamar esta función cuando se crea una nueva mascota (en `mascota_service.dart` o similar)

### 5. **MODERADO: Testing funcional** (1+ hora)
   - [ ] Probar crear mascota de diferentes especies
   - [ ] Verificar que configs cargadas tienen valores por defecto correctos
   - [ ] Agregar sesión de limpieza → verificar que aparece en historial
   - [ ] Agregar monitoreo temperatura → verificar que calcula `temperaturaEnRango` correctamente
   - [ ] Agregar registro comportamiento → verificar que suma/contador de positivos/negativos funciona
   - [ ] Modificar datos en otro dispositivo → verificar updates en tiempo real con StreamBuilder
   - [ ] Verificar navigation desde `detalle_mascota.dart` a nuevas pantallas

### 6. **MODERADO: Optimizaciones** (30 min)
   - [ ] Agregar límite de registros históricos (últimos 50-100) en streams para no sobrecargar
   - [ ] Implementar pull-to-refresh en las pantallas nuevas
   - [ ] Agregar empty states cuando no hay registros
   - [ ] Considerarotas especies adicionales si es necesario

### 7. **MENOR: Polish UI** (1+ hora)
   - [ ] Revisar iconografía (lucide_icons vs Material Icons)
   - [ ] Consistencia de colores con AppColors
   - [ ] Responsive design en tablets/desktop
   - [ ] Animaciones en transiciones
   - [ ] Mensajes de error/success en dialogs

---

## 📊 Estructura Firestore Esperada

```
Familias/
  {familiaID}/
    Mascotas/
      {mascotaID}/
        Modulos/
          mod_limpieza/
            (document con config)
            Sesiones/ (subcollection)
              {sesionID}: {tipo, fecha, duracionMinutos, completada, productoUsado, notas}
          
          mod_calor/
            (document con config)
            Monitoreos/ (subcollection)
              {monitoreoID}: {fecha, temperaturaActual, tipo, dentibroPrendido, notas}
          
          mod_comportamiento/
            (document con config)
            Registros/ (subcollection)
              {registroID}: {fecha, tipo, descripcion, categoria, intensidad, detonante, resolucion, notas}
            Ejercicios/ (subcollection)
              {ejercicioID}: {nombre, descripcion, dificultad, objetivo, fechaInicio, 
                             fechaTermino, completado, progreso, notas}
```

---

## 🚀 Checklist de Finalización

### Antes de merge/commit:
- [ ] `flutter analyze` sin errores
- [ ] `flutter pub get` completa sin warnings
- [ ] Todas las 3 pantallas abren sin crashes
- [ ] Navigation desde detalle_mascota.dart funciona
- [ ] StreamBuilders actualizan en tiempo real
- [ ] Los diálogos guardan datos en Firestore
- [ ] Las configs se cargan correctamente por especie
- [ ] Probado con múltiples especies (perro, gato, tortuga, pez)

### Deployment:
- [ ] Revisar Cloud Firestore security rules si es necesario actualizar
- [ ] Considerar migración de mascotas existentes para agregar las nuevas configs
- [ ] Actualizar documentación de arquitectura del proyecto

---

## 📝 Notas Importantes

1. **Patrón de Especie**: Las configs usan `getDefaultXXX(String especie)` para retornar valores por defecto. La especie viene de `Mascota.especie`.

2. **Real-time Updates**: Todas las pantallas usan `StreamBuilder` para escuchar cambios en Firestore. Esto asegura que si se modifica desde otro dispositivo, se actualiza inmediatamente.

3. **ID de Documentos**: Los métodos de guardar asignan IDs automáticamente:
   ```dart
   final doc = collection.doc();
   objeto.id = doc.id;
   await doc.set(objeto.toMap());
   ```

4. **Import Path**: Los imports deben ser relativos al `lib/`:
   ```dart
   import 'package:pawner_app/core/model/modulo_limpieza/sesion_limpieza.dart';
   ```

5. **Material Design**: Usar `lucide_icons` para iconografía nueva (cleaning_services, thermostat, psychology).

---

## 🔗 Archivos Clave Modificados

- ✅ `lib/services/firestore_service.dart` - Agregados 18 métodos + imports
- ✅ `lib/core/model/` - 7 nuevos archivos de modelos
- ✅ `lib/screens/modulos/` - 3 nuevas pantallas
- ⚠️ `lib/screens/mascota/detalle_mascota.dart` - PENDIENTE: Navigation a nuevas pantallas

---

## 💡 Próximos Pasos Recomendados

**Sesión siguiente (próxima)**:
1. Ejecutar `flutter analyze` y resolver errores
2. Integrar 3 chips de navegación en `detalle_mascota.dart`
3. Implementar inicialización automática de configs
4. Testing funcional básico

**Sesión posterior**:
5. Testing completo end-to-end
6. Optimizaciones y polish UI
7. Deployment y migration de datos existentes

---

**Última actualización**: 12 de mayo de 2026  
**Estimación de tiempo total**: 4-6 horas de desarrollo + testing
**Estado actual**: ~70% completado
