# Mejoras pendientes

## FirestoreService

### 1. Añadir `updateFamilia()` / `updateNombreFamilia()`
No existe un método para renombrar la familia. No es un bug hoy porque no hay UI para ello, pero es deuda de diseño que habrá que saldar cuando se construya esa pantalla.

### 2. Añadir `streamFamilia()`
`DetalleFamiliaScreen` usa `getFamilia()` (one-shot). Si el admin regenera el código de invitación o cambia el nombre mientras otro miembro tiene la pantalla abierta, ese miembro ve datos obsoletos hasta que cierra y reabre. En una app colaborativa esto puede causar confusión. Reemplazar por un stream en tiempo real.

### 3. `eliminarMascota()` no borra el documento raíz `Modulos/mod_vet` ni `mod_comida`
El cascade borra las subcolecciones (`Citas/`, `EventosSalud/`, `Platos/`, `Horarios/`) pero los documentos raíz de cada módulo quedan huérfanos en Firestore. Impacto: acumulación de documentos basura (coste económico menor) y riesgo teórico de herencia de config si se reutilizara un `mascotaID`. Añadir `batch.delete()` para ambos documentos raíz en `eliminarMascota()`.

### 4. ~~`updateCitaVeterinaria()` no sincronizaba el Recordatorio asociado~~ ✅ Resuelto
Cuando se editaba el motivo o la fecha de una cita, el documento `Recordatorios/` a nivel familia quedaba desactualizado. Convertido a WriteBatch que actualiza ambos documentos atómicamente. Si `recordatorioID` es null (citas antiguas), actualiza solo la cita.

### 5. No existe `updatePlato()`
`updatePlato()` no existe — editar un plato requiere borrarlo y recrearlo. Pendiente añadir el método en `FirestoreService` y `ComidaService`, y habilitar la edición desde `DetallePlatoSheet`.

---

## HorariosScreen

### 6. No hay validación de duplicados al crear horarios
Si el usuario pulsa "Guardar Horarios" dos veces con el mismo modo y horas, se crean horarios duplicados en Firestore con IDs distintos. Ambos quedan activos y disparan notificaciones distintas a la misma hora.

### 7. Modo Intervalos ignora horarios existentes
`_crearHorarioIntervalos()` genera siempre desde `DateTime.now()`, sin tener en cuenta los horarios ya guardados. Puede generar solapamientos o duplicar horas si se usa más de una vez.

### 8. La lista de horarios no está ordenada
`streamHorarios` no aplica `.orderBy()`. Los horarios aparecen en orden de inserción en Firestore, no por hora del día. Añadir ordenación por el campo `hora` (string `HH:mm` ordena correctamente de forma lexicográfica).
