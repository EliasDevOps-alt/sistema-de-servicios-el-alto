// ══════════════════════════════════════════════════════════════════
// PRUEBAS UNITARIAS — Cálculos financieros y de reputación
// Archivo: test/calculos_test.dart
// Ejecutar: flutter test test/calculos_test.dart
// ══════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';

// ── Lógica extraída de home_tecnico_screen.dart ──
class CalculadorPrecio {
  static bool precioValido(double precio) => precio > 0;

  static double parsearPrecioTexto(String texto) {
    if (texto.isEmpty) return 0.0;
    final limpio = texto.replaceAll(',', '.').trim();
    return double.tryParse(limpio) ?? 0.0;
  }

  static double calcularGananciasTotales(List<double> precios) =>
    precios.fold(0.0, (acum, p) => acum + p);

  static double calcularPromedioCalificacion(List<int> calificaciones) {
    if (calificaciones.isEmpty) return 0.0;
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }

  static String formatearPrecioBolivianos(double precio) =>
    'Bs. ${precio.toStringAsFixed(2)}';

  static double calcularComisionApp(double precio, {double porcentaje = 0.10}) =>
    precio * porcentaje;

  static double calcularGananciaNetaTecnico(double precio, {double comision = 0.10}) =>
    precio * (1 - comision);
}

// ── Lógica de cancelaciones extraída de home_tecnico_screen.dart ──
class SistemaCancelaciones {
  static const int limitePermitido = 3;
  static const int ventanaDias = 7;

  static bool estaBloqueable(int cancelacionesUltimos7Dias) =>
    cancelacionesUltimos7Dias >= limitePermitido;

  static int vidasRestantes(int cancelaciones) =>
    (limitePermitido - cancelaciones).clamp(0, limitePermitido);

  static bool puedeReconectarse(int cancelaciones) =>
    cancelaciones < limitePermitido;

  static bool esCancelacionEnVentana(DateTime fechaCancel, DateTime ahora) =>
    ahora.difference(fechaCancel).inDays < ventanaDias;
}

void main() {
  // ══════════════════════════════════════════════════════════════════
  // VALIDACIÓN DE PRECIO
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio.precioValido()', () {
    test('150.0 es válido',  () => expect(CalculadorPrecio.precioValido(150.0), isTrue));
    test('0.0 NO es válido', () => expect(CalculadorPrecio.precioValido(0.0), isFalse));
    test('-50.0 NO es válido (no se acepta deuda)', () => expect(CalculadorPrecio.precioValido(-50.0), isFalse));
    test('0.01 es válido (mínimo posible)', () => expect(CalculadorPrecio.precioValido(0.01), isTrue));
    test('5000.0 es válido (precio alto)', () => expect(CalculadorPrecio.precioValido(5000.0), isTrue));
  });

  // ══════════════════════════════════════════════════════════════════
  // PARSEO DESDE TECLADO
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio.parsearPrecioTexto()', () {
    test('"150.00" → 150.0',  () => expect(CalculadorPrecio.parsearPrecioTexto('150.00'), equals(150.0)));
    test('"150,00" → 150.0 (coma latina)', () => expect(CalculadorPrecio.parsearPrecioTexto('150,00'), equals(150.0)));
    test('"75" → 75.0',       () => expect(CalculadorPrecio.parsearPrecioTexto('75'), equals(75.0)));
    test('"abc" → 0.0 (texto inválido no explota)', () => expect(CalculadorPrecio.parsearPrecioTexto('abc'), equals(0.0)));
    test('"" → 0.0 (vacío no explota)', () => expect(CalculadorPrecio.parsearPrecioTexto(''), equals(0.0)));
    test('"  100  " → 100.0 (recorta espacios)', () => expect(CalculadorPrecio.parsearPrecioTexto('  100  '), equals(100.0)));
    test('"1500,50" → 1500.5', () => expect(CalculadorPrecio.parsearPrecioTexto('1500,50'), closeTo(1500.5, 0.001)));
  });

  // ══════════════════════════════════════════════════════════════════
  // GANANCIAS TOTALES
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio.calcularGananciasTotales()', () {
    test('[150, 200, 75] suma a 425.0', () {
      expect(CalculadorPrecio.calcularGananciasTotales([150.0, 200.0, 75.0]), equals(425.0));
    });
    test('lista vacía retorna 0.0',  () {
      expect(CalculadorPrecio.calcularGananciasTotales([]), equals(0.0));
    });
    test('decimales suman correctamente', () {
      expect(CalculadorPrecio.calcularGananciasTotales([99.50, 100.50]), closeTo(200.0, 0.001));
    });
    test('un solo trabajo retorna su precio', () {
      expect(CalculadorPrecio.calcularGananciasTotales([350.0]), equals(350.0));
    });
    test('mil trabajos pequeños', () {
      final precios = List.filled(1000, 10.0);
      expect(CalculadorPrecio.calcularGananciasTotales(precios), equals(10000.0));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // PROMEDIO DE CALIFICACIÓN
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio.calcularPromedioCalificacion()', () {
    test('[5,5,5] → 5.0',          () => expect(CalculadorPrecio.calcularPromedioCalificacion([5, 5, 5]), equals(5.0)));
    test('[4,5,3] → 4.0',          () => expect(CalculadorPrecio.calcularPromedioCalificacion([4, 5, 3]), closeTo(4.0, 0.001)));
    test('lista vacía → 0.0 (técnico nuevo)', () => expect(CalculadorPrecio.calcularPromedioCalificacion([]), equals(0.0)));
    test('[1,2,3,4,5] → 3.0',      () => expect(CalculadorPrecio.calcularPromedioCalificacion([1, 2, 3, 4, 5]), equals(3.0)));
    test('[5] → 5.0 (única calificación)', () => expect(CalculadorPrecio.calcularPromedioCalificacion([5]), equals(5.0)));
    test('[1,1,1] → 1.0 (técnico malo)',  () => expect(CalculadorPrecio.calcularPromedioCalificacion([1, 1, 1]), equals(1.0)));
  });

  // ══════════════════════════════════════════════════════════════════
  // FORMATO DE PRECIO
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio.formatearPrecioBolivianos()', () {
    test('150.0 → "Bs. 150.00"', () {
      expect(CalculadorPrecio.formatearPrecioBolivianos(150.0), equals('Bs. 150.00'));
    });
    test('0.5 → "Bs. 0.50"', () {
      expect(CalculadorPrecio.formatearPrecioBolivianos(0.5), equals('Bs. 0.50'));
    });
    test('1500.123 → "Bs. 1500.12" (redondea a 2 decimales)', () {
      expect(CalculadorPrecio.formatearPrecioBolivianos(1500.123), equals('Bs. 1500.12'));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // COMISIÓN DE LA APP
  // ══════════════════════════════════════════════════════════════════
  group('CalculadorPrecio — comisiones y ganancia neta', () {
    test('comisión 10% sobre 100 = 10', () {
      expect(CalculadorPrecio.calcularComisionApp(100.0), equals(10.0));
    });
    test('ganancia neta del técnico tras 10% comisión sobre 100 = 90', () {
      expect(CalculadorPrecio.calcularGananciaNetaTecnico(100.0), closeTo(90.0, 0.001));
    });
    test('comisión sobre 0 es 0', () {
      expect(CalculadorPrecio.calcularComisionApp(0.0), equals(0.0));
    });
    test('comisión personalizada al 15%', () {
      expect(CalculadorPrecio.calcularComisionApp(200.0, porcentaje: 0.15), equals(30.0));
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // SISTEMA DE CANCELACIONES (suspensión técnico)
  // ══════════════════════════════════════════════════════════════════
  group('SistemaCancelaciones — bloqueo automático', () {
    test('0 cancelaciones → NO bloquea',           () => expect(SistemaCancelaciones.estaBloqueable(0), isFalse));
    test('1 cancelación → NO bloquea',             () => expect(SistemaCancelaciones.estaBloqueable(1), isFalse));
    test('2 cancelaciones → NO bloquea',           () => expect(SistemaCancelaciones.estaBloqueable(2), isFalse));
    test('3 cancelaciones → SÍ bloquea (límite)',  () => expect(SistemaCancelaciones.estaBloqueable(3), isTrue));
    test('4 cancelaciones → SÍ bloquea (supera)',  () => expect(SistemaCancelaciones.estaBloqueable(4), isTrue));
    test('10 cancelaciones → SÍ bloquea',          () => expect(SistemaCancelaciones.estaBloqueable(10), isTrue));
  });

  group('SistemaCancelaciones — vidas restantes', () {
    test('con 0 cancel → 3 vidas',  () => expect(SistemaCancelaciones.vidasRestantes(0), equals(3)));
    test('con 1 cancel → 2 vidas',  () => expect(SistemaCancelaciones.vidasRestantes(1), equals(2)));
    test('con 2 cancel → 1 vida',   () => expect(SistemaCancelaciones.vidasRestantes(2), equals(1)));
    test('con 3 cancel → 0 vidas',  () => expect(SistemaCancelaciones.vidasRestantes(3), equals(0)));
    test('con 5 cancel → 0 (no negativos)', () => expect(SistemaCancelaciones.vidasRestantes(5), equals(0)));
  });

  group('SistemaCancelaciones — reconexión', () {
    test('puede reconectarse con 0 cancelaciones',  () => expect(SistemaCancelaciones.puedeReconectarse(0), isTrue));
    test('puede reconectarse con 2 cancelaciones',  () => expect(SistemaCancelaciones.puedeReconectarse(2), isTrue));
    test('NO puede reconectarse con 3 cancelaciones', () => expect(SistemaCancelaciones.puedeReconectarse(3), isFalse));
    test('NO puede reconectarse con 100 cancelaciones', () => expect(SistemaCancelaciones.puedeReconectarse(100), isFalse));
  });

  group('SistemaCancelaciones — ventana de 7 días', () {
    final ahora = DateTime.now();
    test('hace 1 día está EN ventana',     () => expect(SistemaCancelaciones.esCancelacionEnVentana(ahora.subtract(const Duration(days: 1)), ahora), isTrue));
    test('hace 6 días está EN ventana',    () => expect(SistemaCancelaciones.esCancelacionEnVentana(ahora.subtract(const Duration(days: 6)), ahora), isTrue));
    test('hace 7 días YA NO está en ventana', () => expect(SistemaCancelaciones.esCancelacionEnVentana(ahora.subtract(const Duration(days: 7)), ahora), isFalse));
    test('hace 30 días FUERA de ventana',  () => expect(SistemaCancelaciones.esCancelacionEnVentana(ahora.subtract(const Duration(days: 30)), ahora), isFalse));
    test('ahora mismo (0 días) está en ventana', () => expect(SistemaCancelaciones.esCancelacionEnVentana(ahora, ahora), isTrue));
  });
}
