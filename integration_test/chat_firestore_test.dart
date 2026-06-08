// ══════════════════════════════════════════════════════════════════
// TESTS DE INTEGRACIÓN — Interacciones de Chat y Firestore real
// Archivo: integration_test/chat_firestore_test.dart
//
// ⚠️  Requiere conexión a Firestore real (o emulador local).
//     Estos tests escriben/leen documentos reales en la DB.
// ══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_servicios/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseFirestore firestore;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestore = FirebaseFirestore.instance;
  });

  group('Firestore — colección solicitudes', () {
    testWidgets('Crear, leer y eliminar una solicitud de prueba', (tester) async {
      final docRef = firestore.collection('solicitudes_test').doc('test_doc_1');

      // CREATE
      await docRef.set({
        'cliente_uid': 'test-uid-123',
        'titulo': 'Test desde integration_test',
        'estado': 'pendiente',
        'fecha': FieldValue.serverTimestamp(),
      });

      // READ
      final snap = await docRef.get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['titulo'], equals('Test desde integration_test'));
      expect(snap.data()?['estado'], equals('pendiente'));

      // UPDATE
      await docRef.update({'estado': 'aceptado'});
      final snap2 = await docRef.get();
      expect(snap2.data()?['estado'], equals('aceptado'));

      // DELETE (limpieza)
      await docRef.delete();
      final snap3 = await docRef.get();
      expect(snap3.exists, isFalse);
    });

    testWidgets('Query con where("estado", isEqualTo: "pendiente")', (tester) async {
      // Crear 3 docs de prueba con diferentes estados
      final c1 = firestore.collection('solicitudes_test').doc('q1');
      final c2 = firestore.collection('solicitudes_test').doc('q2');
      final c3 = firestore.collection('solicitudes_test').doc('q3');

      await c1.set({'estado': 'pendiente', 'titulo': 'A'});
      await c2.set({'estado': 'pendiente', 'titulo': 'B'});
      await c3.set({'estado': 'finalizado', 'titulo': 'C'});

      // Query
      final q = await firestore.collection('solicitudes_test')
        .where('estado', isEqualTo: 'pendiente').get();

      expect(q.docs.length, greaterThanOrEqualTo(2));

      // Limpieza
      await c1.delete();
      await c2.delete();
      await c3.delete();
    });

    testWidgets('serverTimestamp() se reemplaza con hora real al escribir', (tester) async {
      final docRef = firestore.collection('solicitudes_test').doc('ts_test');
      await docRef.set({
        'fecha': FieldValue.serverTimestamp(),
      });
      final snap = await docRef.get();
      final fecha = snap.data()?['fecha'];

      expect(fecha, isA<Timestamp>());
      final ahora = DateTime.now();
      final fechaServidor = (fecha as Timestamp).toDate();

      // La fecha del servidor debe estar dentro de los últimos 60 segundos
      expect(ahora.difference(fechaServidor).abs().inSeconds, lessThan(60));

      await docRef.delete();
    });
  });

  group('Firestore — chat_rooms (mensajes ordenados)', () {
    testWidgets('Insertar 3 mensajes y leerlos ordenados por fecha', (tester) async {
      const sala = 'test_chat_room_xyz';
      final ref = firestore.collection('chat_rooms').doc(sala).collection('mensajes');

      // Limpiar previos si quedaron
      final prev = await ref.get();
      for (final d in prev.docs) {
        await d.reference.delete();
      }

      // Insertar 3 mensajes en orden
      await ref.add({'texto': 'Hola', 'sender_id': 'A', 'fecha': FieldValue.serverTimestamp()});
      await Future.delayed(const Duration(milliseconds: 100));
      await ref.add({'texto': 'Cómo estás', 'sender_id': 'B', 'fecha': FieldValue.serverTimestamp()});
      await Future.delayed(const Duration(milliseconds: 100));
      await ref.add({'texto': 'Bien gracias', 'sender_id': 'A', 'fecha': FieldValue.serverTimestamp()});

      // Leer ordenados descendente (el más reciente primero)
      final snap = await ref.orderBy('fecha', descending: true).get();
      expect(snap.docs.length, equals(3));
      expect(snap.docs.first.data()['texto'], equals('Bien gracias'));
      expect(snap.docs.last.data()['texto'], equals('Hola'));

      // Limpieza
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    });

    testWidgets('Detectar mensajes propios con sender_id', (tester) async {
      const sala = 'test_propios_xyz';
      final ref = firestore.collection('chat_rooms').doc(sala).collection('mensajes');

      const miUid = 'mi-uid-test';
      await ref.add({'texto': 'Mio', 'sender_id': miUid});
      await ref.add({'texto': 'Ajeno', 'sender_id': 'otro-uid'});

      final snap = await ref.get();
      final propios = snap.docs.where((d) => d.data()['sender_id'] == miUid).toList();
      final ajenos = snap.docs.where((d) => d.data()['sender_id'] != miUid).toList();

      expect(propios.length, equals(1));
      expect(ajenos.length, equals(1));
      expect(propios.first.data()['texto'], equals('Mio'));

      // Limpieza
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    });

    testWidgets('chat_room_id es consistente con el orden alfabético de UIDs', (tester) async {
      String generarIdSala(String a, String b) {
        final ids = [a, b]..sort();
        return ids.join('_');
      }

      // Cliente y técnico en cualquier orden producen el mismo ID
      final id1 = generarIdSala('uidCliente_xyz', 'uidTecnico_abc');
      final id2 = generarIdSala('uidTecnico_abc', 'uidCliente_xyz');
      expect(id1, equals(id2));

      // Y ambos pueden escribir/leer en la misma sala
      final ref = firestore.collection('chat_rooms').doc(id1).collection('mensajes');
      await ref.add({'texto': 'desde cliente', 'sender_id': 'uidCliente_xyz'});

      final snapDesdeTecnico = await firestore.collection('chat_rooms').doc(id2)
        .collection('mensajes').get();
      expect(snapDesdeTecnico.docs.length, greaterThanOrEqualTo(1));

      // Limpieza
      for (final d in snapDesdeTecnico.docs) {
        await d.reference.delete();
      }
    });
  });

  group('Firestore — transacciones atómicas', () {
    testWidgets('Transacción: solo un técnico puede aceptar la solicitud', (tester) async {
      final docRef = firestore.collection('solicitudes_test').doc('race_condition');
      await docRef.set({'estado': 'pendiente', 'tecnico_uid': null});

      // Simulamos dos técnicos compitiendo
      await firestore.runTransaction((trx) async {
        final snap = await trx.get(docRef);
        if (snap.data()?['estado'] == 'pendiente') {
          trx.update(docRef, {
            'estado': 'aceptado',
            'tecnico_uid': 'tecnico-A-ganador',
          });
        }
      });

      // El segundo técnico llega tarde
      try {
        await firestore.runTransaction((trx) async {
          final snap = await trx.get(docRef);
          if (snap.data()?['estado'] != 'pendiente') {
            throw Exception('Ya fue tomado');
          }
          trx.update(docRef, {'tecnico_uid': 'tecnico-B-perdedor'});
        });
        fail('No debió permitir al segundo técnico aceptar');
      } catch (e) {
        expect(e.toString(), contains('tomado'));
      }

      // Verificar que el ganador es A
      final final_snap = await docRef.get();
      expect(final_snap.data()?['tecnico_uid'], equals('tecnico-A-ganador'));

      await docRef.delete();
    });
  });

  group('Firestore — StreamBuilder en tiempo real', () {
    testWidgets('Cambios en Firestore se reflejan en el snapshot stream', (tester) async {
      final docRef = firestore.collection('solicitudes_test').doc('stream_test');
      await docRef.set({'estado': 'pendiente'});

      final eventos = <String>[];
      final sub = docRef.snapshots().listen((snap) {
        if (snap.exists) eventos.add(snap.data()?['estado']);
      });

      // Esperar primer snapshot
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Actualizar y esperar
      await docRef.update({'estado': 'aceptado'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await docRef.update({'estado': 'finalizado'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(eventos, contains('pendiente'));
      expect(eventos, contains('aceptado'));
      expect(eventos, contains('finalizado'));

      await sub.cancel();
      await docRef.delete();
    });
  });
}
