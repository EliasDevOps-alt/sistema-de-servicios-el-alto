// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Formateo de fechas y ordenamiento
// Archivo: test/fecha_formato_test.dart
// Qué testea: formato de fechas visible al usuario, ordenamiento
//             de solicitudes por fecha (más reciente primero),
//             lógica de fechas para cancelaciones (ventana 7 días),
//             parseo de timestamps
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Utilidades de fecha del sistema ──────────────────────────────
class FormatadorFecha {
  static String formatearParaUI(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  static String formatearHora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  static bool esDentroDeVentana7Dias(DateTime fecha, DateTime ahora) {
    return ahora.difference(fecha).inDays < 7;
  }

  static bool esFueraDeVentana7Dias(DateTime fecha, DateTime ahora) {
    return ahora.difference(fecha).inDays >= 7;
  }

  static int compararFechasDescendente(DateTime a, DateTime b) {
    return b.compareTo(a); // más reciente primero
  }
}

class OrdenadorSolicitudes {
  static List<Map<String, dynamic>> ordenarPorFechaDescendente(
      List<Map<String, dynamic>> solicitudes) {
    final copia = List<Map<String, dynamic>>.from(solicitudes);
    copia.sort((a, b) {
      final tA = a['fecha'] as DateTime;
      final tB = b['fecha'] as DateTime;
      return tB.compareTo(tA);
    });
    return copia;
  }

  static List<Map<String, dynamic>> filtrarActivos(
      List<Map<String, dynamic>> solicitudes) {
    return solicitudes
        .where((s) => ['pendiente', 'aceptado', 'en_proceso'].contains(s['estado']))
        .toList();
  }

  static List<Map<String, dynamic>> filtrarHistorial(
      List<Map<String, dynamic>> solicitudes) {
    return solicitudes
        .where((s) => ['finalizado', 'cancelado'].contains(s['estado']))
        .toList();
  }
}


void main() {
  // ── Grupo 1: FormatadorFecha.formatearParaUI() ────────────────
  group('FormatadorFecha.formatearParaUI()', () {
    test('formatea fecha con día y mes con cero a la izquierda', () {
      final fecha = DateTime(2024, 3, 5, 9, 7);
      expect(FormatadorFecha.formatearParaUI(fecha), equals('05/03/2024 09:07'));
    });

    test('formatea fecha con dos dígitos correctamente', () {
      final fecha = DateTime(2024, 12, 31, 23, 59);
      expect(FormatadorFecha.formatearParaUI(fecha), equals('31/12/2024 23:59'));
    });

    test('formatea fecha de inicio de día correctamente', () {
      final fecha = DateTime(2024, 1, 1, 0, 0);
      expect(FormatadorFecha.formatearParaUI(fecha), equals('01/01/2024 00:00'));
    });

    test('formato tiene la forma DD/MM/YYYY HH:MM', () {
      final fecha = DateTime(2024, 6, 15, 14, 30);
      final resultado = FormatadorFecha.formatearParaUI(fecha);
      // Verifica estructura: dd/mm/yyyy hh:mm
      expect(RegExp(r'^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$').hasMatch(resultado), isTrue);
    });
  });

  // ── Grupo 2: FormatadorFecha.formatearHora() ──────────────────
  group('FormatadorFecha.formatearHora()', () {
    test('formatea hora con cero a la izquierda', () {
      final fecha = DateTime(2024, 1, 1, 9, 5);
      expect(FormatadorFecha.formatearHora(fecha), equals('09:05'));
    });

    test('formatea medianoche correctamente', () {
      final fecha = DateTime(2024, 1, 1, 0, 0);
      expect(FormatadorFecha.formatearHora(fecha), equals('00:00'));
    });

    test('formatea 23:59 correctamente', () {
      final fecha = DateTime(2024, 1, 1, 23, 59);
      expect(FormatadorFecha.formatearHora(fecha), equals('23:59'));
    });

    test('formato es HH:MM', () {
      final fecha = DateTime(2024, 6, 1, 14, 30);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(FormatadorFecha.formatearHora(fecha)), isTrue);
    });
  });

  // ── Grupo 3: Ventana de 7 días (cancelaciones) ────────────────
  group('FormatadorFecha — ventana de 7 días para cancelaciones', () {
    test('cancelación de hace 1 día está DENTRO de la ventana', () {
      final ahora = DateTime.now();
      final hace1dia = ahora.subtract(const Duration(days: 1));
      expect(FormatadorFecha.esDentroDeVentana7Dias(hace1dia, ahora), isTrue);
    });

    test('cancelación de hace 6 días está DENTRO de la ventana', () {
      final ahora = DateTime.now();
      final hace6dias = ahora.subtract(const Duration(days: 6));
      expect(FormatadorFecha.esDentroDeVentana7Dias(hace6dias, ahora), isTrue);
    });

    test('cancelación de hace 7 días EXACTOS está FUERA de la ventana', () {
      final ahora = DateTime.now();
      final hace7dias = ahora.subtract(const Duration(days: 7));
      expect(FormatadorFecha.esFueraDeVentana7Dias(hace7dias, ahora), isTrue);
    });

    test('cancelación de hace 8 días está FUERA de la ventana', () {
      final ahora = DateTime.now();
      final hace8dias = ahora.subtract(const Duration(days: 8));
      expect(FormatadorFecha.esFueraDeVentana7Dias(hace8dias, ahora), isTrue);
    });

    test('cancelación de hace 30 días está FUERA de la ventana', () {
      final ahora = DateTime.now();
      final hace30dias = ahora.subtract(const Duration(days: 30));
      expect(FormatadorFecha.esFueraDeVentana7Dias(hace30dias, ahora), isTrue);
    });

    test('cancelación justo ahora (0 días) está DENTRO', () {
      final ahora = DateTime.now();
      expect(FormatadorFecha.esDentroDeVentana7Dias(ahora, ahora), isTrue);
    });
  });

  // ── Grupo 4: Comparador de fechas ─────────────────────────────
  group('FormatadorFecha.compararFechasDescendente()', () {
    test('fecha más reciente se ordena primero', () {
      final antigua = DateTime(2024, 1, 1);
      final reciente = DateTime(2024, 12, 31);
      expect(FormatadorFecha.compararFechasDescendente(antigua, reciente), greaterThan(0));
    });

    test('fecha más antigua se ordena después', () {
      final antigua = DateTime(2024, 1, 1);
      final reciente = DateTime(2024, 12, 31);
      expect(FormatadorFecha.compararFechasDescendente(reciente, antigua), lessThan(0));
    });

    test('fechas iguales retornan 0', () {
      final fecha = DateTime(2024, 6, 15, 12, 0);
      expect(FormatadorFecha.compararFechasDescendente(fecha, fecha), equals(0));
    });
  });

  // ── Grupo 5: OrdenadorSolicitudes ─────────────────────────────
  group('OrdenadorSolicitudes.ordenarPorFechaDescendente()', () {
    test('ordena 3 solicitudes de más reciente a más antigua', () {
      final solicitudes = [
        {'id': 'A', 'fecha': DateTime(2024, 1, 1), 'estado': 'pendiente'},
        {'id': 'B', 'fecha': DateTime(2024, 6, 15), 'estado': 'pendiente'},
        {'id': 'C', 'fecha': DateTime(2024, 3, 10), 'estado': 'pendiente'},
      ];
      final ordenadas = OrdenadorSolicitudes.ordenarPorFechaDescendente(solicitudes);
      expect(ordenadas[0]['id'], equals('B')); // más reciente
      expect(ordenadas[1]['id'], equals('C'));
      expect(ordenadas[2]['id'], equals('A')); // más antigua
    });

    test('lista vacía retorna lista vacía', () {
      final resultado = OrdenadorSolicitudes.ordenarPorFechaDescendente([]);
      expect(resultado, isEmpty);
    });

    test('lista de un elemento retorna el mismo elemento', () {
      final solicitudes = [{'id': 'solo', 'fecha': DateTime(2024, 1, 1), 'estado': 'pendiente'}];
      final resultado = OrdenadorSolicitudes.ordenarPorFechaDescendente(solicitudes);
      expect(resultado.length, equals(1));
      expect(resultado[0]['id'], equals('solo'));
    });

    test('el orden original no se modifica (trabaja sobre copia)', () {
      final original = [
        {'id': 'primero', 'fecha': DateTime(2024, 1, 1), 'estado': 'pendiente'},
        {'id': 'segundo', 'fecha': DateTime(2024, 12, 31), 'estado': 'pendiente'},
      ];
      OrdenadorSolicitudes.ordenarPorFechaDescendente(original);
      expect(original[0]['id'], equals('primero')); // original no cambia
    });
  });

  // ── Grupo 6: Filtros de estado ────────────────────────────────
  group('OrdenadorSolicitudes.filtrarActivos() y filtrarHistorial()', () {
    final solicitudes = [
      {'id': '1', 'estado': 'pendiente'},
      {'id': '2', 'estado': 'aceptado'},
      {'id': '3', 'estado': 'en_proceso'},
      {'id': '4', 'estado': 'finalizado'},
      {'id': '5', 'estado': 'cancelado'},
    ];

    test('filtrarActivos retorna 3 solicitudes activas', () {
      final activos = OrdenadorSolicitudes.filtrarActivos(solicitudes);
      expect(activos.length, equals(3));
    });

    test('filtrarActivos incluye pendiente, aceptado, en_proceso', () {
      final activos = OrdenadorSolicitudes.filtrarActivos(solicitudes);
      final ids = activos.map((s) => s['id']).toList();
      expect(ids, containsAll(['1', '2', '3']));
    });

    test('filtrarActivos NO incluye finalizado ni cancelado', () {
      final activos = OrdenadorSolicitudes.filtrarActivos(solicitudes);
      final ids = activos.map((s) => s['id']).toList();
      expect(ids, isNot(contains('4')));
      expect(ids, isNot(contains('5')));
    });

    test('filtrarHistorial retorna 2 solicitudes', () {
      final historial = OrdenadorSolicitudes.filtrarHistorial(solicitudes);
      expect(historial.length, equals(2));
    });

    test('filtrarHistorial incluye finalizado y cancelado', () {
      final historial = OrdenadorSolicitudes.filtrarHistorial(solicitudes);
      final ids = historial.map((s) => s['id']).toList();
      expect(ids, containsAll(['4', '5']));
    });

    test('filtrarHistorial NO incluye pendiente, aceptado, en_proceso', () {
      final historial = OrdenadorSolicitudes.filtrarHistorial(solicitudes);
      final ids = historial.map((s) => s['id']).toList();
      expect(ids, isNot(containsAll(['1', '2', '3'])));
    });
  });
}
