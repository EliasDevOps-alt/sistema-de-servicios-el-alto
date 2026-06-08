// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Validaciones de Perfil (Cliente y Técnico)
// Archivo: test/perfil_validacion_test.dart
// Qué testea: validaciones de nombre, teléfono, especialidad,
//             radio de cobertura, email, procesamiento de datos
//             de Firestore, y lógica de perfil incompleto
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Helpers de validación extraídos del sistema ──────────────────
class ValidadorPerfil {
  static bool nombreValido(String nombre) {
    return nombre.trim().isNotEmpty && nombre.trim().length >= 2;
  }

  static bool telefonoValido(String telefono) {
    final limpio = telefono.replaceAll(RegExp(r'[\s\-\+]'), '');
    return limpio.isNotEmpty && limpio.length >= 7 && RegExp(r'^\d+$').hasMatch(limpio);
  }

  static bool especialidadValida(String especialidad) {
    return especialidad.trim().isNotEmpty && especialidad.trim().length >= 2;
  }

  static bool radioValido(int radio, List<int> opcionesPermitidas) {
    return opcionesPermitidas.contains(radio);
  }

  static bool emailValido(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  static String extraerIniciales(String nombre) {
    if (nombre.isEmpty) return 'A';
    return nombre.trim()[0].toUpperCase();
  }

  static String extraerPrimerNombre(String nombreCompleto) {
    if (nombreCompleto.trim().isEmpty) return '';
    return nombreCompleto.trim().split(' ')[0];
  }

  static bool perfilClienteCompleto(Map<String, dynamic> datos) {
    return datos.containsKey('nombre') &&
           datos.containsKey('telefono') &&
           datos.containsKey('email') &&
           (datos['nombre'] as String? ?? '').isNotEmpty &&
           (datos['email'] as String? ?? '').isNotEmpty;
  }

  static bool perfilTecnicoCompleto(Map<String, dynamic> datos) {
    return datos.containsKey('nombre') &&
           datos.containsKey('especialidad') &&
           datos.containsKey('ubicacion') &&
           (datos['nombre'] as String? ?? '').isNotEmpty &&
           (datos['especialidad'] as String? ?? '').isNotEmpty &&
           datos['ubicacion'] != null;
  }
}

// ── Procesamiento de datos de Firestore ──────────────────────────
class ProcesadorDatosFirestore {
  static String extraerNombreDeDoc(Map<String, dynamic>? data, String email) {
    if (data == null) return email.split('@')[0];
    return data['nombre'] ?? data['name'] ?? email.split('@')[0];
  }

  static String extraerTelefonoDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 'No registrado';
    return data['telefono'] ?? data['phone'] ?? 'No registrado';
  }

  static double extraerCalificacionDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    final val = data['calificacion'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  static double extraerPrecioDeDoc(Map<String, dynamic>? data) {
    if (data == null) return 0.0;
    final val = data['precio'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  static bool tecnicoDisponible(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['disponible'] == true;
  }
}


void main() {
  // ── Grupo 1: Nombre válido ────────────────────────────────────
  group('ValidadorPerfil.nombreValido()', () {
    test('nombre de 2 caracteres es válido (mínimo)', () {
      expect(ValidadorPerfil.nombreValido('Jo'), isTrue);
    });

    test('nombre vacío no es válido', () {
      expect(ValidadorPerfil.nombreValido(''), isFalse);
    });

    test('nombre de sólo espacios no es válido', () {
      expect(ValidadorPerfil.nombreValido('   '), isFalse);
    });

    test('nombre de 1 caracter no es válido', () {
      expect(ValidadorPerfil.nombreValido('A'), isFalse);
    });

    test('nombre completo boliviano es válido', () {
      expect(ValidadorPerfil.nombreValido('Felicitas Condori Mamani'), isTrue);
    });

    test('nombre con espacios al inicio/fin se recorta y valida', () {
      expect(ValidadorPerfil.nombreValido('  Juan  '), isTrue);
    });
  });

  // ── Grupo 2: Teléfono válido ──────────────────────────────────
  group('ValidadorPerfil.telefonoValido()', () {
    test('número boliviano 70000000 es válido', () {
      expect(ValidadorPerfil.telefonoValido('70000000'), isTrue);
    });

    test('número con 7 dígitos es válido (mínimo)', () {
      expect(ValidadorPerfil.telefonoValido('7654321'), isTrue);
    });

    test('número con 6 dígitos NO es válido', () {
      expect(ValidadorPerfil.telefonoValido('765432'), isFalse);
    });

    test('número vacío no es válido', () {
      expect(ValidadorPerfil.telefonoValido(''), isFalse);
    });

    test('texto no numérico no es válido', () {
      expect(ValidadorPerfil.telefonoValido('siete-ocho'), isFalse);
    });

    test('número con guiones se normaliza y valida', () {
      expect(ValidadorPerfil.telefonoValido('700-123-45'), isTrue);
    });

    test('número con prefijo + se normaliza y valida', () {
      expect(ValidadorPerfil.telefonoValido('+59170000000'), isTrue);
    });
  });

  // ── Grupo 3: Especialidad válida ──────────────────────────────
  group('ValidadorPerfil.especialidadValida()', () {
    test('Plomero es válida', () => expect(ValidadorPerfil.especialidadValida('Plomero'), isTrue));
    test('Ab (2 chars) es válida', () => expect(ValidadorPerfil.especialidadValida('Ab'), isTrue));
    test('A (1 char) no es válida', () => expect(ValidadorPerfil.especialidadValida('A'), isFalse));
    test('vacía no es válida', () => expect(ValidadorPerfil.especialidadValida(''), isFalse));
    test('Electricista es válida', () => expect(ValidadorPerfil.especialidadValida('Electricista'), isTrue));
  });

  // ── Grupo 4: Radio de cobertura ───────────────────────────────
  group('ValidadorPerfil.radioValido()', () {
    const opcionesRadio = [1, 3, 5, 10, 15];

    test('radio 1 km es válido', () => expect(ValidadorPerfil.radioValido(1, opcionesRadio), isTrue));
    test('radio 3 km es válido', () => expect(ValidadorPerfil.radioValido(3, opcionesRadio), isTrue));
    test('radio 5 km es válido', () => expect(ValidadorPerfil.radioValido(5, opcionesRadio), isTrue));
    test('radio 10 km es válido', () => expect(ValidadorPerfil.radioValido(10, opcionesRadio), isTrue));
    test('radio 15 km es válido', () => expect(ValidadorPerfil.radioValido(15, opcionesRadio), isTrue));
    test('radio 2 km NO es válido (no está en opciones)', () => expect(ValidadorPerfil.radioValido(2, opcionesRadio), isFalse));
    test('radio 0 km NO es válido', () => expect(ValidadorPerfil.radioValido(0, opcionesRadio), isFalse));
    test('radio 20 km NO es válido', () => expect(ValidadorPerfil.radioValido(20, opcionesRadio), isFalse));
    test('todas las 5 opciones son válidas', () {
      for (final r in opcionesRadio) {
        expect(ValidadorPerfil.radioValido(r, opcionesRadio), isTrue, reason: 'Radio $r km debe ser válido');
      }
    });
  });

  // ── Grupo 5: Email válido ─────────────────────────────────────
  group('ValidadorPerfil.emailValido()', () {
    test('email Google válido', () => expect(ValidadorPerfil.emailValido('usuario@gmail.com'), isTrue));
    test('email sin @ no es válido', () => expect(ValidadorPerfil.emailValido('usuariogmail.com'), isFalse));
    test('email sin dominio no es válido', () => expect(ValidadorPerfil.emailValido('usuario@'), isFalse));
    test('email vacío no es válido', () => expect(ValidadorPerfil.emailValido(''), isFalse));
    test('email con subdominio es válido', () => expect(ValidadorPerfil.emailValido('user@mail.empresa.com'), isTrue));
    test('email institucional es válido', () => expect(ValidadorPerfil.emailValido('tecnico@servicios-elalto.bo'), isTrue));
  });

  // ── Grupo 6: Iniciales y primer nombre ───────────────────────
  group('ValidadorPerfil — extracción de nombre', () {
    test('extraerIniciales retorna primera letra en mayúscula', () {
      expect(ValidadorPerfil.extraerIniciales('felicitas condori'), equals('F'));
    });

    test('extraerIniciales retorna A con nombre vacío (default)', () {
      expect(ValidadorPerfil.extraerIniciales(''), equals('A'));
    });

    test('extraerPrimerNombre retorna solo el primer nombre', () {
      expect(ValidadorPerfil.extraerPrimerNombre('Juan Carlos Mamani'), equals('Juan'));
    });

    test('extraerPrimerNombre con un solo nombre retorna ese nombre', () {
      expect(ValidadorPerfil.extraerPrimerNombre('María'), equals('María'));
    });

    test('extraerPrimerNombre con vacío retorna vacío', () {
      expect(ValidadorPerfil.extraerPrimerNombre(''), equals(''));
    });

    test('extraerPrimerNombre recorta espacios iniciales', () {
      expect(ValidadorPerfil.extraerPrimerNombre('  Pedro Flores'), equals('Pedro'));
    });
  });

  // ── Grupo 7: perfilCompleto ───────────────────────────────────
  group('ValidadorPerfil — perfilClienteCompleto()', () {
    test('perfil con nombre, email y teléfono es completo', () {
      final datos = {'nombre': 'Juan Mamani', 'email': 'juan@gmail.com', 'telefono': '70000001'};
      expect(ValidadorPerfil.perfilClienteCompleto(datos), isTrue);
    });

    test('perfil sin teléfono aún es aceptable (teléfono es opcional)', () {
      final datos = {'nombre': 'Ana Quispe', 'email': 'ana@gmail.com'};
      expect(ValidadorPerfil.perfilClienteCompleto(datos), isTrue);
    });

    test('perfil sin nombre es incompleto', () {
      final datos = {'nombre': '', 'email': 'sin@nombre.com'};
      expect(ValidadorPerfil.perfilClienteCompleto(datos), isFalse);
    });

    test('perfil sin email es incompleto', () {
      final datos = {'nombre': 'Carlos Flores', 'email': ''};
      expect(ValidadorPerfil.perfilClienteCompleto(datos), isFalse);
    });
  });

  group('ValidadorPerfil — perfilTecnicoCompleto()', () {
    test('técnico con nombre, especialidad y ubicación es completo', () {
      final datos = {'nombre': 'Pedro Quispe', 'especialidad': 'Plomería', 'ubicacion': {'lat': -16.5, 'lng': -68.1}};
      expect(ValidadorPerfil.perfilTecnicoCompleto(datos), isTrue);
    });

    test('técnico sin ubicación es incompleto', () {
      final datos = {'nombre': 'Pedro', 'especialidad': 'Plomería', 'ubicacion': null};
      expect(ValidadorPerfil.perfilTecnicoCompleto(datos), isFalse);
    });

    test('técnico sin especialidad es incompleto', () {
      final datos = {'nombre': 'Pedro', 'especialidad': '', 'ubicacion': {}};
      expect(ValidadorPerfil.perfilTecnicoCompleto(datos), isFalse);
    });
  });

  // ── Grupo 8: ProcesadorDatosFirestore ─────────────────────────
  group('ProcesadorDatosFirestore — extracción de campos', () {
    test('extraerNombreDeDoc usa "nombre" si existe', () {
      final datos = {'nombre': 'María Flores', 'email': 'maria@gmail.com'};
      expect(ProcesadorDatosFirestore.extraerNombreDeDoc(datos, 'maria@gmail.com'), equals('María Flores'));
    });

    test('extraerNombreDeDoc usa parte del email si no hay nombre', () {
      expect(ProcesadorDatosFirestore.extraerNombreDeDoc(null, 'tecnico99@gmail.com'), equals('tecnico99'));
    });

    test('extraerNombreDeDoc usa "name" como fallback', () {
      final datos = {'name': 'Jorge Apaza'};
      expect(ProcesadorDatosFirestore.extraerNombreDeDoc(datos, 'jorge@gmail.com'), equals('Jorge Apaza'));
    });

    test('extraerTelefonoDeDoc retorna teléfono si existe', () {
      final datos = {'telefono': '71234567'};
      expect(ProcesadorDatosFirestore.extraerTelefonoDeDoc(datos), equals('71234567'));
    });

    test('extraerTelefonoDeDoc retorna "No registrado" si no hay teléfono', () {
      expect(ProcesadorDatosFirestore.extraerTelefonoDeDoc({}), equals('No registrado'));
    });

    test('extraerCalificacionDeDoc retorna double correctamente', () {
      final datos = {'calificacion': 4};
      expect(ProcesadorDatosFirestore.extraerCalificacionDeDoc(datos), equals(4.0));
    });

    test('extraerCalificacionDeDoc retorna 0.0 cuando es null', () {
      expect(ProcesadorDatosFirestore.extraerCalificacionDeDoc({'calificacion': null}), equals(0.0));
    });

    test('extraerPrecioDeDoc convierte num a double', () {
      final datos = {'precio': 250};
      expect(ProcesadorDatosFirestore.extraerPrecioDeDoc(datos), equals(250.0));
    });

    test('extraerPrecioDeDoc retorna 0.0 si precio es null', () {
      expect(ProcesadorDatosFirestore.extraerPrecioDeDoc({'precio': null}), equals(0.0));
    });

    test('tecnicoDisponible retorna true cuando disponible es true', () {
      expect(ProcesadorDatosFirestore.tecnicoDisponible({'disponible': true}), isTrue);
    });

    test('tecnicoDisponible retorna false cuando disponible es false', () {
      expect(ProcesadorDatosFirestore.tecnicoDisponible({'disponible': false}), isFalse);
    });

    test('tecnicoDisponible retorna false con datos null', () {
      expect(ProcesadorDatosFirestore.tecnicoDisponible(null), isFalse);
    });
  });
}
