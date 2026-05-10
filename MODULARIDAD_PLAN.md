# Plan de Modularidad y Personalización para Pawner App

## Objetivo
Definir una arquitectura eficiente y profesional que permita:
- Personalizar cada mascota con módulos activos específicos.
- Facilitar la adición de nuevos módulos en el futuro.
- Mantener la entrega estable en 7 días.

## Visión clave
Cada mascota es un lienzo en blanco. El usuario activa solo los módulos que necesita, y la interfaz se adapta automáticamente a esa configuración.

## 1. Estructura de datos en Firestore
Mantener la jerarquía actual y añadir una lista de módulos activos por mascota.

### Modelo de documento de mascota
```
Familias/{familiaID}/Mascotas/{mascotaID}
├── datos_base          // nombre, especie, raza, peso, etc.
├── modulos_activos: ["vet", "comida", "paseos"]
└── Modulos/
    ├── vet/           // Configuración y datos de veterinario
    ├── comida/        // Configuración y datos de alimentación
    └── paseos/        // Futuro módulo de paseos
```

### Por qué
- `modulos_activos` hace que cada mascota tenga un perfil único.
- Los módulos se activan/desactivan sin cambiar la estructura base.
- Agregar un módulo nuevo solo exige un nuevo `moduloID` y un registro central.

## 2. Catálogo global de módulos
Crear un registro central de módulos disponibles en la app.

### Ejemplo de definición
```dart
class ModuloDefinition {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final List<String> especiesRecomendadas;
  final String configPath;
}
```

### Beneficios
- Muestra una arquitectura de módulos clara ante el tribunal.
- Permite recomendaciones inteligentes según la especie.
- Facilita la incorporación de nuevos módulos en el futuro.

## 3. Contrato común para módulos
Definir una interfaz que todos los módulos deben implementar.

### Ejemplo
```dart
abstract class ModuloBase {
  String get id;
  String get nombre;
  Widget buildScreen(BuildContext context, String familiaID, String mascotaID);
  Future<void> inicializarConfig(String familiaID, String mascotaID);
  Future<void> limpiarDatos(String familiaID, String mascotaID);
}
```

## 4. Servicio de gestión de módulos
Extender el servicio de Firestore para manejar activación y desactivación.

### Métodos
- `activarModulo(familiaID, mascotaID, moduloID)`
- `desactivarModulo(familiaID, mascotaID, moduloID)`
- `streamModulosActivos(familiaID, mascotaID)`

## 5. Interfaz de usuario dinámica
Mostrar solo los módulos activos en la pantalla de detalles de la mascota.

### Flujo propuesto
1. La mascota carga su lista `modulos_activos`.
2. La pantalla de configuración muestra todos los módulos disponibles.
3. El usuario activa/desactiva con un switch.
4. El detalle de la mascota muestra botones o cards solo para los módulos activos.

## 6. Pantalla de configuración de módulos
Agregar una pantalla específica para elegir módulos.

### UX recomendada
- Lista de módulos con icono, nombre y descripción.
- Switch para activar/desactivar.
- Etiquetas de módulo recomendado según especie.
- Mensaje claro: "Activa solo lo que tu mascota necesita".

## 7. Prioridad para el MVP de 7 días
### Fase 1: Preparar datos y modelo
- Añadir `modulos_activos` al modelo `Mascota`.
- Crear `ModuloRegistry` con los módulos actuales.
- Asegurar la migración de mascotas existentes.

### Fase 2: Lógica de servicios
- Implementar activación/desactivación en Firestore.
- Añadir stream de módulos activos.
- Integrar con el servicio existente sin romperlo.

### Fase 3: UI dinámica
- Crear la pantalla de configuración de módulos.
- Ajustar la pantalla de detalle para mostrar solo módulos activos.
- Probar con los módulos Vet y Comida existentes.

### Fase 4: Refinamiento y documentación
- Probar el flujo completo.
- Documentar el proceso para el tribunal.
- Agregar ejemplos de cómo crear futuros módulos.

## 8. Cómo venderlo en el tribunal
### Argumentos técnicos
- Arquitectura basada en módulos predefinidos con activación por mascota.
- Contrato común para cada módulo garantiza escalabilidad.
- Separación clara entre datos de mascota y datos del módulo.
- Interfaz adaptativa que evita renderizados dinámicos complejos.

### Beneficios de negocio
- Cada mascota recibe solo lo que necesita.
- El sistema permite añadir nuevas funcionalidades sin rehacer la base.
- Evita la complejidad de un constructor de formularios genérico para el MVP.

## 9. Extensión futura
### Nuevos módulos fáciles de añadir
1. Definir `ModuloDefinition` en el catálogo.
2. Implementar la clase que extienda `ModuloBase`.
3. Añadir la ruta de pantalla y el `configPath` en Firestore.

### Ejemplos de módulos futuros
- Paseos
- Adiestramiento
- Control de parámetros de agua para peces
- Higiene y limpieza
- Farmacia y medicamentos

## 10. Conclusión
Este enfoque ofrece la mejor combinación entre:
- personalización real para cada mascota,
- modularidad escalable para el futuro,
- estabilidad y entrega rápida para el MVP.

> Resultado final: un sistema que es "altamente modular" en construcción, pero que se apoya en módulos robustos y ya existentes en lugar de en un motor de formularios dinámicos complejo.
