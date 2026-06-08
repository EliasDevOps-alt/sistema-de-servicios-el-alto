// ══════════════════════════════════════════════════════════════════
// TESTS DE INTEGRACIÓN — Flujo de Solicitud de Servicio
// Archivo: integration_test/solicitud_flow_test.dart
// Ejecutar: flutter test integration_test/solicitud_flow_test.dart
//
// TEXTOS EXACTOS del código fuente:
//  - AppBar:           "Nueva Solicitud"
//  - Título pantalla:  "¿Qué necesitas reparar?"
//  - Label categorías: "Categoría del Servicio"
//  - Error sin cat.:   "⚠️ Selecciona una categoría"
//  - Error sin título: "⚠️ Completa el título y descripción"
//  - Botón enviar:     "ENVIAR SOLICITUD"
//  - Las categorías están en un ListView HORIZONTAL con scroll
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sistema_servicios/firebase_options.dart';
import 'package:sistema_servicios/presentation/screens/home/solicitud_servicio_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  // ── Helper: espera que la pantalla esté estable ────────────────
  Future<void> esperarPantalla(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 4));
    } catch (_) {
      await tester.pump(const Duration(seconds: 2));
    }
  }

  // ── Helper: scroll horizontal en el ListView de categorías ─────
  Future<void> scrollCategorias(WidgetTester tester,
      {double offset = 300}) async {
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView.first, Offset(-offset, 0));
      await tester.pumpAndSettle();
    }
  }

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — estructura de pantalla', () {

    testWidgets('Renderiza sin crashear', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byType(SolicitudServicioScreen), findsOneWidget);
    });

    testWidgets('AppBar muestra "Nueva Solicitud"', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('Nueva Solicitud'), findsOneWidget);
    });

    testWidgets('Muestra "¿Qué necesitas reparar?"', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('¿Qué necesitas reparar?'), findsOneWidget);
    });

    testWidgets('Muestra etiqueta "Categoría del Servicio"', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('Categoría del Servicio'), findsOneWidget);
    });

    testWidgets('Botón "ENVIAR SOLICITUD" existe', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('ENVIAR SOLICITUD'), findsOneWidget);
    });

    testWidgets('La pantalla tiene SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Hay un ListView horizontal para las categorías',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — categorías', () {

    testWidgets('Plomería visible sin scroll (es la primera)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('Plomería'), findsOneWidget);
    });

    testWidgets('Electricidad visible sin scroll', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.text('Electricidad'), findsOneWidget);
    });

    testWidgets('Limpieza visible luego de scroll horizontal', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      // Limpieza es la 4ta — fuera de pantalla sin scroll
      await scrollCategorias(tester, offset: 200);
      expect(find.text('Limpieza'), findsOneWidget);
    });

    testWidgets('Otros visible luego de scroll completo', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await scrollCategorias(tester, offset: 400);
      expect(find.text('Otros'), findsOneWidget);
    });

    testWidgets('Hay al menos 8 GestureDetectors (uno por categoría)',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(
        find.byType(GestureDetector).evaluate().length,
        greaterThanOrEqualTo(8),
      );
    });

    testWidgets('Tocar Plomería no genera error', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await tester.tap(find.text('Plomería'));
      await tester.pumpAndSettle();
      expect(find.text('Plomería'), findsOneWidget);
    });

    testWidgets('Tocar Electricidad no genera error', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await tester.tap(find.text('Electricidad'));
      await tester.pumpAndSettle();
      expect(find.text('Electricidad'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — campos de texto', () {

    testWidgets('Hay exactamente 3 TextFields', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('Permite escribir en el campo título (primer TextField)',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Caño roto');
      await tester.pump();
      expect(find.text('Caño roto'), findsOneWidget);
    });

    testWidgets('Permite escribir descripción (segundo TextField)',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await tester.enterText(
          find.byType(TextField).at(1), 'El grifo gotea sin parar');
      await tester.pump();
      expect(find.text('El grifo gotea sin parar'), findsOneWidget);
    });

    testWidgets('Permite escribir ubicación (tercer TextField)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      await tester.enterText(
          find.byType(TextField).at(2), 'Av. Bolivia 123');
      await tester.pump();
      expect(find.text('Av. Bolivia 123'), findsOneWidget);
    });

    testWidgets('Ícono del mapa naranja es visible', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — validaciones con mensajes exactos', () {

    testWidgets(
        'Sin categoría → SnackBar "⚠️ Selecciona una categoría"',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);

      // Tocar ENVIAR sin ninguna categoría seleccionada
      await tester.tap(find.text('ENVIAR SOLICITUD'));
      await tester.pump(); // pump simple para SnackBar

      // Texto EXACTO del SnackBar en el código fuente
      expect(find.text('⚠️ Selecciona una categoría'), findsOneWidget);
    });

    testWidgets(
        'Con categoría y sin título → SnackBar "⚠️ Completa el título y descripción"',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);

      // 1. Seleccionar categoría
      await tester.tap(find.text('Plomería'));
      await tester.pump();

      // 2. Tocar ENVIAR sin título
      await tester.tap(find.text('ENVIAR SOLICITUD'));
      await tester.pump();

      // Texto EXACTO del SnackBar en el código fuente
      expect(
        find.text('⚠️ Completa el título y descripción'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Con categoría, título pero sin descripción → error de campos',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);

      await tester.tap(find.text('Electricidad'));
      await tester.pump();

      // Solo llena el título, deja descripción vacía
      await tester.enterText(find.byType(TextField).at(0), 'Corto circuito');
      await tester.pump();

      await tester.tap(find.text('ENVIAR SOLICITUD'));
      await tester.pump();

      expect(
        find.text('⚠️ Completa el título y descripción'),
        findsOneWidget,
      );
    });

    testWidgets('Botón ENVIAR habilitado por defecto (_isLoading = false)',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'ENVIAR SOLICITUD'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — íconos del formulario', () {

    testWidgets('Ícono de título (Icons.title_rounded)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byIcon(Icons.title_rounded), findsOneWidget);
    });

    testWidgets('Ícono de ubicación (Icons.location_on)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('Ícono de Plomería (Icons.water_drop_outlined)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });

    testWidgets('Ícono de Electricidad (Icons.bolt_rounded)', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('SolicitudServicioScreen — scroll y navegación', () {

    testWidgets('Scroll vertical revela el botón ENVIAR', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: SolicitudServicioScreen()));
      await esperarPantalla(tester);

      await tester.dragUntilVisible(
        find.text('ENVIAR SOLICITUD'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      expect(find.text('ENVIAR SOLICITUD'), findsOneWidget);
    });

    testWidgets('Tiene back button cuando se navega desde otra pantalla',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => const SolicitudServicioScreen()),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}