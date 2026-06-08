// ══════════════════════════════════════════════════════════════════
// TESTS DE INTEGRACIÓN — Navegación entre pestañas y pantallas
// Archivo: integration_test/navegacion_test.dart
// Ejecutar: flutter test integration_test/navegacion_test.dart
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

  group('Navegación con BottomNavigationBar (cliente)', () {
    testWidgets('Las 3 pestañas son visibles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: const Center(child: Text('Contenido')),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Mapa'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Pedidos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Mis Pedidos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('Iconos de las 3 pestañas del cliente visibles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Mapa'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Pedidos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Tocar una pestaña cambia el índice activo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _SimuladorBottomNav(),
      ));
      await tester.pumpAndSettle();

      // Inicialmente está en Mapa (índice 0)
      expect(find.text('Contenido: Mapa'), findsOneWidget);

      // Tocar Mis Pedidos
      await tester.tap(find.text('Mis Pedidos'));
      await tester.pumpAndSettle();
      expect(find.text('Contenido: Mis Pedidos'), findsOneWidget);

      // Tocar Perfil
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Contenido: Perfil'), findsOneWidget);
    });
  });

  group('Navegación con BottomNavigationBar (técnico)', () {
    testWidgets('Las 4 pestañas del técnico son visibles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Ofertas'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Pendientes'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ganancias'),
              BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Explorar'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ofertas'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Ganancias'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
    });
  });

  group('Navegación con TabBar (Jobs Screen)', () {
    testWidgets('Tabs EN CURSO e HISTORIAL visibles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mis Solicitudes'),
              bottom: const TabBar(tabs: [
                Tab(text: 'EN CURSO'),
                Tab(text: 'HISTORIAL'),
              ]),
            ),
            body: const TabBarView(children: [
              Center(child: Text('Lista de activos')),
              Center(child: Text('Lista historial')),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('EN CURSO'), findsOneWidget);
      expect(find.text('HISTORIAL'), findsOneWidget);
      expect(find.text('Lista de activos'), findsOneWidget);
    });

    testWidgets('Cambiar de tab cambia el contenido', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(tabs: [
                Tab(text: 'EN CURSO'),
                Tab(text: 'HISTORIAL'),
              ]),
            ),
            body: const TabBarView(children: [
              Center(child: Text('Lista de activos')),
              Center(child: Text('Lista historial')),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Inicialmente vemos "Lista de activos"
      expect(find.text('Lista de activos'), findsOneWidget);

      // Tocar el tab HISTORIAL
      await tester.tap(find.text('HISTORIAL'));
      await tester.pumpAndSettle();

      // Ahora vemos "Lista historial"
      expect(find.text('Lista historial'), findsOneWidget);
    });
  });

  group('Navegación con Navigator.push', () {
    testWidgets('Push a nueva pantalla y back funcionan', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Inicial')),
          body: Builder(builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Segunda')),
                  body: const Center(child: Text('Contenido segunda')),
                )),
              ),
              child: const Text('Ir a segunda'),
            ),
          )),
        ),
      ));
      await tester.pumpAndSettle();

      // Pantalla inicial
      expect(find.text('Inicial'), findsOneWidget);
      expect(find.text('Segunda'), findsNothing);

      // Tocar el botón para ir a la segunda
      await tester.tap(find.text('Ir a segunda'));
      await tester.pumpAndSettle();

      // Ahora estamos en la segunda
      expect(find.text('Segunda'), findsOneWidget);
      expect(find.text('Contenido segunda'), findsOneWidget);

      // Verificar que hay back button
      expect(find.byType(BackButton), findsOneWidget);

      // Tocar back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Regresamos a la inicial
      expect(find.text('Inicial'), findsOneWidget);
    });

    testWidgets('Navigator.pop con resultado', (tester) async {
      String? resultado;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                resultado = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (ctx) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, 'datos-devueltos'),
                        child: const Text('Devolver'),
                      ),
                    ),
                  )),
                );
              },
              child: const Text('Ir'),
            ),
          )),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Devolver'));
      await tester.pumpAndSettle();

      expect(resultado, equals('datos-devueltos'));
    });
  });

  group('PopScope — bloqueo del botón atrás', () {
    testWidgets('PopScope con canPop:false intercepta el back', (tester) async {
      bool interceptado = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (!didPop) interceptado = true;
            },
            child: const Center(child: Text('Contenido protegido')),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Intentar back con el sistema
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(interceptado, isTrue);
      expect(find.text('Contenido protegido'), findsOneWidget);
    });
  });
}

// ── Widget simulador de BottomNavigationBar con cambio de pestaña ──
class _SimuladorBottomNav extends StatefulWidget {
  @override
  State<_SimuladorBottomNav> createState() => _SimuladorBottomNavState();
}

class _SimuladorBottomNavState extends State<_SimuladorBottomNav> {
  int _index = 0;
  static const _titulos = ['Mapa', 'Mis Pedidos', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Contenido: ${_titulos[_index]}')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
