// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Validadores de Solicitud de Servicio
// Archivo: test/solicitud_validacion_test.dart
// Ejecutar: flutter test test/solicitud_validacion_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Clases puras de validación extraídas de solicitud_servicio_screen.dart ──
class ValidadorSolicitud {
  static const List<String> categoriasValidas = [
    'Plomería', 'Electricidad', 'Albañilería', 'Limpieza',
    'Cerrajería', 'Pintura', 'Gasfitería', 'Otros'
  ];

  static bool camposCompletos({
    required String titulo,
    required String descripcion,
    required String? categoria,
  }) {
    return titulo.isNotEmpty && descripcion.isNotEmpty && categoria != null;
  }

  static bool tituloValido(String titulo) =>
      titulo.trim().isNotEmpty && titulo.trim().length >= 3;

  static bool descripcionValida(String descripcion) =>
      descripcion.trim().isNotEmpty && descripcion.trim().length >= 10;

  static bool categoriaValida(String? categoria) =>
      categoria != null && categoriasValidas.contains(categoria);

  static String formatearCoordenadasGps(double lat, double lng) =>
      'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  static Map<String, dynamic> construirDocumentoSolicitud({
    required String clienteUid,
    required String email,
    required String titulo,
    required String descripcion,
    required String categoria,
    required String ubicacion,
    double? latitud,
    double? longitud,
  }) {
    return {
      'cliente_uid':   clienteUid,
      'cliente_email': email,
      'titulo':        titulo.trim(),
      'descripcion':   descripcion.trim(),
      'categoria':     categoria,
      'ubicacion':     ubicacion.trim(),
      'latitud':       latitud,
      'longitud':      longitud,
      'estado':        'pendiente',
    };
  }
}

void main() {
  // ── Grupo 1: Campos completos ─────────────────────────────────
  group('ValidadorSolicitud.camposCompletos()', () {
    test('todos los campos presentes → true', () {
      expect(ValidadorSolicitud.camposCompletos(
        titulo: 'Caño roto',
        descripcion: 'El caño de la cocina gotea',
        categoria: 'Plomería',
      ), isTrue);
    });

    test('título vacío → false', () {
      expect(ValidadorSolicitud.camposCompletos(
        titulo: '', descripcion: 'algo', categoria: 'Electricidad',
      ), isFalse);
    });

    test('descripción vacía → false', () {
      expect(ValidadorSolicitud.camposCompletos(
        titulo: 'Algo', descripcion: '', categoria: 'Limpieza',
      ), isFalse);
    });

    test('categoría null → false', () {
      expect(ValidadorSolicitud.camposCompletos(
        titulo: 'X', descripcion: 'Y', categoria: null,
      ), isFalse);
    });

    test('todos vacíos → false', () {
      expect(ValidadorSolicitud.camposCompletos(
        titulo: '', descripcion: '', categoria: null,
      ), isFalse);
    });
  });

  // ── Grupo 2: Título válido ────────────────────────────────────
  group('ValidadorSolicitud.tituloValido()', () {
    test('título de 3 caracteres es válido (mínimo)', () {
      expect(ValidadorSolicitud.tituloValido('abc'), isTrue);
    });

    test('título vacío no es válido', () {
      expect(ValidadorSolicitud.tituloValido(''), isFalse);
    });

    test('título de solo espacios no es válido', () {
      expect(ValidadorSolicitud.tituloValido('   '), isFalse);
    });

    test('título de 2 caracteres no es válido', () {
      expect(ValidadorSolicitud.tituloValido('ab'), isFalse);
    });

    test('título descriptivo largo es válido', () {
      expect(ValidadorSolicitud.tituloValido('Caño del baño principal'), isTrue);
    });

    test('título con espacios alrededor se recorta y valida', () {
      expect(ValidadorSolicitud.tituloValido('  Hola  '), isTrue);
    });
  });

  // ── Grupo 3: Descripción válida ──────────────────────────────
  group('ValidadorSolicitud.descripcionValida()', () {
    test('descripción de 10 caracteres es válida', () {
      expect(ValidadorSolicitud.descripcionValida('1234567890'), isTrue);
    });

    test('descripción de 9 caracteres NO es válida', () {
      expect(ValidadorSolicitud.descripcionValida('123456789'), isFalse);
    });

    test('descripción vacía no es válida', () {
      expect(ValidadorSolicitud.descripcionValida(''), isFalse);
    });

    test('descripción detallada es válida', () {
      expect(ValidadorSolicitud.descripcionValida(
        'El grifo del lavabo principal gotea sin parar desde el lunes',
      ), isTrue);
    });
  });

  // ── Grupo 4: Categoría válida ─────────────────────────────────
  group('ValidadorSolicitud.categoriaValida()', () {
    test('Plomería es válida',     () => expect(ValidadorSolicitud.categoriaValida('Plomería'), isTrue));
    test('Electricidad es válida', () => expect(ValidadorSolicitud.categoriaValida('Electricidad'), isTrue));
    test('Albañilería es válida',  () => expect(ValidadorSolicitud.categoriaValida('Albañilería'), isTrue));
    test('Limpieza es válida',     () => expect(ValidadorSolicitud.categoriaValida('Limpieza'), isTrue));
    test('Cerrajería es válida',   () => expect(ValidadorSolicitud.categoriaValida('Cerrajería'), isTrue));
    test('Pintura es válida',      () => expect(ValidadorSolicitud.categoriaValida('Pintura'), isTrue));
    test('Gasfitería es válida',   () => expect(ValidadorSolicitud.categoriaValida('Gasfitería'), isTrue));
    test('Otros es válida',        () => expect(ValidadorSolicitud.categoriaValida('Otros'), isTrue));

    test('null NO es válida', () => expect(ValidadorSolicitud.categoriaValida(null), isFalse));
    test('Jardinería NO es válida (no en lista)',
      () => expect(ValidadorSolicitud.categoriaValida('Jardinería'), isFalse));
    test('cadena vacía NO es válida',
      () => expect(ValidadorSolicitud.categoriaValida(''), isFalse));

    test('exactamente 8 categorías están definidas', () {
      expect(ValidadorSolicitud.categoriasValidas.length, equals(8));
    });

    test('las 8 categorías son únicas', () {
      expect(ValidadorSolicitud.categoriasValidas.toSet().length, equals(8));
    });
  });

  // ── Grupo 5: Formato GPS ──────────────────────────────────────
  group('ValidadorSolicitud.formatearCoordenadasGps()', () {
    test('genera formato GPS: lat, lng', () {
      final r = ValidadorSolicitud.formatearCoordenadasGps(-16.5034, -68.1627);
      expect(r, startsWith('GPS:'));
      expect(r, contains('-16.50340'));
      expect(r, contains('-68.16270'));
    });

    test('siempre exactamente 5 decimales en latitud', () {
      final r = ValidadorSolicitud.formatearCoordenadasGps(-16.5, -68.1);
      expect(r, contains('-16.50000'));
      expect(r, contains('-68.10000'));
    });

    test('coordenadas de El Alto formateadas', () {
      final r = ValidadorSolicitud.formatearCoordenadasGps(-16.5034, -68.1627);
      expect(r, equals('GPS: -16.50340, -68.16270'));
    });
  });

  // ── Grupo 6: Construcción de documento Firestore ─────────────
  group('ValidadorSolicitud.construirDocumentoSolicitud()', () {
    test('estado inicial siempre es "pendiente"', () {
      final doc = ValidadorSolicitud.construirDocumentoSolicitud(
        clienteUid: 'uid', email: 'a@b.com',
        titulo: 'X', descripcion: 'Y', categoria: 'Plomería', ubicacion: 'Z',
      );
      expect(doc['estado'], equals('pendiente'));
    });

    test('recorta espacios del título', () {
      final doc = ValidadorSolicitud.construirDocumentoSolicitud(
        clienteUid: 'uid', email: 'a@b.com',
        titulo: '  Caño  ', descripcion: 'Descripción larga aquí',
        categoria: 'Plomería', ubicacion: 'Av X',
      );
      expect(doc['titulo'], equals('Caño'));
    });

    test('latitud y longitud son nullable', () {
      final doc = ValidadorSolicitud.construirDocumentoSolicitud(
        clienteUid: 'uid', email: 'a@b.com',
        titulo: 'X', descripcion: 'Y', categoria: 'Plomería', ubicacion: 'Z',
      );
      expect(doc['latitud'], isNull);
      expect(doc['longitud'], isNull);
    });

    test('incluye GPS cuando se provee', () {
      final doc = ValidadorSolicitud.construirDocumentoSolicitud(
        clienteUid: 'uid', email: 'a@b.com',
        titulo: 'X', descripcion: 'Y', categoria: 'Plomería', ubicacion: 'Z',
        latitud: -16.5034, longitud: -68.1627,
      );
      expect(doc['latitud'], equals(-16.5034));
      expect(doc['longitud'], equals(-68.1627));
    });

    test('preserva cliente_uid y email', () {
      final doc = ValidadorSolicitud.construirDocumentoSolicitud(
        clienteUid: 'firebase-uid-123', email: 'cliente@gmail.com',
        titulo: 'X', descripcion: 'Y', categoria: 'Plomería', ubicacion: 'Z',
      );
      expect(doc['cliente_uid'],   equals('firebase-uid-123'));
      expect(doc['cliente_email'], equals('cliente@gmail.com'));
    });
  });
}
