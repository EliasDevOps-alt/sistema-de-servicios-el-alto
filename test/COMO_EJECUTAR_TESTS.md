# 🧪 Guía de Tests — Sistema de Servicios El Alto

## 📊 Resumen

| Tipo | Carpeta | Archivos | Tests aprox. | Dónde corre |
|---|---|---|---|---|
| **Unitarios** | `test/` | 6 | ~250 | Local, en segundos |
| **Widget** | `test/widget_pantallas_test.dart` | 1 (incluido) | ~30 | Local, en segundos |
| **Integración** | `integration_test/` | 5 | ~50 | En el celular, lento |

**TOTAL: ~330 tests**

---

## 📁 Estructura de carpetas

```
sistema_servicios_app/
├── test/                              ← Tests unitarios (rápidos)
│   ├── tecnico_entity_test.dart           (16 tests)
│   ├── solicitud_validacion_test.dart     (50+ tests)
│   ├── estados_y_chat_test.dart           (40+ tests)
│   ├── calculos_test.dart                 (50+ tests)
│   ├── perfil_y_gps_test.dart             (50+ tests)
│   ├── firestore_y_fechas_test.dart       (40+ tests)
│   └── widget_pantallas_test.dart         (30+ tests)
│
└── integration_test/                  ← Tests de integración (en celular)
    ├── app_arranque_test.dart             (10+ tests)
    ├── solicitud_flow_test.dart           (12+ tests)
    ├── navegacion_test.dart               (15+ tests)
    ├── chat_firestore_test.dart           (10+ tests reales con Firebase)
    └── jobs_screen_test.dart              (20+ tests)
```

---

## ⚙️ PASO 1 — Configurar el proyecto

### 1.1 Agregar dependencias en `pubspec.yaml`

Reemplaza tu sección `dev_dependencies` por esta:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### 1.2 Instalar dependencias

```powershell
flutter pub get
```

---

## 🚀 PASO 2 — Ejecutar tests UNITARIOS (no necesita celular)

Los tests unitarios corren localmente en tu PC en segundos.

### Correr TODOS los tests unitarios:
```powershell
flutter test
```

### Correr UN archivo específico:
```powershell
flutter test test/tecnico_entity_test.dart
flutter test test/solicitud_validacion_test.dart
flutter test test/estados_y_chat_test.dart
flutter test test/calculos_test.dart
flutter test test/perfil_y_gps_test.dart
flutter test test/firestore_y_fechas_test.dart
flutter test test/widget_pantallas_test.dart
```

### Ver el detalle expandido de cada test:
```powershell
flutter test --reporter expanded
```

### Generar reporte de cobertura:
```powershell
flutter test --coverage
```

---

## 📱 PASO 3 — Ejecutar tests de INTEGRACIÓN (necesita celular)

Los tests de integración corren en un dispositivo real o emulador.

### 3.1 Conectar el celular por USB

1. Activa **Opciones de desarrollador** en tu celular
2. Activa **Depuración USB**
3. Conecta el cable USB
4. Acepta el diálogo "Permitir depuración" en el celular
5. Verifica que el celular se detecte:
   ```powershell
   flutter devices
   ```
   Debe aparecer tu celular en la lista.

### 3.2 Ejecutar TODOS los tests de integración:
```powershell
flutter test integration_test
```

### 3.3 Ejecutar UN archivo específico:
```powershell
flutter test integration_test/app_arranque_test.dart
flutter test integration_test/solicitud_flow_test.dart
flutter test integration_test/navegacion_test.dart
flutter test integration_test/chat_firestore_test.dart
flutter test integration_test/jobs_screen_test.dart
```

### 3.4 Si tienes varios dispositivos:
```powershell
flutter test integration_test -d <device-id>
```

---

## ⚠️ Notas importantes

### Sobre los tests de Firestore (chat_firestore_test.dart):
Estos tests **escriben datos reales** en tu Firestore en colecciones llamadas:
- `solicitudes_test/`
- `chat_rooms/test_chat_room_xyz`
- `chat_rooms/test_propios_xyz`

Los tests **limpian solos** los documentos al terminar, pero si algún test falla a la mitad podrían quedar residuos. Para evitar ensuciar tu DB de producción, usa el **Firebase Emulator**:

```powershell
firebase emulators:start --only firestore
```

Y agrega antes de `Firebase.initializeApp()` en `chat_firestore_test.dart`:

```dart
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

### Sobre los tests que necesitan login:
Algunos tests de integración asumen que hay un usuario logueado en Firebase. Si no lo hay, esos tests específicos se saltarán automáticamente (los he envuelto en condicionales).

---

## 📈 ¿Qué probar cada test?

### Tests Unitarios

| Archivo | Qué prueba |
|---|---|
| `tecnico_entity_test.dart` | Reglas de negocio del técnico: `puedeTrabajar()`, valores por defecto, calificaciones |
| `solicitud_validacion_test.dart` | Validaciones de título, descripción, las 8 categorías, formato GPS, construcción del documento Firestore |
| `estados_y_chat_test.dart` | Estados pendiente/aceptado/finalizado/cancelado, generación de chatRoomId, mensajes propios vs ajenos |
| `calculos_test.dart` | Parseo de precios "150,00" → 150.0, ganancias totales, promedio de calificaciones, comisiones, sistema de cancelaciones con ventana de 7 días |
| `perfil_y_gps_test.dart` | Validación de nombre, teléfono boliviano (+591), radio de cobertura, email, coordenadas dentro de Bolivia, zoom válido |
| `firestore_y_fechas_test.dart` | Extracción de datos de documentos, formato DD/MM/YYYY HH:MM, ordenamiento, filtros de estado |
| `widget_pantallas_test.dart` | Colores del tema, badges, categorías seleccionables, TextFields, botones, diálogos, snackbars |

### Tests de Integración

| Archivo | Qué prueba |
|---|---|
| `app_arranque_test.dart` | La app arranca sin crashear, muestra LoginScreen, aplica el tema azul |
| `solicitud_flow_test.dart` | Pantalla de solicitud muestra las 8 categorías, valida campos vacíos |
| `navegacion_test.dart` | BottomNavigationBar de cliente (3 pestañas) y técnico (4 pestañas), TabBar EN CURSO/HISTORIAL, push/pop con resultado, PopScope |
| `chat_firestore_test.dart` | CRUD real en Firestore, queries con where, serverTimestamp, transacciones atómicas (race condition de dos técnicos), StreamBuilder en vivo |
| `jobs_screen_test.dart` | Badges de estado, botón TERMINAR, diálogo de cancelación, diálogo de calificación con 5 estrellas tocables, RefreshIndicator |

---

## 🐛 Solución de problemas

### "Could not find a command named 'test/archivo.dart'"
Escribiste `flutter test/archivo.dart` (sin espacio). Lo correcto es:
```powershell
flutter test test/archivo.dart
```

### "No devices found"
Conecta tu celular por USB con depuración activada, o inicia un emulador:
```powershell
flutter emulators --launch <emulator_id>
```

### Tests de Firestore fallan con "permission-denied"
Tus reglas de Firestore no permiten escribir en `solicitudes_test`. Agrega esta regla temporalmente en Firebase Console:
```javascript
match /solicitudes_test/{doc} {
  allow read, write: if true;
}
match /chat_rooms/{room}/mensajes/{msg} {
  allow read, write: if true;
}
```

### "import 'package:sistema_servicios/...' could not be found"
Verifica que el nombre del paquete en `pubspec.yaml` sea exactamente `sistema_servicios`. Si es diferente, ajusta los imports en los archivos de test.
