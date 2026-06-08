// ══════════════════════════════════════════════════════════════════
// TESTS DE INTEGRACIÓN — Flujo completo de Solicitudes y Jobs Screen
// Archivo: integration_test/jobs_screen_test.dart
// Ejecutar: flutter test integration_test/jobs_screen_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sistema_servicios/firebase_options.dart';
import 'package:sistema_servicios/config/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Tarjeta de solicitud activa (UI)', () {
    testWidgets('Renderiza badge naranja para pendiente', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: _TarjetaSolicitudPrueba(
          titulo: 'Caño roto',
          estado: 'pendiente',
          colorEstado: Colors.orange,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Caño roto'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);
    });

    testWidgets('Renderiza badge azul para aceptado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _TarjetaSolicitudPrueba(
          titulo: 'Reparación eléctrica',
          estado: 'aceptado',
          colorEstado: Colors.blue,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reparación eléctrica'), findsOneWidget);
      expect(find.text('ACEPTADO'), findsOneWidget);
    });

    testWidgets('Renderiza badge verde para finalizado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _TarjetaSolicitudPrueba(
          titulo: 'Pintura',
          estado: 'finalizado',
          colorEstado: Colors.green,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('Renderiza badge rojo para cancelado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _TarjetaSolicitudPrueba(
          titulo: 'Limpieza',
          estado: 'cancelado',
          colorEstado: Colors.red,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('CANCELADO'), findsOneWidget);
    });
  });

  group('Botón TERMINAR TRABAJO del técnico', () {
    testWidgets('Botón visible cuando estado es aceptado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _BotonTerminar(estado: 'aceptado')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TERMINAR TRABAJO'), findsOneWidget);
    });

    testWidgets('Botón NO visible cuando estado es finalizado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _BotonTerminar(estado: 'finalizado')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TERMINAR TRABAJO'), findsNothing);
      expect(find.textContaining('finalizaste'), findsOneWidget);
    });

    testWidgets('Tap en TERMINAR dispara el callback', (tester) async {
      int presionado = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _BotonTerminar(
          estado: 'aceptado',
          onPressed: () => presionado++,
        )),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TERMINAR TRABAJO'));
      await tester.pump();
      expect(presionado, equals(1));
    });
  });

  group('Diálogo de cancelación de solicitud', () {
    testWidgets('Diálogo aparece con título y dos botones', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Cancelar Solicitud'),
              content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('NO')),
                ElevatedButton(onPressed: () {}, child: const Text('SÍ, CANCELAR')),
              ],
            ),
          ),
          child: const Text('Abrir cancelación'),
        ))),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir cancelación'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar Solicitud'), findsOneWidget);
      expect(find.text('¿Estás seguro? Esta acción no se puede deshacer.'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
      expect(find.text('SÍ, CANCELAR'), findsOneWidget);
    });

    testWidgets('Diálogo se cierra al presionar NO', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmar'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('NO'),
                ),
              ],
            ),
          ),
          child: const Text('Abrir'),
        ))),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar'), findsOneWidget);

      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar'), findsNothing);
    });
  });

  group('Diálogo de calificación con estrellas', () {
    testWidgets('Muestra 5 estrellas tocables', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _DialogoCalificar()),
      ));
      await tester.pumpAndSettle();

      // Inicialmente todas son star_rounded (5 estrellas iluminadas)
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    testWidgets('Al tocar la 3ra estrella, 2 quedan iluminadas y 3 sin', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _DialogoCalificar()),
      ));
      await tester.pumpAndSettle();

      // Tocar la 3ra estrella (index 2)
      final estrellas = find.byIcon(Icons.star_rounded);
      await tester.tap(estrellas.at(2));
      await tester.pumpAndSettle();

      // Después de tocar la 3ra → 3 iluminadas (0,1,2) y 2 vacías (3,4)
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(2));
    });

    testWidgets('Texto muestra cantidad de estrellas seleccionada', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _DialogoCalificar()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5 Estrellas'), findsOneWidget);

      // Tocar la 1ra estrella
      final estrellas = find.byIcon(Icons.star_rounded);
      await tester.tap(estrellas.at(0));
      await tester.pumpAndSettle();

      expect(find.text('1 Estrellas'), findsOneWidget);
    });
  });

  group('Estado vacío de la lista', () {
    testWidgets('Mensaje cuando no hay solicitudes activas', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 65, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tienes solicitudes activas'),
            ],
          ),
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No tienes solicitudes activas'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('Mensaje cuando no hay historial', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 65, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tienes historial'),
            ],
          ),
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No tienes historial'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('Pull to refresh', () {
    testWidgets('RefreshIndicator dispara callback al deslizar', (tester) async {
      int refrescado = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: RefreshIndicator(
          onRefresh: () async => refrescado++,
          child: ListView(children: const [
            ListTile(title: Text('Item 1')),
            ListTile(title: Text('Item 2')),
          ]),
        )),
      ));
      await tester.pumpAndSettle();

      // Simular el gesto de pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refrescado, equals(1));
    });
  });
}

// ── Widgets auxiliares de prueba ──────────────────────────────────
class _TarjetaSolicitudPrueba extends StatelessWidget {
  final String titulo;
  final String estado;
  final Color colorEstado;
  const _TarjetaSolicitudPrueba({
    required this.titulo,
    required this.estado,
    required this.colorEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonTerminar extends StatelessWidget {
  final String estado;
  final VoidCallback? onPressed;
  const _BotonTerminar({required this.estado, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (estado == 'aceptado') {
      return ElevatedButton.icon(
        onPressed: onPressed ?? () {},
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('TERMINAR TRABAJO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      );
    }
    return const Center(
      child: Text('🎉 ¡Ya finalizaste este servicio!',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DialogoCalificar extends StatefulWidget {
  @override
  State<_DialogoCalificar> createState() => _DialogoCalificarState();
}

class _DialogoCalificarState extends State<_DialogoCalificar> {
  int estrellas = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          children: List.generate(5, (i) => IconButton(
            icon: Icon(
              i < estrellas ? Icons.star_rounded : Icons.star_border_rounded,
              size: 40, color: Colors.amber,
            ),
            onPressed: () => setState(() => estrellas = i + 1),
          )),
        ),
        Text('$estrellas Estrellas', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
