// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Estados de Solicitud + ChatRoom
// Archivo: test/estados_y_chat_test.dart
// Ejecutar: flutter test test/estados_y_chat_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Lógica extraída de jobs_screen.dart y home_tecnico_screen.dart ──
class EstadoSolicitud {
  static const String pendiente  = 'pendiente';
  static const String aceptado   = 'aceptado';
  static const String enProceso  = 'en_proceso';
  static const String finalizado = 'finalizado';
  static const String completado = 'completado'; // se usa en mis_trabajos
  static const String cancelado  = 'cancelado';

  static bool esActivo(String estado) =>
    [pendiente, aceptado, enProceso].contains(estado);

  static bool esHistorial(String estado) =>
    [finalizado, completado, cancelado].contains(estado);

  static bool esCancelablePorCliente(String estado) => estado == pendiente;

  static bool esTerminado(String estado) =>
    estado == finalizado || estado == completado;

  static bool puedeCalificar(String estado, int calificacionActual) =>
    esTerminado(estado) && calificacionActual == 0;

  static bool tecnicoEnCamino(String estado) => estado == aceptado;
}

// ── Lógica de ChatRoom extraída de chat_screen.dart ──
class ChatRoomHelper {
  static String generarIdSala(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  static Map<String, dynamic> construirMensaje({
    required String texto,
    required String senderId,
    required String email,
  }) {
    return {
      'texto':     texto.trim(),
      'sender_id': senderId,
      'email':     email,
    };
  }

  static bool esMensajeMio(Map<String, dynamic> data, String miUid) =>
    data['sender_id'] == miUid;
}

void main() {
  // ══════════════════════════════════════════════════════════════════
  // ESTADOS DE SOLICITUD
  // ══════════════════════════════════════════════════════════════════
  group('EstadoSolicitud — clasificación de estados', () {
    test('pendiente es activo',    () => expect(EstadoSolicitud.esActivo('pendiente'), isTrue));
    test('aceptado es activo',     () => expect(EstadoSolicitud.esActivo('aceptado'), isTrue));
    test('en_proceso es activo',   () => expect(EstadoSolicitud.esActivo('en_proceso'), isTrue));
    test('finalizado NO es activo',() => expect(EstadoSolicitud.esActivo('finalizado'), isFalse));
    test('cancelado NO es activo', () => expect(EstadoSolicitud.esActivo('cancelado'), isFalse));
    test('completado NO es activo',() => expect(EstadoSolicitud.esActivo('completado'), isFalse));

    test('finalizado es historial',() => expect(EstadoSolicitud.esHistorial('finalizado'), isTrue));
    test('cancelado es historial', () => expect(EstadoSolicitud.esHistorial('cancelado'), isTrue));
    test('completado es historial',() => expect(EstadoSolicitud.esHistorial('completado'), isTrue));
    test('pendiente NO es historial', () => expect(EstadoSolicitud.esHistorial('pendiente'), isFalse));
    test('aceptado NO es historial',  () => expect(EstadoSolicitud.esHistorial('aceptado'), isFalse));
  });

  group('EstadoSolicitud — reglas de cancelación', () {
    test('cliente puede cancelar pendiente',     () => expect(EstadoSolicitud.esCancelablePorCliente('pendiente'), isTrue));
    test('cliente NO puede cancelar aceptado',   () => expect(EstadoSolicitud.esCancelablePorCliente('aceptado'), isFalse));
    test('cliente NO puede cancelar finalizado', () => expect(EstadoSolicitud.esCancelablePorCliente('finalizado'), isFalse));
    test('cliente NO puede cancelar cancelado',  () => expect(EstadoSolicitud.esCancelablePorCliente('cancelado'), isFalse));
  });

  group('EstadoSolicitud — botón calificar', () {
    test('finalizado sin calificación → puede calificar', () {
      expect(EstadoSolicitud.puedeCalificar('finalizado', 0), isTrue);
    });
    test('completado sin calificación → puede calificar', () {
      expect(EstadoSolicitud.puedeCalificar('completado', 0), isTrue);
    });
    test('finalizado YA calificado → NO puede volver a calificar', () {
      expect(EstadoSolicitud.puedeCalificar('finalizado', 5), isFalse);
    });
    test('pendiente NO puede calificar aunque no tenga calificación', () {
      expect(EstadoSolicitud.puedeCalificar('pendiente', 0), isFalse);
    });
    test('aceptado NO puede calificar', () {
      expect(EstadoSolicitud.puedeCalificar('aceptado', 0), isFalse);
    });
  });

  group('EstadoSolicitud — semáforos visuales', () {
    test('aceptado → técnico en camino',        () => expect(EstadoSolicitud.tecnicoEnCamino('aceptado'), isTrue));
    test('pendiente → técnico NO en camino',    () => expect(EstadoSolicitud.tecnicoEnCamino('pendiente'), isFalse));
    test('en_proceso → técnico NO en camino',   () => expect(EstadoSolicitud.tecnicoEnCamino('en_proceso'), isFalse));
  });

  group('EstadoSolicitud — equivalencia finalizado/completado', () {
    test('finalizado es terminado', () => expect(EstadoSolicitud.esTerminado('finalizado'), isTrue));
    test('completado es terminado', () => expect(EstadoSolicitud.esTerminado('completado'), isTrue));
    test('cancelado NO es terminado (es interrupción)', () => expect(EstadoSolicitud.esTerminado('cancelado'), isFalse));
  });

  // ══════════════════════════════════════════════════════════════════
  // CHAT ROOM ID
  // ══════════════════════════════════════════════════════════════════
  group('ChatRoomHelper.generarIdSala() — ID determinístico', () {
    test('mismo par de UIDs en cualquier orden produce el mismo ID', () {
      final a = ChatRoomHelper.generarIdSala('uidCliente', 'uidTecnico');
      final b = ChatRoomHelper.generarIdSala('uidTecnico', 'uidCliente');
      expect(a, equals(b));
    });

    test('el ID contiene ambos UIDs', () {
      final id = ChatRoomHelper.generarIdSala('abc', 'xyz');
      expect(id, contains('abc'));
      expect(id, contains('xyz'));
    });

    test('usa _ como separador', () {
      final id = ChatRoomHelper.generarIdSala('u1', 'u2');
      expect(id, contains('_'));
    });

    test('pares distintos dan IDs distintos', () {
      final id1 = ChatRoomHelper.generarIdSala('u1', 'u2');
      final id2 = ChatRoomHelper.generarIdSala('u1', 'u3');
      expect(id1, isNot(equals(id2)));
    });

    test('ID es determinístico (mismo input → mismo output siempre)', () {
      const u1 = 'firebase_uid_cliente_XYZ';
      const u2 = 'firebase_uid_tecnico_ABC';
      expect(
        ChatRoomHelper.generarIdSala(u1, u2),
        equals(ChatRoomHelper.generarIdSala(u1, u2)),
      );
    });

    test('orden alfabético: ID empieza con el UID alfabéticamente menor', () {
      final id = ChatRoomHelper.generarIdSala('zzz', 'aaa');
      expect(id, startsWith('aaa'));
      expect(id, endsWith('zzz'));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // MENSAJES DE CHAT
  // ══════════════════════════════════════════════════════════════════
  group('ChatRoomHelper.construirMensaje()', () {
    test('preserva texto, sender_id y email', () {
      final msg = ChatRoomHelper.construirMensaje(
        texto: 'Hola técnico',
        senderId: 'uid-cliente-123',
        email: 'cliente@gmail.com',
      );
      expect(msg['texto'],     equals('Hola técnico'));
      expect(msg['sender_id'], equals('uid-cliente-123'));
      expect(msg['email'],     equals('cliente@gmail.com'));
    });

    test('recorta espacios del texto', () {
      final msg = ChatRoomHelper.construirMensaje(
        texto: '   Hola   ',
        senderId: 'uid',
        email: 'a@b.com',
      );
      expect(msg['texto'], equals('Hola'));
    });
  });

  group('ChatRoomHelper.esMensajeMio()', () {
    test('mensaje propio retorna true', () {
      expect(ChatRoomHelper.esMensajeMio({'sender_id': 'mi-uid'}, 'mi-uid'), isTrue);
    });
    test('mensaje ajeno retorna false', () {
      expect(ChatRoomHelper.esMensajeMio({'sender_id': 'otro-uid'}, 'mi-uid'), isFalse);
    });
  });
}
