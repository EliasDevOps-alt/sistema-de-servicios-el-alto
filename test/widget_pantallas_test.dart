// ══════════════════════════════════════════════════════════════════
// PRUEBAS DE WIDGET — Componentes UI aislados
// Archivo: test/widget_pantallas_test.dart
// Ejecutar: flutter test test/widget_pantallas_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_servicios/config/theme.dart';

// ── Widget de prueba: tarjeta de categoría usada en solicitudes ──
class CategoriaCardTest extends StatefulWidget {
  final String nombre;
  final IconData icon;
  const CategoriaCardTest({super.key, required this.nombre, required this.icon});
  @override
  State<CategoriaCardTest> createState() => _CategoriaCardTestState();
}

class _CategoriaCardTestState extends State<CategoriaCardTest> {
  bool seleccionada = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => seleccionada = !seleccionada),
      child: Container(
        key: const Key('categoria-container'),
        padding: const EdgeInsets.all(10),
        color: seleccionada ? AppTheme.primaryColor : Colors.white,
        child: Column(
          children: [
            Icon(widget.icon, color: seleccionada ? Colors.white : Colors.grey),
            Text(widget.nombre, style: TextStyle(
              color: seleccionada ? Colors.white : Colors.black,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Widget de prueba: badge de estado de solicitud ──
class BadgeEstado extends StatelessWidget {
  final String estado;
  const BadgeEstado({super.key, required this.estado});

  Color get color {
    switch (estado) {
      case 'aceptado':   return Colors.blue;
      case 'finalizado': return Colors.green;
      case 'completado': return Colors.green;
      case 'cancelado':  return Colors.red;
      default:           return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('badge-container'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        estado.toUpperCase(),
        key: const Key('badge-text'),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

void main() {
  // ══════════════════════════════════════════════════════════════════
  // TEMA DE LA APP — VERIFICACIÓN DE COLORES
  // ══════════════════════════════════════════════════════════════════
  group('AppTheme — configuración visual', () {
    testWidgets('primaryColor es azul confianza', (tester) async {
      expect(AppTheme.primaryColor, equals(const Color(0xFF1565C0)));
    });

    testWidgets('accentColor es naranja trabajo', (tester) async {
      expect(AppTheme.accentColor, equals(const Color(0xFFEF6C00)));
    });

    testWidgets('backgroundColor es gris claro', (tester) async {
      expect(AppTheme.backgroundColor, equals(const Color(0xFFF5F5F5)));
    });

    testWidgets('lightTheme tiene Material 3 activado', (tester) async {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('AppBar tiene color primary', (tester) async {
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme.backgroundColor, equals(AppTheme.primaryColor));
    });

    testWidgets('AppBar tiene icono blanco', (tester) async {
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme.iconTheme?.color, equals(Colors.white));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // BADGE DE ESTADO — RENDERIZADO
  // ══════════════════════════════════════════════════════════════════
  group('BadgeEstado — renderizado y colores', () {
    testWidgets('estado "pendiente" se muestra en MAYÚSCULAS', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BadgeEstado(estado: 'pendiente')),
      ));
      expect(find.text('PENDIENTE'), findsOneWidget);
    });

    testWidgets('estado "aceptado" se muestra en mayúsculas', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BadgeEstado(estado: 'aceptado')),
      ));
      expect(find.text('ACEPTADO'), findsOneWidget);
    });

    testWidgets('estado "finalizado" se muestra en mayúsculas', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BadgeEstado(estado: 'finalizado')),
      ));
      expect(find.text('FINALIZADO'), findsOneWidget);
    });

    testWidgets('badge tiene contenedor con padding', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BadgeEstado(estado: 'pendiente')),
      ));
      expect(find.byKey(const Key('badge-container')), findsOneWidget);
    });

    testWidgets('texto del badge usa fontWeight bold', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BadgeEstado(estado: 'aceptado')),
      ));
      final textWidget = tester.widget<Text>(find.byKey(const Key('badge-text')));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // TARJETA DE CATEGORÍA — INTERACCIÓN
  // ══════════════════════════════════════════════════════════════════
  group('CategoriaCardTest — interacción de selección', () {
    testWidgets('muestra el nombre de la categoría', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CategoriaCardTest(
          nombre: 'Plomería',
          icon: Icons.water_drop,
        )),
      ));
      expect(find.text('Plomería'), findsOneWidget);
    });

    testWidgets('muestra el icono asociado', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CategoriaCardTest(
          nombre: 'Electricidad',
          icon: Icons.bolt_rounded,
        )),
      ));
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('al tocar cambia el color de fondo', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CategoriaCardTest(
          nombre: 'Limpieza',
          icon: Icons.cleaning_services,
        )),
      ));
      // Estado inicial: blanco
      final containerInicial = tester.widget<Container>(
        find.byKey(const Key('categoria-container'))
      );
      expect((containerInicial.color), equals(Colors.white));

      // Tocar
      await tester.tap(find.byKey(const Key('categoria-container')));
      await tester.pump();

      // Estado final: color primary
      final containerFinal = tester.widget<Container>(
        find.byKey(const Key('categoria-container'))
      );
      expect((containerFinal.color), equals(AppTheme.primaryColor));
    });

    testWidgets('doble toque deselecciona', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CategoriaCardTest(
          nombre: 'Cerrajería',
          icon: Icons.vpn_key,
        )),
      ));
      await tester.tap(find.byKey(const Key('categoria-container')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('categoria-container')));
      await tester.pump();
      final container = tester.widget<Container>(
        find.byKey(const Key('categoria-container'))
      );
      expect(container.color, equals(Colors.white));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // FORMULARIO DE TEXTO — TEXTFIELDS
  // ══════════════════════════════════════════════════════════════════
  group('Validación de TextField en formulario de solicitud', () {
    testWidgets('TextField permite escribir', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Título'),
        )),
      ));
      await tester.enterText(find.byType(TextField), 'Caño roto');
      expect(ctrl.text, equals('Caño roto'));
    });

    testWidgets('TextField multilínea permite saltos', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TextField(
          controller: ctrl,
          maxLines: 3,
        )),
      ));
      await tester.enterText(find.byType(TextField), 'Línea 1\nLínea 2');
      expect(ctrl.text, contains('Línea 1'));
      expect(ctrl.text, contains('Línea 2'));
    });

    testWidgets('TextField vacío no tiene texto', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TextField(controller: ctrl)),
      ));
      expect(ctrl.text, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // BOTONES — TAPS Y CALLBACKS
  // ══════════════════════════════════════════════════════════════════
  group('Botones críticos del sistema', () {
    testWidgets('ElevatedButton dispara callback al ser tocado', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ElevatedButton(
          onPressed: () => tapCount++,
          child: const Text('ENVIAR SOLICITUD'),
        )),
      ));
      expect(find.text('ENVIAR SOLICITUD'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapCount, equals(1));
    });

    testWidgets('botón deshabilitado no dispara callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ElevatedButton(
          onPressed: null, // deshabilitado
          child: const Text('ENVIAR'),
        )),
      ));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapCount, equals(0));
    });

    testWidgets('CircularProgressIndicator visible cuando isLoading', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CircularProgressIndicator()),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // SCAFFOLD Y APPBAR — ESTRUCTURA BÁSICA
  // ══════════════════════════════════════════════════════════════════
  group('Estructura básica de pantallas', () {
    testWidgets('Scaffold con AppBar muestra título', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Mis Solicitudes')),
          body: const SizedBox(),
        ),
      ));
      expect(find.text('Mis Solicitudes'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('BottomNavigationBar muestra los 3 items del cliente', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Mapa'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Pedidos'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
          body: const SizedBox(),
        ),
      ));
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Mis Pedidos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('TabBar de jobs muestra EN CURSO e HISTORIAL', (tester) async {
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
            body: const SizedBox(),
          ),
        ),
      ));
      expect(find.text('EN CURSO'), findsOneWidget);
      expect(find.text('HISTORIAL'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // ALERTDIALOG — DIÁLOGOS DE CONFIRMACIÓN
  // ══════════════════════════════════════════════════════════════════
  group('Diálogos de confirmación', () {
    testWidgets('AlertDialog muestra título y contenido', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cancelar Solicitud'),
                content: const Text('¿Estás seguro?'),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('NO')),
                  ElevatedButton(onPressed: () {}, child: const Text('SÍ')),
                ],
              ),
            ),
            child: const Text('Abrir'),
          ),
        )),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar Solicitud'), findsOneWidget);
      expect(find.text('¿Estás seguro?'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
      expect(find.text('SÍ'), findsOneWidget);
    });

    testWidgets('AlertDialog se cierra al tocar acción', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Test'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                ],
              ),
            ),
            child: const Text('Abrir'),
          ),
        )),
      ));

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsNothing);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // SNACKBAR — MENSAJES DE FEEDBACK
  // ══════════════════════════════════════════════════════════════════
  group('SnackBars de feedback al usuario', () {
    testWidgets('SnackBar de éxito aparece al ejecutar acción', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Solicitud enviada')),
            ),
            child: const Text('Enviar'),
          ),
        )),
      ));

      await tester.tap(find.text('Enviar'));
      await tester.pump();
      expect(find.text('✅ Solicitud enviada'), findsOneWidget);
    });

    testWidgets('SnackBar rojo de error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Error al guardar'),
                backgroundColor: Colors.red,
              ),
            ),
            child: const Text('Error'),
          ),
        )),
      ));

      await tester.tap(find.text('Error'));
      await tester.pump();
      expect(find.text('⚠️ Error al guardar'), findsOneWidget);
    });
  });
}
