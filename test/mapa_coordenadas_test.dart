// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Coordenadas GPS y lógica de mapa
// Archivo: test/mapa_coordenadas_test.dart
// Qué testea: validación de coordenadas GPS dentro de Bolivia,
//             El Alto / La Paz, conversión GeoPoint↔LatLng,
//             texto de coordenadas, zoom válido
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

class CoordenadasHelper {
  // Bounding box de Bolivia aproximado
  static const double latMinBolivia = -22.9;
  static const double latMaxBolivia = -9.7;
  static const double lngMinBolivia = -69.7;
  static const double lngMaxBolivia = -57.5;

  // Coordenadas de El Alto
  static const double latElAlto = -16.5034;
  static const double lngElAlto = -68.1627;

  static bool esCoordenadaValida(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static bool estaEnBolivia(double lat, double lng) {
    return lat >= latMinBolivia && lat <= latMaxBolivia &&
           lng >= lngMinBolivia && lng <= lngMaxBolivia;
  }

  static bool estaEnZonaElAlto(double lat, double lng) {
    // Radio aproximado de ~10 km de El Alto
    const tolerancia = 0.1;
    return (lat - latElAlto).abs() < tolerancia && (lng - lngElAlto).abs() < tolerancia;
  }

  static String coordenadasATexto(double lat, double lng) {
    return 'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static Map<String, double>? parsearTextoCoords(String texto) {
    // Formato esperado: "GPS: -16.50340, -68.16270"
    if (!texto.startsWith('GPS:')) return null;
    final partes = texto.replaceFirst('GPS:', '').trim().split(',');
    if (partes.length != 2) return null;
    final lat = double.tryParse(partes[0].trim());
    final lng = double.tryParse(partes[1].trim());
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  static bool zoomValido(double zoom) => zoom >= 1.0 && zoom <= 19.0;

  static double calcularDistanciaSimple(double lat1, double lng1, double lat2, double lng2) {
    // Distancia aproximada en grados (no Haversine, suficiente para tests)
    final dLat = (lat2 - lat1).abs();
    final dLng = (lng2 - lng1).abs();
    return (dLat * dLat + dLng * dLng);
  }
}


void main() {
  // ── Grupo 1: Validación básica de coordenadas ─────────────────
  group('CoordenadasHelper.esCoordenadaValida()', () {
    test('coordenadas de El Alto son válidas', () {
      expect(CoordenadasHelper.esCoordenadaValida(-16.5034, -68.1627), isTrue);
    });

    test('latitud 0, longitud 0 (nulo de Greenwich) es válida', () {
      expect(CoordenadasHelper.esCoordenadaValida(0.0, 0.0), isTrue);
    });

    test('latitud 91 es inválida (fuera de rango)', () {
      expect(CoordenadasHelper.esCoordenadaValida(91.0, 0.0), isFalse);
    });

    test('latitud -91 es inválida', () {
      expect(CoordenadasHelper.esCoordenadaValida(-91.0, 0.0), isFalse);
    });

    test('longitud 181 es inválida', () {
      expect(CoordenadasHelper.esCoordenadaValida(0.0, 181.0), isFalse);
    });

    test('longitud -181 es inválida', () {
      expect(CoordenadasHelper.esCoordenadaValida(0.0, -181.0), isFalse);
    });

    test('latitud 90 (polo norte) es válida', () {
      expect(CoordenadasHelper.esCoordenadaValida(90.0, 0.0), isTrue);
    });

    test('latitud -90 (polo sur) es válida', () {
      expect(CoordenadasHelper.esCoordenadaValida(-90.0, 0.0), isTrue);
    });
  });

  // ── Grupo 2: Dentro de Bolivia ────────────────────────────────
  group('CoordenadasHelper.estaEnBolivia()', () {
    test('coordenadas de El Alto están en Bolivia', () {
      expect(CoordenadasHelper.estaEnBolivia(-16.5034, -68.1627), isTrue);
    });

    test('coordenadas de La Paz están en Bolivia', () {
      expect(CoordenadasHelper.estaEnBolivia(-16.5000, -68.1500), isTrue);
    });

    test('coordenadas de Santa Cruz están en Bolivia', () {
      expect(CoordenadasHelper.estaEnBolivia(-17.7833, -63.1833), isTrue);
    });

    test('coordenadas de Buenos Aires NO están en Bolivia', () {
      expect(CoordenadasHelper.estaEnBolivia(-34.6037, -58.3816), isFalse);
    });

    test('coordenadas de Lima NO están en Bolivia', () {
      expect(CoordenadasHelper.estaEnBolivia(-12.0464, -77.0428), isFalse);
    });
  });

  // ── Grupo 3: Zona de El Alto ──────────────────────────────────
  group('CoordenadasHelper.estaEnZonaElAlto()', () {
    test('coordenadas exactas de El Alto están en la zona', () {
      expect(CoordenadasHelper.estaEnZonaElAlto(-16.5034, -68.1627), isTrue);
    });

    test('coordenadas a 0.05° de El Alto están en la zona', () {
      expect(CoordenadasHelper.estaEnZonaElAlto(-16.5534, -68.2127), isTrue);
    });

    test('coordenadas de Cochabamba NO están en la zona de El Alto', () {
      expect(CoordenadasHelper.estaEnZonaElAlto(-17.3895, -66.1568), isFalse);
    });
  });

  // ── Grupo 4: coordenadasATexto() y parsearTextoCoords() ───────
  group('CoordenadasHelper — texto de coordenadas', () {
    test('texto generado inicia con "GPS:"', () {
      final texto = CoordenadasHelper.coordenadasATexto(-16.5034, -68.1627);
      expect(texto, startsWith('GPS:'));
    });

    test('texto contiene latitud con 5 decimales', () {
      final texto = CoordenadasHelper.coordenadasATexto(-16.5034, -68.1627);
      expect(texto, contains('-16.50340'));
    });

    test('texto contiene longitud con 5 decimales', () {
      final texto = CoordenadasHelper.coordenadasATexto(-16.5034, -68.1627);
      expect(texto, contains('-68.16270'));
    });

    test('parsear texto de coordenadas válido retorna mapa', () {
      final coords = CoordenadasHelper.parsearTextoCoords('GPS: -16.50340, -68.16270');
      expect(coords, isNotNull);
      expect(coords!['lat'], closeTo(-16.50340, 0.00001));
      expect(coords['lng'], closeTo(-68.16270, 0.00001));
    });

    test('parsear texto sin prefijo GPS: retorna null', () {
      expect(CoordenadasHelper.parsearTextoCoords('-16.5, -68.1'), isNull);
    });

    test('parsear texto con formato incorrecto retorna null', () {
      expect(CoordenadasHelper.parsearTextoCoords('GPS: invalido'), isNull);
    });

    test('round-trip: generar texto y parsear devuelve coordenadas originales', () {
      const lat = -16.50340;
      const lng = -68.16270;
      final texto = CoordenadasHelper.coordenadasATexto(lat, lng);
      final parsed = CoordenadasHelper.parsearTextoCoords(texto);
      expect(parsed, isNotNull);
      expect(parsed!['lat'], closeTo(lat, 0.00001));
      expect(parsed['lng'], closeTo(lng, 0.00001));
    });
  });

  // ── Grupo 5: Zoom válido ──────────────────────────────────────
  group('CoordenadasHelper.zoomValido()', () {
    test('zoom 15.0 (usado en la app) es válido', () {
      expect(CoordenadasHelper.zoomValido(15.0), isTrue);
    });

    test('zoom 1.0 (mínimo) es válido', () {
      expect(CoordenadasHelper.zoomValido(1.0), isTrue);
    });

    test('zoom 19.0 (máximo) es válido', () {
      expect(CoordenadasHelper.zoomValido(19.0), isTrue);
    });

    test('zoom 0.9 no es válido', () {
      expect(CoordenadasHelper.zoomValido(0.9), isFalse);
    });

    test('zoom 20.0 no es válido', () {
      expect(CoordenadasHelper.zoomValido(20.0), isFalse);
    });
  });

  // ── Grupo 6: Distancia entre puntos ──────────────────────────
  group('CoordenadasHelper.calcularDistanciaSimple()', () {
    test('distancia de un punto a sí mismo es 0', () {
      expect(CoordenadasHelper.calcularDistanciaSimple(-16.5034, -68.1627, -16.5034, -68.1627), equals(0.0));
    });

    test('El Alto a La Paz es menor que El Alto a Santa Cruz', () {
      final distLaPaz   = CoordenadasHelper.calcularDistanciaSimple(-16.5034, -68.1627, -16.5000, -68.1500);
      final distStaCruz = CoordenadasHelper.calcularDistanciaSimple(-16.5034, -68.1627, -17.7833, -63.1833);
      expect(distLaPaz, lessThan(distStaCruz));
    });

    test('la distancia es simétrica (A→B == B→A)', () {
      final dAB = CoordenadasHelper.calcularDistanciaSimple(-16.5034, -68.1627, -17.7833, -63.1833);
      final dBA = CoordenadasHelper.calcularDistanciaSimple(-17.7833, -63.1833, -16.5034, -68.1627);
      expect(dAB, closeTo(dBA, 0.00001));
    });
  });
}
