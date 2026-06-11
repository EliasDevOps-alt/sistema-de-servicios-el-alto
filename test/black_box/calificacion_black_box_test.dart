import 'package:flutter_test/flutter_test.dart';

/// ══════════════════════════════════════════════════════════════════
/// BLACK BOX — CALIFICACIÓN DE SERVICIO (SIMULACIÓN LÓGICA)
/// ══════════════════════════════════════════════════════════════════
class CalificacionBlackBox {
  // Regla 1: Las estrellas deben estar estrictamente en el rango de 1 a 5
  static bool esPuntuacionValida(int estrellas) {
    return estrellas >= 1 && estrellas <= 5;
  }

  // Regla 2: Si la puntuación es baja (1 o 2 estrellas), el comentario de justificación es obligatorio
  static bool requiereJustificacion(int estrellas, String comentario) {
    if (estrellas <= 2) {
      return comentario.trim().isNotEmpty && comentario.trim().length >= 10;
    }
    return true;
  }

  // Regla 3: Solo se puede calificar si el estado actual del servicio es 'finalizado'
  static bool puedeCalificar(String estadoServicio) {
    return estadoServicio.trim().toLowerCase() == 'finalizado';
  }

  // Regla 4: Verificación del flujo completo de calificación
  static bool esCalificacionCompleta({
    required String estadoServicio,
    required int estrellas,
    required String comentario,
  }) {
    return puedeCalificar(estadoServicio) &&
        esPuntuacionValida(estrellas) &&
        requiereJustificacion(estrellas, comentario);
  }
}

/// ══════════════════════════════════════════════════════════════════
/// TESTS
/// ══════════════════════════════════════════════════════════════════
void main() {
  group('CalificacionBlackBox — Validación de Estrellas', () {
    test('Puntuación válida de 5 estrellas es aceptada', () {
      print('Ejecutando: Puntuación válida de 5 estrellas es aceptada');
      expect(CalificacionBlackBox.esPuntuacionValida(5), isTrue);
    });

    test('Puntuación de 3 estrellas es aceptada', () {
      print('Ejecutando: Puntuación de 3 estrellas es aceptada');
      expect(CalificacionBlackBox.esPuntuacionValida(3), isTrue);
    });

    test('Puntuación de 0 estrellas es rechazada', () {
      print('Ejecutando: Puntuación de 0 estrellas es rechazada');
      expect(CalificacionBlackBox.esPuntuacionValida(0), isFalse);
    });

    test('Puntuación de 6 estrellas es rechazada', () {
      print('Ejecutando: Puntuación de 6 estrellas es rechazada');
      expect(CalificacionBlackBox.esPuntuacionValida(6), isFalse);
    });
  });

  group('CalificacionBlackBox — Justificación Obligatoria', () {
    test('Puntuación de 5 estrellas no necesita comentario', () {
      print('Ejecutando: Puntuación de 5 estrellas no necesita comentario');
      expect(CalificacionBlackBox.requiereJustificacion(5, ''), isTrue);
    });

    test('Puntuación de 2 estrellas sin comentario es rechazada', () {
      print('Ejecutando: Puntuación de 2 estrellas sin comentario es rechazada');
      expect(CalificacionBlackBox.requiereJustificacion(2, ''), isFalse);
    });

    test('Puntuación de 1 estrella con comentario descriptivo es aprobada', () {
      print('Ejecutando: Puntuación de 1 estrella con comentario descriptivo es aprobada');
      expect(
        CalificacionBlackBox.requiereJustificacion(
          1,
          'El técnico no terminó el trabajo',
        ),
        isTrue,
      );
    });
  });

  group('CalificacionBlackBox — Restricción de Estado', () {
    test('Se permite calificar un servicio "finalizado"', () {
      print('Ejecutando: Se permite calificar un servicio "finalizado"');
      expect(CalificacionBlackBox.puedeCalificar('finalizado'), isTrue);
    });

    test('No se permite calificar un servicio "pendiente"', () {
      print('Ejecutando: No se permite calificar un servicio "pendiente"');
      expect(CalificacionBlackBox.puedeCalificar('pendiente'), isFalse);
    });
  });

  group('CalificacionBlackBox — Flujo Completo', () {
    test('Calificación exitosa (Servicio Finalizado, 5 estrellas)', () {
      print('Ejecutando: Calificación exitosa (Servicio Finalizado, 5 estrellas)');
      expect(
        CalificacionBlackBox.esCalificacionCompleta(
          estadoServicio: 'finalizado',
          estrellas: 5,
          comentario: 'Excelente servicio',
        ),
        isTrue,
      );
    });

    test('Calificación fallida por estado incorrecto', () {
      print('Ejecutando: Calificación fallida por estado incorrecto');
      expect(
        CalificacionBlackBox.esCalificacionCompleta(
          estadoServicio: 'en_curso',
          estrellas: 5,
          comentario: 'Bueno',
        ),
        isFalse,
      );
    });
  });
}
