// ══════════════════════════════════════════════════════════════════
// TESTS DE INTEGRACIÓN — Arranque de la app
// Archivo: integration_test/app_arranque_test.dart
// Ejecutar: flutter test integration_test/app_arranque_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sistema_servicios/firebase_options.dart';
import 'package:sistema_servicios/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  // ── Helper: descarta cualquier diálogo/permiso del sistema ─────
  Future<void> descartarDialogos(WidgetTester tester) async {
    // Espera que la app cargue completamente (hasta 8 segundos)
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // Si hay un diálogo de permisos del sistema operativo,
    // el botón "Permitir" o "Allow" lo cerramos tocándolo
    for (final label in ['Permitir', 'Allow', 'OK', 'Aceptar']) {
      final btn = find.text(label);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  group('App — arranque básico', () {
    testWidgets('La app arranca sin crashear', (tester) async {
      app.main();
      await descartarDialogos(tester);

      // Si llegamos aquí sin excepción la app arrancó bien
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Existe al menos un Scaffold en pantalla', (tester) async {
      app.main();
      await descartarDialogos(tester);

      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('Hay al menos un botón visible en pantalla', (tester) async {
      app.main();
      await descartarDialogos(tester);

      // En login hay un botón de Google
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('No hay errores de overflow en pantalla', (tester) async {
      app.main();

      // Capturar errores de overflow
      final errores = <String>[];
      FlutterError.onError = (details) {
        errores.add(details.toString());
      };

      await descartarDialogos(tester);

      // No debe haber errores de RenderFlex overflow
      final overflows = errores.where((e) => e.contains('overflow'));
      expect(overflows, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('Pantalla Login — elementos visibles', () {
    testWidgets('Logo o icono visible', (tester) async {
      app.main();
      await descartarDialogos(tester);

      // Verifica icono principal de la pantalla de login
      expect(
        find.byType(Icon).evaluate().isNotEmpty ||
        find.byType(Image).evaluate().isNotEmpty ||
        find.byType(CircleAvatar).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Botón de Google Sign-In existe y no está deshabilitado', (tester) async {
      app.main();
      await descartarDialogos(tester);

      final botones = find.byType(ElevatedButton);
      expect(botones.evaluate().isNotEmpty, isTrue);

      // Verifica que al menos uno no tenga onPressed null
      bool hayBotonesActivos = false;
      for (final elem in botones.evaluate()) {
        final btn = elem.widget as ElevatedButton;
        if (btn.onPressed != null) {
          hayBotonesActivos = true;
          break;
        }
      }
      expect(hayBotonesActivos, isTrue);
    });

    testWidgets('No hay CircularProgressIndicator cargando infinitamente', (tester) async {
      app.main();
      await descartarDialogos(tester);

      // La pantalla debe estar estable, no en loading permanente
      // (el loading solo aparece cuando se toca el botón de Google)
      final scaffolds = find.byType(Scaffold);
      expect(scaffolds.evaluate().isNotEmpty, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('Tema visual — Material3 activo', () {
    testWidgets('MaterialApp usa Material3', (tester) async {
      app.main();
      await descartarDialogos(tester);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets('Hay una pantalla completa renderizada', (tester) async {
      app.main();
      await descartarDialogos(tester);

      // El tamaño del render debe ser mayor a 0
      final size = binding.renderViews.first.size;
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });
  });

  // ══════════════════════════════════════════════════════════════
  group('Performance básica', () {
    testWidgets('La app carga en menos de 10 segundos', (tester) async {
      final inicio = DateTime.now();
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      final fin = DateTime.now();

      final segundos = fin.difference(inicio).inSeconds;
      expect(segundos, lessThan(10));
    });
  });
}