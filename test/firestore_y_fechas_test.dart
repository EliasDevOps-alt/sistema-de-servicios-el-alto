// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Datos de Firestore y formato de fechas
// Archivo: test/firestore_y_fechas_test.dart
// Ejecutar: flutter test test/firestore_y_fechas_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Procesamiento de documentos de Firestore (lógica de jobs_screen, profile, etc) ──
class ProcesadorFirestore {
  static String extraerNombreDeDoc(Map<String, dynamic>? data, String email) {
    if (data == null) return email.split('@')[0];
    final n = data['nombre'] ?? data['name'];
    if (n != null && (n as String).isNotEmpty) return n;
    return email.split('@')[0];
  }

  static String extraerTelefonoDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 'No registrado';
    return data['telefono'] ?? data['phone'] ?? 'No registrado';
  }

  static double extraerCalificacionDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    final v = data['calificacion'];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  static double extraerPrecioDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    final v = data['precio'];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  static bool tecnicoDisponible(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['disponible'] == true;
  }

  static String estadoConFallback(Map<String, dynamic>? data, {String fallback = 'pendiente'}) {
    if (data == null) return fallback;
    return data['estado'] ?? fallback;
  }
}

// ── Formato de fechas (jobs_screen) ──
class FormatoFecha {
  static String formatearParaUI(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year} $h:$min';
  }

  static String formatearHora(DateTime fecha) =>
    '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  static int compararDescendente(DateTime a, DateTime b) => b.compareTo(a);

  static List<DateTime> ordenarMasRecientePrimero(List<DateTime> fechas) {
    final copia = List<DateTime>.from(fechas);
    copia.sort(compararDescendente);
    return copia;
  }
}

void main() {
  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — NOMBRE
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.extraerNombreDeDoc()', () {
    test('usa "nombre" cuando existe', () {
      expect(ProcesadorFirestore.extraerNombreDeDoc(
        {'nombre': 'María Flores'}, 'maria@gmail.com'
      ), equals('María Flores'));
    });

    test('cae a email si data es null', () {
      expect(ProcesadorFirestore.extraerNombreDeDoc(null, 'tecnico99@gmail.com'),
        equals('tecnico99'));
    });

    test('usa "name" como fallback de "nombre"', () {
      expect(ProcesadorFirestore.extraerNombreDeDoc(
        {'name': 'Jorge Apaza'}, 'jorge@g.com'
      ), equals('Jorge Apaza'));
    });

    test('cae a email si "nombre" está vacío', () {
      expect(ProcesadorFirestore.extraerNombreDeDoc(
        {'nombre': ''}, 'pedro@gmail.com'
      ), equals('pedro'));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — TELÉFONO
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.extraerTelefonoDeDoc()', () {
    test('retorna teléfono si existe',  () => expect(ProcesadorFirestore.extraerTelefonoDeDoc({'telefono': '71234567'}), equals('71234567')));
    test('null → "No registrado"',       () => expect(ProcesadorFirestore.extraerTelefonoDeDoc(null), equals('No registrado')));
    test('vacío → "No registrado"',      () => expect(ProcesadorFirestore.extraerTelefonoDeDoc({}), equals('No registrado')));
    test('fallback a "phone" en inglés', () => expect(ProcesadorFirestore.extraerTelefonoDeDoc({'phone': '70000000'}), equals('70000000')));
  });

  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — CALIFICACIÓN
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.extraerCalificacionDeDoc()', () {
    test('int 4 → 4.0',         () => expect(ProcesadorFirestore.extraerCalificacionDeDoc({'calificacion': 4}), equals(4.0)));
    test('double 4.5 → 4.5',    () => expect(ProcesadorFirestore.extraerCalificacionDeDoc({'calificacion': 4.5}), equals(4.5)));
    test('null → 0.0',          () => expect(ProcesadorFirestore.extraerCalificacionDeDoc({'calificacion': null}), equals(0.0)));
    test('data null → 0.0',     () => expect(ProcesadorFirestore.extraerCalificacionDeDoc(null), equals(0.0)));
    test('sin campo → 0.0',     () => expect(ProcesadorFirestore.extraerCalificacionDeDoc({}), equals(0.0)));
  });

  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — PRECIO
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.extraerPrecioDeDoc()', () {
    test('int 250 → 250.0',     () => expect(ProcesadorFirestore.extraerPrecioDeDoc({'precio': 250}), equals(250.0)));
    test('double 150.5 → 150.5',() => expect(ProcesadorFirestore.extraerPrecioDeDoc({'precio': 150.5}), equals(150.5)));
    test('null → 0.0',          () => expect(ProcesadorFirestore.extraerPrecioDeDoc({'precio': null}), equals(0.0)));
    test('sin campo → 0.0',     () => expect(ProcesadorFirestore.extraerPrecioDeDoc({}), equals(0.0)));
  });

  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — DISPONIBILIDAD TÉCNICO
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.tecnicoDisponible()', () {
    test('true cuando disponible == true',   () => expect(ProcesadorFirestore.tecnicoDisponible({'disponible': true}), isTrue));
    test('false cuando disponible == false', () => expect(ProcesadorFirestore.tecnicoDisponible({'disponible': false}), isFalse));
    test('false cuando data es null',         () => expect(ProcesadorFirestore.tecnicoDisponible(null), isFalse));
    test('false cuando no existe campo',      () => expect(ProcesadorFirestore.tecnicoDisponible({}), isFalse));
    test('false cuando es "true" string (no booleano)', () => expect(ProcesadorFirestore.tecnicoDisponible({'disponible': 'true'}), isFalse));
  });

  // ══════════════════════════════════════════════════════════════════
  // PROCESADOR FIRESTORE — ESTADO CON FALLBACK
  // ══════════════════════════════════════════════════════════════════
  group('ProcesadorFirestore.estadoConFallback()', () {
    test('retorna estado existente', () => expect(ProcesadorFirestore.estadoConFallback({'estado': 'aceptado'}), equals('aceptado')));
    test('null → "pendiente"',        () => expect(ProcesadorFirestore.estadoConFallback(null), equals('pendiente')));
    test('sin campo → "pendiente"',   () => expect(ProcesadorFirestore.estadoConFallback({}), equals('pendiente')));
    test('respeta fallback custom',   () => expect(ProcesadorFirestore.estadoConFallback(null, fallback: 'aceptado'), equals('aceptado')));
  });

  // ══════════════════════════════════════════════════════════════════
  // FORMATO DE FECHA — UI
  // ══════════════════════════════════════════════════════════════════
  group('FormatoFecha.formatearParaUI()', () {
    test('formato DD/MM/YYYY HH:MM con ceros a la izquierda', () {
      expect(FormatoFecha.formatearParaUI(DateTime(2024, 3, 5, 9, 7)), equals('05/03/2024 09:07'));
    });

    test('fin de año a medianoche', () {
      expect(FormatoFecha.formatearParaUI(DateTime(2024, 12, 31, 23, 59)), equals('31/12/2024 23:59'));
    });

    test('inicio de año a las 00:00', () {
      expect(FormatoFecha.formatearParaUI(DateTime(2024, 1, 1, 0, 0)), equals('01/01/2024 00:00'));
    });

    test('formato siempre cumple expresión regular DD/MM/YYYY HH:MM', () {
      final r = FormatoFecha.formatearParaUI(DateTime(2025, 6, 15, 14, 30));
      expect(RegExp(r'^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$').hasMatch(r), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // FORMATO DE FECHA — SOLO HORA
  // ══════════════════════════════════════════════════════════════════
  group('FormatoFecha.formatearHora()', () {
    test('09:05 con cero',      () => expect(FormatoFecha.formatearHora(DateTime(2024, 1, 1, 9, 5)), equals('09:05')));
    test('medianoche 00:00',    () => expect(FormatoFecha.formatearHora(DateTime(2024, 1, 1, 0, 0)), equals('00:00')));
    test('23:59 final del día', () => expect(FormatoFecha.formatearHora(DateTime(2024, 1, 1, 23, 59)), equals('23:59')));
    test('mediodía 12:00',      () => expect(FormatoFecha.formatearHora(DateTime(2024, 1, 1, 12, 0)), equals('12:00')));
  });

  // ══════════════════════════════════════════════════════════════════
  // ORDENAMIENTO DE FECHAS
  // ══════════════════════════════════════════════════════════════════
  group('FormatoFecha.ordenarMasRecientePrimero()', () {
    test('ordena 3 fechas correctamente', () {
      final fechas = [
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31),
        DateTime(2024, 6, 15),
      ];
      final ord = FormatoFecha.ordenarMasRecientePrimero(fechas);
      expect(ord[0], equals(DateTime(2024, 12, 31)));
      expect(ord[1], equals(DateTime(2024, 6, 15)));
      expect(ord[2], equals(DateTime(2024, 1, 1)));
    });

    test('lista vacía retorna lista vacía', () {
      expect(FormatoFecha.ordenarMasRecientePrimero([]), isEmpty);
    });

    test('una sola fecha retorna esa fecha', () {
      final r = FormatoFecha.ordenarMasRecientePrimero([DateTime(2024, 5, 5)]);
      expect(r.length, equals(1));
      expect(r.first, equals(DateTime(2024, 5, 5)));
    });

    test('no modifica la lista original (trabaja sobre copia)', () {
      final orig = [DateTime(2024, 1, 1), DateTime(2024, 12, 31)];
      FormatoFecha.ordenarMasRecientePrimero(orig);
      expect(orig[0], equals(DateTime(2024, 1, 1))); // sigue igual
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // FILTROS DE LISTA DE SOLICITUDES
  // ══════════════════════════════════════════════════════════════════
  group('Filtrado de solicitudes por estado', () {
    final solicitudes = [
      {'id': '1', 'estado': 'pendiente'},
      {'id': '2', 'estado': 'aceptado'},
      {'id': '3', 'estado': 'en_proceso'},
      {'id': '4', 'estado': 'finalizado'},
      {'id': '5', 'estado': 'cancelado'},
      {'id': '6', 'estado': 'completado'},
    ];

    test('filtra activos correctamente (pendiente/aceptado/en_proceso)', () {
      final activos = solicitudes.where((s) =>
        ['pendiente', 'aceptado', 'en_proceso'].contains(s['estado'])
      ).toList();
      expect(activos.length, equals(3));
      expect(activos.map((e) => e['id']).toSet(), equals({'1', '2', '3'}));
    });

    test('filtra historial correctamente', () {
      final hist = solicitudes.where((s) =>
        ['finalizado', 'cancelado', 'completado'].contains(s['estado'])
      ).toList();
      expect(hist.length, equals(3));
      expect(hist.map((e) => e['id']).toSet(), equals({'4', '5', '6'}));
    });

    test('ningún elemento aparece en ambas listas', () {
      final activos = solicitudes.where((s) =>
        ['pendiente', 'aceptado', 'en_proceso'].contains(s['estado'])
      ).map((e) => e['id']).toSet();
      final hist = solicitudes.where((s) =>
        ['finalizado', 'cancelado', 'completado'].contains(s['estado'])
      ).map((e) => e['id']).toSet();
      expect(activos.intersection(hist), isEmpty);
    });
  });
}
