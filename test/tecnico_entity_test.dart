// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Entidad Tecnico
// Archivo: test/tecnico_entity_test.dart
// Ejecutar: flutter test test/tecnico_entity_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_servicios/domain/entities/tecnico.dart';

void main() {
  // ── Grupo 1: puedeTrabajar() ──────────────────────────────────
  group('Tecnico.puedeTrabajar() — regla de negocio crítica', () {
    test('false cuando identidad NO verificada y GPS activo', () {
      final t = Tecnico(
        id: '1', nombreCompleto: 'Juan Mamani', carnetIdentidad: '1234567',
        especialidad: 'Plomería', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        identidadVerificada: false, disponibleGps: true,
      );
      expect(t.puedeTrabajar(), isFalse);
    });

    test('false cuando identidad verificada pero GPS inactivo', () {
      final t = Tecnico(
        id: '2', nombreCompleto: 'Pedro Quispe', carnetIdentidad: '7654321',
        especialidad: 'Electricidad', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        identidadVerificada: true, disponibleGps: false,
      );
      expect(t.puedeTrabajar(), isFalse);
    });

    test('true solo cuando AMBOS verificado Y GPS activo', () {
      final t = Tecnico(
        id: '3', nombreCompleto: 'Carlos Flores', carnetIdentidad: '9876543',
        especialidad: 'Albañilería', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        identidadVerificada: true, disponibleGps: true,
      );
      expect(t.puedeTrabajar(), isTrue);
    });

    test('false cuando ambos son false (técnico recién registrado)', () {
      final t = Tecnico(
        id: '4', nombreCompleto: 'Luis Chura', carnetIdentidad: '1111111',
        especialidad: 'Limpieza', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
      );
      expect(t.puedeTrabajar(), isFalse);
    });
  });

  // ── Grupo 2: Valores por defecto ─────────────────────────────
  group('Tecnico — valores por defecto al registrarse', () {
    final t = Tecnico(
      id: '5', nombreCompleto: 'Ana Copa', carnetIdentidad: '2222222',
      especialidad: 'Cerrajería', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
    );
    test('identidadVerificada por defecto es false', () => expect(t.identidadVerificada, isFalse));
    test('disponibleGps por defecto es false',       () => expect(t.disponibleGps, isFalse));
    test('promedioCalificacion por defecto es 0.0',  () => expect(t.promedioCalificacion, equals(0.0)));
    test('aniosExperiencia por defecto es 0',        () => expect(t.aniosExperiencia, equals(0)));
  });

  // ── Grupo 3: Integridad de campos ─────────────────────────────
  group('Tecnico — integridad de datos almacenados', () {
    test('almacena nombre completo correctamente', () {
      final t = Tecnico(
        id: 'uid-001', nombreCompleto: 'Felicitas Condori Mamani',
        carnetIdentidad: '6543210', especialidad: 'Electricidad',
        fotoPerfilUrl: 'https://foto.com/img.jpg',
        certificadoAntecedentesUrl: 'https://docs.com/cert.pdf',
      );
      expect(t.nombreCompleto, equals('Felicitas Condori Mamani'));
    });

    test('almacena carnet de identidad correctamente', () {
      final t = Tecnico(
        id: 'uid-002', nombreCompleto: 'Bernardo Quispe',
        carnetIdentidad: '8765432', especialidad: 'Plomería',
        fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
      );
      expect(t.carnetIdentidad, equals('8765432'));
    });

    test('almacena calificación con precisión decimal', () {
      final t = Tecnico(
        id: 'uid-004', nombreCompleto: 'Raul Paco',
        carnetIdentidad: '1234321', especialidad: 'Electricidad',
        fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        promedioCalificacion: 4.7,
      );
      expect(t.promedioCalificacion, closeTo(4.7, 0.001));
    });

    test('almacena años de experiencia personalizado', () {
      final t = Tecnico(
        id: 'uid-005', nombreCompleto: 'Dario Mamani',
        carnetIdentidad: '4321234', especialidad: 'Cerrajería',
        fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        aniosExperiencia: 8,
      );
      expect(t.aniosExperiencia, equals(8));
    });

    test('almacena URL de foto y certificado', () {
      final t = Tecnico(
        id: 'uid-006', nombreCompleto: 'Test',
        carnetIdentidad: '1111111', especialidad: 'Pintura',
        fotoPerfilUrl: 'https://storage.firebase.com/foto.jpg',
        certificadoAntecedentesUrl: 'https://storage.firebase.com/cert.pdf',
      );
      expect(t.fotoPerfilUrl, contains('storage.firebase.com'));
      expect(t.certificadoAntecedentesUrl, endsWith('.pdf'));
    });
  });

  // ── Grupo 4: Rangos de calificación ──────────────────────────
  group('Tecnico — rangos válidos de calificación', () {
    test('5.0 es el máximo posible', () {
      final t = Tecnico(
        id: '1', nombreCompleto: 'X', carnetIdentidad: '0',
        especialidad: 'P', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        promedioCalificacion: 5.0,
      );
      expect(t.promedioCalificacion, lessThanOrEqualTo(5.0));
    });

    test('0.0 es el mínimo posible (nuevo)', () {
      final t = Tecnico(
        id: '2', nombreCompleto: 'X', carnetIdentidad: '0',
        especialidad: 'P', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        promedioCalificacion: 0.0,
      );
      expect(t.promedioCalificacion, greaterThanOrEqualTo(0.0));
    });

    test('promedio de 3.5 es válido (entre 0 y 5)', () {
      final t = Tecnico(
        id: '3', nombreCompleto: 'X', carnetIdentidad: '0',
        especialidad: 'P', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        promedioCalificacion: 3.5,
      );
      expect(t.promedioCalificacion, inInclusiveRange(0.0, 5.0));
    });

    test('técnico con 5.0 + verificado + GPS puede trabajar', () {
      final t = Tecnico(
        id: '4', nombreCompleto: 'Top', carnetIdentidad: '9999',
        especialidad: 'Electricidad', fotoPerfilUrl: '', certificadoAntecedentesUrl: '',
        identidadVerificada: true, disponibleGps: true,
        promedioCalificacion: 5.0,
      );
      expect(t.puedeTrabajar(), isTrue);
      expect(t.promedioCalificacion, equals(5.0));
    });
  });
}
