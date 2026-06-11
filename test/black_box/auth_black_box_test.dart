// ══════════════════════════════════════════════════════════════════
// PLAN DE PRUEBAS DE CAJA NEGRA — AUTENTICACIÓN (QA MANUAL & AUTO)
// Código de Módulo: QA-AUTH
// ══════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

/// SIMULADOR DE LÓGICA DE NEGOCIO PARA AUTENTICACIÓN (CAJA NEGRA)
class AuthBlackBox {
  static bool emailValido(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool passwordValida(String pass) {
    return pass.trim().length >= 6;
  }

  static bool loginValido(String email, String pass) {
    return emailValido(email) && passwordValida(pass);
  }

  static bool esRegistroValido({
    required String nombre,
    required String email,
    required String password,
  }) {
    return nombre.trim().length >= 2 &&
        emailValido(email) &&
        passwordValida(password);
  }
}

void main() {
  group('🛡️ [QA-AUTH] MÓDULO DE AUTENTICACIÓN Y REGISTRO', () {

    group('📧 [QA-AUTH-EML] Validaciones de Correo Electrónico', () {
      test('QA-AUTH-EML-001: [ÉXITO] Dado un correo estándar válido, debería retornar TRUE', () {
        print('Ejecutando: QA-AUTH-EML-001: [ÉXITO] Dado un correo estándar válido, debería retornar TRUE');
        // GIVEN
        const email = 'usuario.pruebas@elalto.gob.bo';
        // WHEN
        final resultado = AuthBlackBox.emailValido(email);
        // THEN
        expect(resultado, isTrue, reason: 'El correo "$email" cumple con el formato estándar.');
      });

      test('QA-AUTH-EML-002: [FALLO] Dado un correo sin arroba "@", debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-EML-002: [FALLO] Dado un correo sin arroba "@", debería retornar FALSE');
        const email = 'usuario_sin_arroba.com';
        final resultado = AuthBlackBox.emailValido(email);
        expect(resultado, isFalse, reason: 'Debe rechazar correos sin "@"');
      });

      test('QA-AUTH-EML-003: [FALLO] Dado un correo vacío, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-EML-003: [FALLO] Dado un correo vacío, debería retornar FALSE');
        const email = '';
        final resultado = AuthBlackBox.emailValido(email);
        expect(resultado, isFalse, reason: 'Un correo vacío es inválido.');
      });

      test('QA-AUTH-EML-004: [FALLO] Dado un correo con múltiples arrobas, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-EML-004: [FALLO] Dado un correo con múltiples arrobas, debería retornar FALSE');
        const email = 'usuario@@dominio.com';
        final resultado = AuthBlackBox.emailValido(email);
        expect(resultado, isFalse, reason: 'Un correo no puede tener más de una arroba.');
      });

      test('QA-AUTH-EML-005: [FALLO] Dado un correo con espacios en blanco, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-EML-005: [FALLO] Dado un correo con espacios en blanco, debería retornar FALSE');
        const email = 'usuario espacio@dominio.com';
        final resultado = AuthBlackBox.emailValido(email);
        expect(resultado, isFalse, reason: 'Los espacios en blanco invalidan el formato.');
      });
    });

    group('🔑 [QA-AUTH-PWD] Validaciones de Contraseña', () {
      test('QA-AUTH-PWD-001: [ÉXITO] Dada una contraseña con longitud límite exacta (6), debería retornar TRUE', () {
        print('Ejecutando: QA-AUTH-PWD-001: [ÉXITO] Dada una contraseña con longitud límite exacta (6), debería retornar TRUE');
        const pass = '123456';
        final resultado = AuthBlackBox.passwordValida(pass);
        expect(resultado, isTrue, reason: 'La longitud mínima es de 6 caracteres.');
      });

      test('QA-AUTH-PWD-002: [ÉXITO] Dada una contraseña larga (> 6), debería retornar TRUE', () {
        print('Ejecutando: QA-AUTH-PWD-002: [ÉXITO] Dada una contraseña larga (> 6), debería retornar TRUE');
        const pass = 'passwordSuperSegura2026';
        final resultado = AuthBlackBox.passwordValida(pass);
        expect(resultado, isTrue, reason: 'Cualquier longitud >= 6 es válida.');
      });

      test('QA-AUTH-PWD-003: [FALLO] Dada una contraseña menor al límite (5), debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-PWD-003: [FALLO] Dada una contraseña menor al límite (5), debería retornar FALSE');
        const pass = '12345';
        final resultado = AuthBlackBox.passwordValida(pass);
        expect(resultado, isFalse, reason: '5 caracteres está por debajo del límite mínimo.');
      });

      test('QA-AUTH-PWD-004: [FALLO] Dada una contraseña vacía o con solo espacios, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-PWD-004: [FALLO] Dada una contraseña vacía o con solo espacios, debería retornar FALSE');
        const pass = '      ';
        final resultado = AuthBlackBox.passwordValida(pass);
        expect(resultado, isFalse, reason: 'Contraseñas vacías o que solo contienen espacios no son seguras.');
      });
    });

    group('🔓 [QA-AUTH-LGN] Validación de Credenciales de Inicio de Sesión', () {
      test('QA-AUTH-LGN-001: [ÉXITO] Dadas credenciales correctas (correo válido y clave >= 6), debería retornar TRUE', () {
        print('Ejecutando: QA-AUTH-LGN-001: [ÉXITO] Dadas credenciales correctas (correo válido y clave >= 6), debería retornar TRUE');
        const email = 'cliente@elalto.bo';
        const pass = 'bolivia123';
        final resultado = AuthBlackBox.loginValido(email, pass);
        expect(resultado, isTrue);
      });

      test('QA-AUTH-LGN-002: [FALLO] Dadas credenciales con clave inválida, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-LGN-002: [FALLO] Dadas credenciales con clave inválida, debería retornar FALSE');
        const email = 'cliente@elalto.bo';
        const pass = '123';
        final resultado = AuthBlackBox.loginValido(email, pass);
        expect(resultado, isFalse);
      });

      test('QA-AUTH-LGN-003: [FALLO] Dadas credenciales con correo inválido, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-LGN-003: [FALLO] Dadas credenciales con correo inválido, debería retornar FALSE');
        const email = 'cliente_sin_arroba';
        const pass = 'bolivia123';
        final resultado = AuthBlackBox.loginValido(email, pass);
        expect(resultado, isFalse);
      });
    });

    group('📝 [QA-AUTH-REG] Validación de Formulario de Registro de Usuario', () {
      test('QA-AUTH-REG-001: [ÉXITO] Dado un formulario completo y válido, debería retornar TRUE', () {
        print('Ejecutando: QA-AUTH-REG-001: [ÉXITO] Dado un formulario completo y válido, debería retornar TRUE');
        final resultado = AuthBlackBox.esRegistroValido(
          nombre: 'Juan Perez',
          email: 'juan@perez.com',
          password: 'contrasenia123',
        );
        expect(resultado, isTrue);
      });

      test('QA-AUTH-REG-002: [FALLO] Dado un nombre vacío, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-REG-002: [FALLO] Dado un nombre vacío, debería retornar FALSE');
        final resultado = AuthBlackBox.esRegistroValido(
          nombre: '',
          email: 'juan@perez.com',
          password: 'contrasenia123',
        );
        expect(resultado, isFalse, reason: 'El nombre es obligatorio.');
      });

      test('QA-AUTH-REG-003: [FALLO] Dado un nombre con solo 1 carácter, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-REG-003: [FALLO] Dado un nombre con solo 1 carácter, debería retornar FALSE');
        final resultado = AuthBlackBox.esRegistroValido(
          nombre: 'A',
          email: 'juan@perez.com',
          password: 'contrasenia123',
        );
        expect(resultado, isFalse, reason: 'El nombre debe tener al menos 2 caracteres.');
      });

      test('QA-AUTH-REG-004: [FALLO] Dado un registro con email inválido, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-REG-004: [FALLO] Dado un registro con email inválido, debería retornar FALSE');
        final resultado = AuthBlackBox.esRegistroValido(
          nombre: 'Juan',
          email: 'juan_perez.com',
          password: 'contrasenia123',
        );
        expect(resultado, isFalse);
      });

      test('QA-AUTH-REG-005: [FALLO] Dado un registro con contraseña corta, debería retornar FALSE', () {
        print('Ejecutando: QA-AUTH-REG-005: [FALLO] Dado un registro con contraseña corta, debería retornar FALSE');
        final resultado = AuthBlackBox.esRegistroValido(
          nombre: 'Juan',
          email: 'juan@perez.com',
          password: '123',
        );
        expect(resultado, isFalse);
      });
    });

  });
}
