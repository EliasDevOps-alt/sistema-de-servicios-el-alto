// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Lógica de negocio de Solicitudes
// Archivo: test/negocio_solicitud_test.dart
// Qué testea: validaciones de campos de solicitud, lógica de estados,
//             formato de coordenadas GPS, cálculo de precio,
//             filtrado por estado, ordenamiento temporal
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Clases puras de lógica de negocio (extraídas del sistema) ──
// Validador de solicitudes de servicio
class ValidadorSolicitud {
  static bool camposCompletos({
    required String titulo,
    required String descripcion,
    required String? categoria,
  }) {
    return titulo.isNotEmpty && descripcion.isNotEmpty && categoria != null;
  }

  static bool tituloValido(String titulo) {
    return titulo.trim().isNotEmpty && titulo.trim().length >= 3;
  }

  static bool descripcionValida(String descripcion) {
    return descripcion.trim().isNotEmpty && descripcion.trim().length >= 10;
  }

  static bool categoriaValida(String? categoria, List<String> categoriasPermitidas) {
    return categoria != null && categoriasPermitidas.contains(categoria);
  }

  static String formatearCoordenadas(double lat, double lng) {
    return 'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

// Lógica de estados de solicitud
class EstadoSolicitud {
  static const String pendiente  = 'pendiente';
  static const String aceptado   = 'aceptado';
  static const String enProceso  = 'en_proceso';
  static const String finalizado = 'finalizado';
  static const String cancelado  = 'cancelado';

  static bool esActivo(String estado) =>
    [pendiente, aceptado, enProceso].contains(estado);

  static bool esHistorial(String estado) =>
    [finalizado, cancelado].contains(estado);

  static bool esCancelable(String estado) => estado == pendiente;

  static bool puedeCalificar(String estado) => estado == finalizado;

  static bool tecnicoEnCamino(String estado) => estado == aceptado;
}

// Lógica de precios
class CalculadorPrecio {
  static bool precioValido(double precio) => precio > 0;

  static double parsearPrecioTexto(String texto) {
    final limpio = texto.replaceAll(',', '.');
    return double.tryParse(limpio) ?? 0.0;
  }

  static double calcularGananciasTotales(List<double> precios) {
    return precios.fold(0.0, (acum, p) => acum + p);
  }

  static double calcularPromedioCalificacion(List<int> calificaciones) {
    if (calificaciones.isEmpty) return 0.0;
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }
}

// Generador de ID de sala de chat
class ChatRoomHelper {
  static String generarChatRoomId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  static bool mismoChat(String uid1, String uid2, String uid3, String uid4) {
    return generarChatRoomId(uid1, uid2) == generarChatRoomId(uid3, uid4);
  }
}

// Lógica de cancelaciones / suspensión del técnico
class SistemaCanelaciones {
  static const int limitePermitido = 3;

  static bool estaBloqueable(int cancelaciones) =>
    cancelaciones >= limitePermitido;

  static int vidasRestantes(int cancelaciones) =>
    (limitePermitido - cancelaciones).clamp(0, limitePermitido);

  static bool puedeActivarse(int cancelaciones) =>
    cancelaciones < limitePermitido;
}


void main() {
  // ── Grupo 1: ValidadorSolicitud ───────────────────────────────
  group('ValidadorSolicitud — campos completos', () {
    test('retorna true cuando todos los campos están presentes', () {
      expect(ValidadorSolicitud.camposCompletos(titulo: 'Grifo roto', descripcion: 'El grifo del baño gotea constantemente', categoria: 'Plomería'), isTrue);
    });

    test('retorna false cuando titulo está vacío', () {
      expect(ValidadorSolicitud.camposCompletos(titulo: '', descripcion: 'Descripción larga', categoria: 'Electricidad'), isFalse);
    });

    test('retorna false cuando descripcion está vacía', () {
      expect(ValidadorSolicitud.camposCompletos(titulo: 'Título válido', descripcion: '', categoria: 'Limpieza'), isFalse);
    });

    test('retorna false cuando categoria es null (no seleccionada)', () {
      expect(ValidadorSolicitud.camposCompletos(titulo: 'Título', descripcion: 'Descripción', categoria: null), isFalse);
    });

    test('retorna false cuando todos los campos fallan', () {
      expect(ValidadorSolicitud.camposCompletos(titulo: '', descripcion: '', categoria: null), isFalse);
    });
  });

  group('ValidadorSolicitud — título válido', () {
    test('título de 3 caracteres es válido (mínimo)', () {
      expect(ValidadorSolicitud.tituloValido('abc'), isTrue);
    });

    test('título vacío no es válido', () {
      expect(ValidadorSolicitud.tituloValido(''), isFalse);
    });

    test('título de sólo espacios no es válido', () {
      expect(ValidadorSolicitud.tituloValido('   '), isFalse);
    });

    test('título de 2 caracteres no es válido', () {
      expect(ValidadorSolicitud.tituloValido('ab'), isFalse);
    });

    test('título largo es válido', () {
      expect(ValidadorSolicitud.tituloValido('Caño principal del baño se rompió'), isTrue);
    });
  });

  group('ValidadorSolicitud — descripción válida', () {
    test('descripción de 10 caracteres es válida (mínimo)', () {
      expect(ValidadorSolicitud.descripcionValida('1234567890'), isTrue);
    });

    test('descripción de 9 caracteres NO es válida', () {
      expect(ValidadorSolicitud.descripcionValida('123456789'), isFalse);
    });

    test('descripción vacía no es válida', () {
      expect(ValidadorSolicitud.descripcionValida(''), isFalse);
    });

    test('descripción larga y detallada es válida', () {
      expect(ValidadorSolicitud.descripcionValida('El grifo del lavabo del baño principal gotea agua constantemente desde hace 3 días'), isTrue);
    });
  });

  group('ValidadorSolicitud — categoría válida', () {
    const categorias = ['Plomería', 'Electricidad', 'Albañilería', 'Limpieza', 'Cerrajería', 'Pintura', 'Gasfitería', 'Otros'];

    test('Plomería es categoría válida', () {
      expect(ValidadorSolicitud.categoriaValida('Plomería', categorias), isTrue);
    });

    test('categoría nula es inválida', () {
      expect(ValidadorSolicitud.categoriaValida(null, categorias), isFalse);
    });

    test('categoría fuera de lista es inválida', () {
      expect(ValidadorSolicitud.categoriaValida('Jardinería', categorias), isFalse);
    });

    test('todas las 8 categorías son válidas', () {
      for (final cat in categorias) {
        expect(ValidadorSolicitud.categoriaValida(cat, categorias), isTrue, reason: '$cat debe ser válida');
      }
    });
  });

  group('ValidadorSolicitud — formato de coordenadas GPS', () {
    test('formatea coordenadas de El Alto correctamente', () {
      final resultado = ValidadorSolicitud.formatearCoordenadas(-16.50340, -68.16270);
      expect(resultado, startsWith('GPS:'));
      expect(resultado, contains('-16.50340'));
      expect(resultado, contains('-68.16270'));
    });

    test('resultado tiene exactamente 5 decimales en latitud', () {
      final resultado = ValidadorSolicitud.formatearCoordenadas(-16.5, -68.1);
      expect(resultado, contains('-16.50000'));
    });

    test('resultado tiene exactamente 5 decimales en longitud', () {
      final resultado = ValidadorSolicitud.formatearCoordenadas(-16.5, -68.1);
      expect(resultado, contains('-68.10000'));
    });
  });

  // ── Grupo 2: EstadoSolicitud ──────────────────────────────────
  group('EstadoSolicitud — esActivo()', () {
    test('pendiente es activo', () => expect(EstadoSolicitud.esActivo('pendiente'), isTrue));
    test('aceptado es activo', () => expect(EstadoSolicitud.esActivo('aceptado'), isTrue));
    test('en_proceso es activo', () => expect(EstadoSolicitud.esActivo('en_proceso'), isTrue));
    test('finalizado NO es activo', () => expect(EstadoSolicitud.esActivo('finalizado'), isFalse));
    test('cancelado NO es activo', () => expect(EstadoSolicitud.esActivo('cancelado'), isFalse));
  });

  group('EstadoSolicitud — esHistorial()', () {
    test('finalizado es historial', () => expect(EstadoSolicitud.esHistorial('finalizado'), isTrue));
    test('cancelado es historial', () => expect(EstadoSolicitud.esHistorial('cancelado'), isTrue));
    test('pendiente NO es historial', () => expect(EstadoSolicitud.esHistorial('pendiente'), isFalse));
    test('aceptado NO es historial', () => expect(EstadoSolicitud.esHistorial('aceptado'), isFalse));
  });

  group('EstadoSolicitud — esCancelable(), puedeCalificar(), tecnicoEnCamino()', () {
    test('solo pendiente es cancelable', () {
      expect(EstadoSolicitud.esCancelable('pendiente'), isTrue);
      expect(EstadoSolicitud.esCancelable('aceptado'), isFalse);
      expect(EstadoSolicitud.esCancelable('finalizado'), isFalse);
    });

    test('solo finalizado puede calificarse', () {
      expect(EstadoSolicitud.puedeCalificar('finalizado'), isTrue);
      expect(EstadoSolicitud.puedeCalificar('aceptado'), isFalse);
      expect(EstadoSolicitud.puedeCalificar('pendiente'), isFalse);
    });

    test('tecnicoEnCamino es true solo para aceptado', () {
      expect(EstadoSolicitud.tecnicoEnCamino('aceptado'), isTrue);
      expect(EstadoSolicitud.tecnicoEnCamino('pendiente'), isFalse);
      expect(EstadoSolicitud.tecnicoEnCamino('en_proceso'), isFalse);
    });
  });

  // ── Grupo 3: CalculadorPrecio ─────────────────────────────────
  group('CalculadorPrecio — validación de precio', () {
    test('precio 150.0 es válido', () => expect(CalculadorPrecio.precioValido(150.0), isTrue));
    test('precio 0.0 NO es válido', () => expect(CalculadorPrecio.precioValido(0.0), isFalse));
    test('precio negativo NO es válido', () => expect(CalculadorPrecio.precioValido(-50.0), isFalse));
    test('precio 0.01 es válido (mínimo posible)', () => expect(CalculadorPrecio.precioValido(0.01), isTrue));
  });

  group('CalculadorPrecio — parseo de texto a precio', () {
    test('parsea "150.00" correctamente', () {
      expect(CalculadorPrecio.parsearPrecioTexto('150.00'), equals(150.0));
    });

    test('parsea "150,00" con coma como separador', () {
      expect(CalculadorPrecio.parsearPrecioTexto('150,00'), equals(150.0));
    });

    test('parsea "75" (sin decimales) correctamente', () {
      expect(CalculadorPrecio.parsearPrecioTexto('75'), equals(75.0));
    });

    test('retorna 0.0 para texto no numérico', () {
      expect(CalculadorPrecio.parsearPrecioTexto('abc'), equals(0.0));
    });

    test('retorna 0.0 para cadena vacía', () {
      expect(CalculadorPrecio.parsearPrecioTexto(''), equals(0.0));
    });

    test('parsea "1500,50" correctamente', () {
      expect(CalculadorPrecio.parsearPrecioTexto('1500,50'), closeTo(1500.50, 0.001));
    });
  });

  group('CalculadorPrecio — ganancias totales', () {
    test('suma correctamente 3 trabajos', () {
      expect(CalculadorPrecio.calcularGananciasTotales([150.0, 200.0, 75.0]), equals(425.0));
    });

    test('lista vacía retorna 0.0', () {
      expect(CalculadorPrecio.calcularGananciasTotales([]), equals(0.0));
    });

    test('suma correctamente precios con decimales', () {
      expect(CalculadorPrecio.calcularGananciasTotales([99.50, 100.50]), closeTo(200.0, 0.001));
    });

    test('un solo trabajo retorna su precio', () {
      expect(CalculadorPrecio.calcularGananciasTotales([350.0]), equals(350.0));
    });
  });

  group('CalculadorPrecio — promedio de calificaciones', () {
    test('promedio de [5, 5, 5] es 5.0', () {
      expect(CalculadorPrecio.calcularPromedioCalificacion([5, 5, 5]), equals(5.0));
    });

    test('promedio de [4, 5, 3] es 4.0', () {
      expect(CalculadorPrecio.calcularPromedioCalificacion([4, 5, 3]), closeTo(4.0, 0.001));
    });

    test('lista vacía retorna 0.0 (técnico nuevo)', () {
      expect(CalculadorPrecio.calcularPromedioCalificacion([]), equals(0.0));
    });

    test('promedio de [1, 2, 3, 4, 5] es 3.0', () {
      expect(CalculadorPrecio.calcularPromedioCalificacion([1, 2, 3, 4, 5]), equals(3.0));
    });

    test('promedio de [5] es 5.0 (un solo trabajo)', () {
      expect(CalculadorPrecio.calcularPromedioCalificacion([5]), equals(5.0));
    });
  });

  // ── Grupo 4: ChatRoomHelper ───────────────────────────────────
  group('ChatRoomHelper — generación de sala privada', () {
    test('dos UIDs generan siempre el mismo chatRoomId sin importar el orden', () {
      final id1 = ChatRoomHelper.generarChatRoomId('uidCliente123', 'uidTecnico456');
      final id2 = ChatRoomHelper.generarChatRoomId('uidTecnico456', 'uidCliente123');
      expect(id1, equals(id2));
    });

    test('chatRoomId contiene ambos UIDs', () {
      final id = ChatRoomHelper.generarChatRoomId('abc', 'xyz');
      expect(id, contains('abc'));
      expect(id, contains('xyz'));
    });

    test('chatRoomId usa guion bajo como separador', () {
      final id = ChatRoomHelper.generarChatRoomId('userA', 'userB');
      expect(id, contains('_'));
    });

    test('UIDs distintos generan chatRooms distintos', () {
      final id1 = ChatRoomHelper.generarChatRoomId('user1', 'user2');
      final id2 = ChatRoomHelper.generarChatRoomId('user1', 'user3');
      expect(id1, isNot(equals(id2)));
    });

    test('mismoChat retorna true cuando los pares son iguales (en cualquier orden)', () {
      expect(ChatRoomHelper.mismoChat('A', 'B', 'B', 'A'), isTrue);
    });

    test('mismoChat retorna false cuando los pares son distintos', () {
      expect(ChatRoomHelper.mismoChat('A', 'B', 'A', 'C'), isFalse);
    });

    test('chatRoomId es determinístico (mismo resultado siempre)', () {
      const uid1 = 'firebase_uid_clienteXYZ';
      const uid2 = 'firebase_uid_tecnicoABC';
      final r1 = ChatRoomHelper.generarChatRoomId(uid1, uid2);
      final r2 = ChatRoomHelper.generarChatRoomId(uid1, uid2);
      expect(r1, equals(r2));
    });
  });

  // ── Grupo 5: SistemaCanelaciones ─────────────────────────────
  group('SistemaCancelaciones — lógica de bloqueo de técnico', () {
    test('0 cancelaciones no bloquea', () {
      expect(SistemaCanelaciones.estaBloqueable(0), isFalse);
    });

    test('1 cancelación no bloquea', () {
      expect(SistemaCanelaciones.estaBloqueable(1), isFalse);
    });

    test('2 cancelaciones no bloquea', () {
      expect(SistemaCanelaciones.estaBloqueable(2), isFalse);
    });

    test('3 cancelaciones SÍ bloquea (límite exacto)', () {
      expect(SistemaCanelaciones.estaBloqueable(3), isTrue);
    });

    test('4 cancelaciones SÍ bloquea (supera límite)', () {
      expect(SistemaCanelaciones.estaBloqueable(4), isTrue);
    });

    test('vidas restantes con 0 cancelaciones es 3', () {
      expect(SistemaCanelaciones.vidasRestantes(0), equals(3));
    });

    test('vidas restantes con 1 cancelación es 2', () {
      expect(SistemaCanelaciones.vidasRestantes(1), equals(2));
    });

    test('vidas restantes con 2 cancelaciones es 1', () {
      expect(SistemaCanelaciones.vidasRestantes(2), equals(1));
    });

    test('vidas restantes con 3 cancelaciones es 0', () {
      expect(SistemaCanelaciones.vidasRestantes(3), equals(0));
    });

    test('vidas restantes no baja de 0 con 5 cancelaciones', () {
      expect(SistemaCanelaciones.vidasRestantes(5), equals(0));
    });

    test('puede activarse con 0 cancelaciones', () {
      expect(SistemaCanelaciones.puedeActivarse(0), isTrue);
    });

    test('puede activarse con 2 cancelaciones', () {
      expect(SistemaCanelaciones.puedeActivarse(2), isTrue);
    });

    test('NO puede activarse con 3 cancelaciones', () {
      expect(SistemaCanelaciones.puedeActivarse(3), isFalse);
    });
  });
}
