// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Validación de Perfil + Coordenadas GPS
// Archivo: test/perfil_y_gps_test.dart
// Ejecutar: flutter test test/perfil_y_gps_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Validadores extraídos de los registros y perfiles ──
class ValidadorPerfil {
  static const List<int> radiosPermitidos = [1, 3, 5, 10, 15];

  static bool nombreValido(String n) => n.trim().isNotEmpty && n.trim().length >= 2;

  static bool telefonoBolivianoValido(String t) {
    final limpio = t.replaceAll(RegExp(r'[\s\-\+]'), '');
    return limpio.isNotEmpty && limpio.length >= 7 && RegExp(r'^\d+$').hasMatch(limpio);
  }

  static bool especialidadValida(String e) => e.trim().length >= 2;

  static bool radioCoberturaValido(int km) => radiosPermitidos.contains(km);

  static bool emailValido(String email) =>
    RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);

  static String extraerIniciales(String nombre) =>
    nombre.trim().isEmpty ? 'A' : nombre.trim()[0].toUpperCase();

  static String extraerPrimerNombre(String nombreCompleto) =>
    nombreCompleto.trim().isEmpty ? '' : nombreCompleto.trim().split(' ')[0];
}

// ── Helpers de coordenadas GPS (Bolivia / El Alto) ──
class CoordenadasGps {
  static const double latElAlto = -16.5034;
  static const double lngElAlto = -68.1627;

  // Bounding box aproximado de Bolivia
  static const double latMinBolivia = -22.9;
  static const double latMaxBolivia = -9.7;
  static const double lngMinBolivia = -69.7;
  static const double lngMaxBolivia = -57.5;

  static bool coordenadaValida(double lat, double lng) =>
    lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  static bool estaEnBolivia(double lat, double lng) =>
    lat >= latMinBolivia && lat <= latMaxBolivia &&
    lng >= lngMinBolivia && lng <= lngMaxBolivia;

  static bool estaCercaDeElAlto(double lat, double lng, {double radioGrados = 0.1}) =>
    (lat - latElAlto).abs() < radioGrados &&
    (lng - lngElAlto).abs() < radioGrados;

  static double distanciaSimpleGrados(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    return dLat * dLat + dLng * dLng;
  }

  static bool zoomValido(double zoom) => zoom >= 1.0 && zoom <= 19.0;
}

void main() {
  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — NOMBRE
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil.nombreValido()', () {
    test('"Jo" (2 chars) es válido (mínimo)', () => expect(ValidadorPerfil.nombreValido('Jo'), isTrue));
    test('vacío es inválido',                 () => expect(ValidadorPerfil.nombreValido(''), isFalse));
    test('solo espacios es inválido',         () => expect(ValidadorPerfil.nombreValido('   '), isFalse));
    test('1 caracter es inválido',            () => expect(ValidadorPerfil.nombreValido('A'), isFalse));
    test('nombre boliviano completo válido',  () => expect(ValidadorPerfil.nombreValido('Felicitas Condori Mamani'), isTrue));
    test('espacios alrededor se recortan',    () => expect(ValidadorPerfil.nombreValido('  Juan  '), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — TELÉFONO BOLIVIANO
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil.telefonoBolivianoValido()', () {
    test('70000000 (móvil estándar) válido',  () => expect(ValidadorPerfil.telefonoBolivianoValido('70000000'), isTrue));
    test('71234567 válido',                    () => expect(ValidadorPerfil.telefonoBolivianoValido('71234567'), isTrue));
    test('número de 7 dígitos válido (mínimo)',() => expect(ValidadorPerfil.telefonoBolivianoValido('7654321'), isTrue));
    test('6 dígitos NO es válido',             () => expect(ValidadorPerfil.telefonoBolivianoValido('765432'), isFalse));
    test('vacío inválido',                     () => expect(ValidadorPerfil.telefonoBolivianoValido(''), isFalse));
    test('texto inválido',                     () => expect(ValidadorPerfil.telefonoBolivianoValido('siete-ocho'), isFalse));
    test('número con guiones se normaliza',    () => expect(ValidadorPerfil.telefonoBolivianoValido('700-123-45'), isTrue));
    test('con prefijo internacional +591',      () => expect(ValidadorPerfil.telefonoBolivianoValido('+59170000000'), isTrue));
    test('con espacios se normaliza',          () => expect(ValidadorPerfil.telefonoBolivianoValido('700 123 45'), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — ESPECIALIDAD
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil.especialidadValida()', () {
    test('Plomero válida',      () => expect(ValidadorPerfil.especialidadValida('Plomero'), isTrue));
    test('"Ab" (2 chars) válida',() => expect(ValidadorPerfil.especialidadValida('Ab'), isTrue));
    test('"A" (1 char) inválida',() => expect(ValidadorPerfil.especialidadValida('A'), isFalse));
    test('vacía inválida',       () => expect(ValidadorPerfil.especialidadValida(''), isFalse));
    test('Electricista válida',  () => expect(ValidadorPerfil.especialidadValida('Electricista'), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — RADIO DE COBERTURA
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil.radioCoberturaValido()', () {
    test('1 km válido',  () => expect(ValidadorPerfil.radioCoberturaValido(1), isTrue));
    test('3 km válido',  () => expect(ValidadorPerfil.radioCoberturaValido(3), isTrue));
    test('5 km válido',  () => expect(ValidadorPerfil.radioCoberturaValido(5), isTrue));
    test('10 km válido', () => expect(ValidadorPerfil.radioCoberturaValido(10), isTrue));
    test('15 km válido', () => expect(ValidadorPerfil.radioCoberturaValido(15), isTrue));
    test('2 km inválido (no está en opciones)', () => expect(ValidadorPerfil.radioCoberturaValido(2), isFalse));
    test('0 km inválido',  () => expect(ValidadorPerfil.radioCoberturaValido(0), isFalse));
    test('20 km inválido', () => expect(ValidadorPerfil.radioCoberturaValido(20), isFalse));
    test('exactamente 5 opciones de radio', () => expect(ValidadorPerfil.radiosPermitidos.length, equals(5)));
  });

  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — EMAIL
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil.emailValido()', () {
    test('Gmail válido',        () => expect(ValidadorPerfil.emailValido('usuario@gmail.com'), isTrue));
    test('email .bo válido',     () => expect(ValidadorPerfil.emailValido('tecnico@servicios.bo'), isTrue));
    test('subdominio válido',    () => expect(ValidadorPerfil.emailValido('user@mail.empresa.com'), isTrue));
    test('sin @ inválido',       () => expect(ValidadorPerfil.emailValido('usuariogmail.com'), isFalse));
    test('sin dominio inválido', () => expect(ValidadorPerfil.emailValido('usuario@'), isFalse));
    test('vacío inválido',       () => expect(ValidadorPerfil.emailValido(''), isFalse));
    test('con guiones en dominio', () => expect(ValidadorPerfil.emailValido('a@servicios-elalto.com'), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // VALIDADOR PERFIL — INICIALES Y PRIMER NOMBRE
  // ══════════════════════════════════════════════════════════════════
  group('ValidadorPerfil — utilidades de nombre', () {
    test('extraerIniciales primera letra en mayúscula', () {
      expect(ValidadorPerfil.extraerIniciales('felicitas condori'), equals('F'));
    });
    test('extraerIniciales vacío retorna "A" por defecto', () {
      expect(ValidadorPerfil.extraerIniciales(''), equals('A'));
    });
    test('extraerPrimerNombre toma solo el primero', () {
      expect(ValidadorPerfil.extraerPrimerNombre('Juan Carlos Mamani Quispe'), equals('Juan'));
    });
    test('extraerPrimerNombre con un solo nombre', () {
      expect(ValidadorPerfil.extraerPrimerNombre('María'), equals('María'));
    });
    test('extraerPrimerNombre vacío retorna vacío', () {
      expect(ValidadorPerfil.extraerPrimerNombre(''), equals(''));
    });
    test('extraerPrimerNombre recorta espacios al inicio', () {
      expect(ValidadorPerfil.extraerPrimerNombre('  Pedro Flores'), equals('Pedro'));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // COORDENADAS GPS - VALIDACIÓN
  // ══════════════════════════════════════════════════════════════════
  group('CoordenadasGps.coordenadaValida()', () {
    test('El Alto es válida',           () => expect(CoordenadasGps.coordenadaValida(-16.5034, -68.1627), isTrue));
    test('0,0 (nulo Greenwich) válida', () => expect(CoordenadasGps.coordenadaValida(0, 0), isTrue));
    test('lat 91 inválida',             () => expect(CoordenadasGps.coordenadaValida(91, 0), isFalse));
    test('lat -91 inválida',            () => expect(CoordenadasGps.coordenadaValida(-91, 0), isFalse));
    test('lng 181 inválida',            () => expect(CoordenadasGps.coordenadaValida(0, 181), isFalse));
    test('lng -181 inválida',           () => expect(CoordenadasGps.coordenadaValida(0, -181), isFalse));
    test('polo norte 90 válido',        () => expect(CoordenadasGps.coordenadaValida(90, 0), isTrue));
    test('polo sur -90 válido',         () => expect(CoordenadasGps.coordenadaValida(-90, 0), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // COORDENADAS GPS - DENTRO DE BOLIVIA
  // ══════════════════════════════════════════════════════════════════
  group('CoordenadasGps.estaEnBolivia()', () {
    test('El Alto está en Bolivia',     () => expect(CoordenadasGps.estaEnBolivia(-16.5034, -68.1627), isTrue));
    test('La Paz está en Bolivia',      () => expect(CoordenadasGps.estaEnBolivia(-16.5, -68.15), isTrue));
    test('Santa Cruz está en Bolivia',  () => expect(CoordenadasGps.estaEnBolivia(-17.7833, -63.1833), isTrue));
    test('Cochabamba está en Bolivia',  () => expect(CoordenadasGps.estaEnBolivia(-17.3895, -66.1568), isTrue));
    test('Sucre está en Bolivia',       () => expect(CoordenadasGps.estaEnBolivia(-19.0196, -65.2619), isTrue));
    test('Buenos Aires NO está',         () => expect(CoordenadasGps.estaEnBolivia(-34.6037, -58.3816), isFalse));
    test('Lima NO está',                 () => expect(CoordenadasGps.estaEnBolivia(-12.0464, -77.0428), isFalse));
    test('Madrid NO está',               () => expect(CoordenadasGps.estaEnBolivia(40.4168, -3.7038), isFalse));
  });

  // ══════════════════════════════════════════════════════════════════
  // COORDENADAS GPS - ZONA EL ALTO
  // ══════════════════════════════════════════════════════════════════
  group('CoordenadasGps.estaCercaDeElAlto()', () {
    test('coords exactas de El Alto', () => expect(CoordenadasGps.estaCercaDeElAlto(-16.5034, -68.1627), isTrue));
    test('La Paz (zona cercana)',     () => expect(CoordenadasGps.estaCercaDeElAlto(-16.5, -68.15), isTrue));
    test('Cochabamba NO está cerca',  () => expect(CoordenadasGps.estaCercaDeElAlto(-17.3895, -66.1568), isFalse));
    test('Santa Cruz NO está cerca',  () => expect(CoordenadasGps.estaCercaDeElAlto(-17.7833, -63.1833), isFalse));
  });

  // ══════════════════════════════════════════════════════════════════
  // COORDENADAS GPS - DISTANCIA Y ZOOM
  // ══════════════════════════════════════════════════════════════════
  group('CoordenadasGps.distanciaSimpleGrados()', () {
    test('distancia de un punto a sí mismo es 0', () {
      expect(CoordenadasGps.distanciaSimpleGrados(-16.5034, -68.1627, -16.5034, -68.1627), equals(0.0));
    });

    test('El Alto → La Paz es menor que El Alto → Santa Cruz', () {
      final dLP = CoordenadasGps.distanciaSimpleGrados(-16.5034, -68.1627, -16.5, -68.15);
      final dSC = CoordenadasGps.distanciaSimpleGrados(-16.5034, -68.1627, -17.7833, -63.1833);
      expect(dLP, lessThan(dSC));
    });

    test('distancia es simétrica (A→B == B→A)', () {
      final dAB = CoordenadasGps.distanciaSimpleGrados(-16.5034, -68.1627, -17.7833, -63.1833);
      final dBA = CoordenadasGps.distanciaSimpleGrados(-17.7833, -63.1833, -16.5034, -68.1627);
      expect(dAB, closeTo(dBA, 0.00001));
    });
  });

  group('CoordenadasGps.zoomValido()', () {
    test('zoom 15.0 (default de la app) válido', () => expect(CoordenadasGps.zoomValido(15.0), isTrue));
    test('zoom 1.0 (mínimo) válido',  () => expect(CoordenadasGps.zoomValido(1.0), isTrue));
    test('zoom 19.0 (máximo) válido', () => expect(CoordenadasGps.zoomValido(19.0), isTrue));
    test('zoom 0.9 inválido',         () => expect(CoordenadasGps.zoomValido(0.9), isFalse));
    test('zoom 20.0 inválido',        () => expect(CoordenadasGps.zoomValido(20.0), isFalse));
    test('zoom -1 inválido',          () => expect(CoordenadasGps.zoomValido(-1), isFalse));
  });
}
