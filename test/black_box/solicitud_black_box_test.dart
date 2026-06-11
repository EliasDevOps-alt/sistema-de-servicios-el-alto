// ══════════════════════════════════════════════════════════════════
// PLAN DE PRUEBAS DE CAJA NEGRA — SOLICITUDES DE SERVICIOS
// Código de Módulo: QA-SOL
// ══════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

/// SIMULADOR DE LÓGICA DE NEGOCIO PARA CREAR SOLICITUDES (CAJA NEGRA)
class SolicitudBlackBox {
  static bool esTituloValido(String titulo) {
    return titulo.trim().isNotEmpty && titulo.trim().length >= 3;
  }

  static bool esDescripcionValida(String desc) {
    return desc.trim().isNotEmpty && desc.trim().length >= 10;
  }

  static bool esCategoriaValida(String? categoria) {
    const categorias = [
      'electricidad',
      'plomeria',
      'carpinteria',
      'limpieza',
      'pintura',
      'gas',
      'electronica',
      'otros',
    ];
    return categoria != null && categorias.contains(categoria);
  }

  static bool esSolicitudValida({
    required String titulo,
    required String descripcion,
    required String? categoria,
  }) {
    return esTituloValido(titulo) &&
        esDescripcionValida(descripcion) &&
        esCategoriaValida(categoria);
  }

  static bool evitaDobleEnvio(int clicks) {
    return clicks == 1;
  }
}

void main() {
  group('🛠️ [QA-SOL] MÓDULO DE SOLICITUDES DE SERVICIO', () {

    group('🏷️ [QA-SOL-TTL] Validación de Longitud y Contenido de Título', () {
      test('QA-SOL-TTL-001: [ÉXITO] Dado un título válido de longitud razonable, debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-TTL-001: [ÉXITO] Dado un título válido de longitud razonable, debería retornar TRUE');
        // GIVEN
        const titulo = 'Instalación de tomacorriente';
        // WHEN
        final resultado = SolicitudBlackBox.esTituloValido(titulo);
        // THEN
        expect(resultado, isTrue, reason: 'El título es descriptivo y supera los 3 caracteres.');
      });

      test('QA-SOL-TTL-002: [FALLO] Dado un título vacío, debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-TTL-002: [FALLO] Dado un título vacío, debería retornar FALSE');
        const titulo = '';
        final resultado = SolicitudBlackBox.esTituloValido(titulo);
        expect(resultado, isFalse, reason: 'Un título vacío no es aceptable en el sistema.');
      });

      test('QA-SOL-TTL-003: [FALLO] Dado un título compuesto solo por espacios vacíos, debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-TTL-003: [FALLO] Dado un título compuesto solo por espacios vacíos, debería retornar FALSE');
        const titulo = '    ';
        final resultado = SolicitudBlackBox.esTituloValido(titulo);
        expect(resultado, isFalse, reason: 'Los espacios vacíos deben ser limpiados y considerados vacíos.');
      });

      test('QA-SOL-TTL-004: [FALLO] Dado un título muy corto por debajo del límite mínimo (2 caracteres), debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-TTL-004: [FALLO] Dado un título muy corto por debajo del límite mínimo (2 caracteres), debería retornar FALSE');
        const titulo = 'Ok';
        final resultado = SolicitudBlackBox.esTituloValido(titulo);
        expect(resultado, isFalse, reason: 'El título debe tener al menos 3 caracteres.');
      });

      test('QA-SOL-TTL-005: [ÉXITO] Dado un título con la longitud mínima exacta (3 caracteres), debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-TTL-005: [ÉXITO] Dado un título con la longitud mínima exacta (3 caracteres), debería retornar TRUE');
        const titulo = 'Luz';
        final resultado = SolicitudBlackBox.esTituloValido(titulo);
        expect(resultado, isTrue, reason: '3 caracteres es el límite inferior exacto de aceptación.');
      });
    });

    group('📝 [QA-SOL-DSC] Validación de Detalle y Longitud de Descripción', () {
      test('QA-SOL-DSC-001: [ÉXITO] Dada una descripción con detalles claros y longitud válida, debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-DSC-001: [ÉXITO] Dada una descripción con detalles claros y longitud válida, debería retornar TRUE');
        const desc = 'El lavamanos de la cocina tiene una fuga de agua constante.';
        final resultado = SolicitudBlackBox.esDescripcionValida(desc);
        expect(resultado, isTrue);
      });

      test('QA-SOL-DSC-002: [FALLO] Dada una descripción vacía, debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-DSC-002: [FALLO] Dada una descripción vacía, debería retornar FALSE');
        const desc = '';
        final resultado = SolicitudBlackBox.esDescripcionValida(desc);
        expect(resultado, isFalse);
      });

      test('QA-SOL-DSC-003: [FALLO] Dada una descripción muy corta (9 caracteres), debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-DSC-003: [FALLO] Dada una descripción muy corta (9 caracteres), debería retornar FALSE');
        const desc = 'Tengo fug';
        final resultado = SolicitudBlackBox.esDescripcionValida(desc);
        expect(resultado, isFalse, reason: 'La descripción requiere al menos 10 caracteres de contexto.');
      });

      test('QA-SOL-DSC-004: [ÉXITO] Dada una descripción con la longitud mínima exacta (10 caracteres), debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-DSC-004: [ÉXITO] Dada una descripción con la longitud mínima exacta (10 caracteres), debería retornar TRUE');
        const desc = 'Gotea baño';
        final resultado = SolicitudBlackBox.esDescripcionValida(desc);
        expect(resultado, isTrue, reason: '10 caracteres es el límite inferior exacto de aceptación.');
      });
    });

    group('🗂️ [QA-SOL-CAT] Validación de Categorías Preestablecidas', () {
      test('QA-SOL-CAT-001: [FALLO] Dada una categoría nula (null), debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-CAT-001: [FALLO] Dada una categoría nula (null), debería retornar FALSE');
        final resultado = SolicitudBlackBox.esCategoriaValida(null);
        expect(resultado, isFalse, reason: 'La selección de categoría es obligatoria.');
      });

      test('QA-SOL-CAT-002: [FALLO] Dada una categoría inexistente o no soportada, debería retornar FALSE', () {
        print('Ejecutando: QA-SOL-CAT-002: [FALLO] Dada una categoría inexistente o no soportada, debería retornar FALSE');
        const cat = 'mecanica';
        final resultado = SolicitudBlackBox.esCategoriaValida(cat);
        expect(resultado, isFalse, reason: '"$cat" no forma parte de las categorías aprobadas.');
      });

      test('QA-SOL-CAT-003: [ÉXITO] Dada una categoría válida ("electricidad"), debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-CAT-003: [ÉXITO] Dada una categoría válida ("electricidad"), debería retornar TRUE');
        const cat = 'electricidad';
        final resultado = SolicitudBlackBox.esCategoriaValida(cat);
        expect(resultado, isTrue);
      });

      test('QA-SOL-CAT-004: [ÉXITO] Dada una categoría válida ("plomeria"), debería retornar TRUE', () {
        print('Ejecutando: QA-SOL-CAT-004: [ÉXITO] Dada una categoría válida ("plomeria"), debería retornar TRUE');
        const cat = 'plomeria';
        final resultado = SolicitudBlackBox.esCategoriaValida(cat);
        expect(resultado, isTrue);
      });
    });

    group('📦 [QA-SOL-VAL] Validación de Solicitud Completa (Flujo de Integridad)', () {
      test('QA-SOL-VAL-001: [ÉXITO] Dada una solicitud con todos sus campos correctos, el formulario debe ser APROBADO (TRUE)', () {
        print('Ejecutando: QA-SOL-VAL-001: [ÉXITO] Dada una solicitud con todos sus campos correctos, el formulario debe ser APROBADO (TRUE)');
        final resultado = SolicitudBlackBox.esSolicitudValida(
          titulo: 'Reparación de ducha',
          descripcion: 'La ducha eléctrica no calienta y salta el disyuntor.',
          categoria: 'electricidad',
        );
        expect(resultado, isTrue);
      });

      test('QA-SOL-VAL-002: [FALLO] Dada una solicitud con título inválido, el formulario debe ser RECHAZADO (FALSE)', () {
        print('Ejecutando: QA-SOL-VAL-002: [FALLO] Dada una solicitud con título inválido, el formulario debe ser RECHAZADO (FALSE)');
        final resultado = SolicitudBlackBox.esSolicitudValida(
          titulo: 'Ok', // inválido
          descripcion: 'La ducha eléctrica no calienta y salta el disyuntor.',
          categoria: 'electricidad',
        );
        expect(resultado, isFalse);
      });

      test('QA-SOL-VAL-003: [FALLO] Dada una solicitud con descripción inválida, el formulario debe ser RECHAZADO (FALSE)', () {
        print('Ejecutando: QA-SOL-VAL-003: [FALLO] Dada una solicitud con descripción inválida, el formulario debe ser RECHAZADO (FALSE)');
        final resultado = SolicitudBlackBox.esSolicitudValida(
          titulo: 'Reparación de ducha',
          descripcion: 'Fallo', // inválido (corto)
          categoria: 'electricidad',
        );
        expect(resultado, isFalse);
      });

      test('QA-SOL-VAL-004: [FALLO] Dada una solicitud con categoría inválida, el formulario debe ser RECHAZADO (FALSE)', () {
        print('Ejecutando: QA-SOL-VAL-004: [FALLO] Dada una solicitud con categoría inválida, el formulario debe ser RECHAZADO (FALSE)');
        final resultado = SolicitudBlackBox.esSolicitudValida(
          titulo: 'Reparación de ducha',
          descripcion: 'La ducha eléctrica no calienta y salta el disyuntor.',
          categoria: 'mecanica', // inválido
        );
        expect(resultado, isFalse);
      });
    });

    group('🛡️ [QA-SOL-DBL] Prevención de Doble Envío (Anti-Spam / Anti-Double-Click)', () {
      test('QA-SOL-DBL-001: [ÉXITO] Dado un único clic del usuario, la acción debe ser PROCESADA (TRUE)', () {
        print('Ejecutando: QA-SOL-DBL-001: [ÉXITO] Dado un único clic del usuario, la acción debe ser PROCESADA (TRUE)');
        final resultado = SolicitudBlackBox.evitaDobleEnvio(1);
        expect(resultado, isTrue);
      });

      test('QA-SOL-DBL-002: [FALLO] Dado un doble clic rápido del usuario, la acción duplicada debe bloquearse', () {
        print('Ejecutando: QA-SOL-DBL-002: [FALLO] Dado un doble clic rápido del usuario, la acción duplicada debe bloquearse');
        final resultado = SolicitudBlackBox.evitaDobleEnvio(2);
        expect(resultado, isFalse, reason: 'Un segundo clic en paralelo debe ser descartado para evitar duplicados en la base de datos.');
      });

      test('QA-SOL-DBL-003: [FALLO] Dado un comportamiento de spam (> 2 clics), las acciones repetitivas deben bloquearse', () {
        print('Ejecutando: QA-SOL-DBL-003: [FALLO] Dado un comportamiento de spam (> 2 clics), las acciones repetitivas deben bloquearse');
        final resultado = SolicitudBlackBox.evitaDobleEnvio(5);
        expect(resultado, isFalse, reason: 'El sistema debe protegerse de clics múltiples repetitivos.');
      });
    });

  });
}
