// ══════════════════════════════════════════════════════════════════
// PLAN DE PRUEBAS DE CAJA NEGRA — CHAT DE SOPORTE Y SERVICIOS
// Código de Módulo: QA-CHAT
// ══════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

/// SIMULADOR DE LÓGICA DE NEGOCIO PARA CHATS (CAJA NEGRA)
class ChatBlackBox {
  static bool mensajeValido(String msg) {
    return msg.trim().isNotEmpty && msg.trim().length <= 500;
  }

  static bool puedeEnviarMensaje(String msg, bool conectado) {
    return conectado && mensajeValido(msg);
  }

  static int contadorMensajes(List<String> mensajes) {
    return mensajes.where((m) => mensajeValido(m)).length;
  }
}

void main() {
  group('💬 [QA-CHAT] MÓDULO DE CHAT Y COMUNICACIÓN', () {

    group('📝 [QA-CHAT-MSG] Validación de Contenido de Mensajes', () {
      test('QA-CHAT-MSG-001: [ÉXITO] Dado un mensaje corto y limpio, debería retornar TRUE', () {
        print('Ejecutando: QA-CHAT-MSG-001: [ÉXITO] Dado un mensaje corto y limpio, debería retornar TRUE');
        const msg = 'Buenas tardes, ¿en qué lugar de El Alto se encuentra?';
        final resultado = ChatBlackBox.mensajeValido(msg);
        expect(resultado, isTrue);
      });

      test('QA-CHAT-MSG-002: [FALLO] Dado un mensaje vacío, debería retornar FALSE', () {
        print('Ejecutando: QA-CHAT-MSG-002: [FALLO] Dado un mensaje vacío, debería retornar FALSE');
        const msg = '';
        final resultado = ChatBlackBox.mensajeValido(msg);
        expect(resultado, isFalse, reason: 'No se permiten enviar mensajes vacíos.');
      });

      test('QA-CHAT-MSG-003: [FALLO] Dado un mensaje compuesto solo de espacios, debería retornar FALSE', () {
        print('Ejecutando: QA-CHAT-MSG-003: [FALLO] Dado un mensaje compuesto solo de espacios, debería retornar FALSE');
        const msg = '      ';
        final resultado = ChatBlackBox.mensajeValido(msg);
        expect(resultado, isFalse, reason: 'Un mensaje con espacios vacíos se considera vacío.');
      });

      test('QA-CHAT-MSG-004: [ÉXITO] Dado un mensaje con la longitud máxima exacta (500 caracteres), debería retornar TRUE', () {
        print('Ejecutando: QA-CHAT-MSG-004: [ÉXITO] Dado un mensaje con la longitud máxima exacta (500 caracteres), debería retornar TRUE');
        final msg = 'a' * 500;
        final resultado = ChatBlackBox.mensajeValido(msg);
        expect(resultado, isTrue, reason: '500 caracteres es el límite máximo permitido.');
      });

      test('QA-CHAT-MSG-005: [FALLO] Dado un mensaje que excede el límite máximo (501 caracteres), debería retornar FALSE', () {
        print('Ejecutando: QA-CHAT-MSG-005: [FALLO] Dado un mensaje que excede el límite máximo (501 caracteres), debería retornar FALSE');
        final msg = 'a' * 501;
        final resultado = ChatBlackBox.mensajeValido(msg);
        expect(resultado, isFalse, reason: 'No se permiten mensajes mayores a 500 caracteres.');
      });
    });

    group('📶 [QA-CHAT-SND] Permisos de Envío según Conectividad', () {
      test('QA-CHAT-SND-001: [ÉXITO] Dado un usuario conectado y mensaje válido, debería permitir el envío (TRUE)', () {
        print('Ejecutando: QA-CHAT-SND-001: [ÉXITO] Dado un usuario conectado y mensaje válido, debería permitir el envío (TRUE)');
        const msg = 'Llego en 10 minutos.';
        const conectado = true;
        final resultado = ChatBlackBox.puedeEnviarMensaje(msg, conectado);
        expect(resultado, isTrue);
      });

      test('QA-CHAT-SND-002: [FALLO] Dado un usuario desconectado, no debería permitir el envío aunque el mensaje sea válido', () {
        print('Ejecutando: QA-CHAT-SND-002: [FALLO] Dado un usuario desconectado, no debería permitir el envío aunque el mensaje sea válido');
        const msg = 'Llego en 10 minutos.';
        const conectado = false;
        final resultado = ChatBlackBox.puedeEnviarMensaje(msg, conectado);
        expect(resultado, isFalse, reason: 'No se puede enviar mensajes sin conexión a internet.');
      });

      test('QA-CHAT-SND-003: [FALLO] Dado un usuario conectado con mensaje inválido, no debería permitir el envío', () {
        print('Ejecutando: QA-CHAT-SND-003: [FALLO] Dado un usuario conectado con mensaje inválido, no debería permitir el envío');
        const msg = '';
        const conectado = true;
        final resultado = ChatBlackBox.puedeEnviarMensaje(msg, conectado);
        expect(resultado, isFalse);
      });
    });

    group('📊 [QA-CHAT-CNT] Filtrado y Conteo de Historial de Mensajes', () {
      test('QA-CHAT-CNT-001: [ÉXITO] Dada una lista mixta de mensajes, debería contar únicamente los válidos', () {
        print('Ejecutando: QA-CHAT-CNT-001: [ÉXITO] Dada una lista mixta de mensajes, debería contar únicamente los válidos');
        final historial = [
          'Hola, buenos días',
          '     ', // inválido
          'Necesito ayuda con mi grifo',
          '', // inválido
          'Entendido, voy en camino.'
        ];
        final totalValidos = ChatBlackBox.contadorMensajes(historial);
        expect(totalValidos, equals(3), reason: 'Solo 3 de los 5 mensajes enviados son lógicamente válidos.');
      });

      test('QA-CHAT-CNT-002: [ÉXITO] Dada una lista sin mensajes válidos, el contador debe retornar 0', () {
        print('Ejecutando: QA-CHAT-CNT-002: [ÉXITO] Dada una lista sin mensajes válidos, el contador debe retornar 0');
        final historial = ['', '   ', '      '];
        final totalValidos = ChatBlackBox.contadorMensajes(historial);
        expect(totalValidos, equals(0));
      });
    });

  });
}
