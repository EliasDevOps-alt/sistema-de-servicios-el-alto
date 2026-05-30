import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. NUEVOS IMPORTS: Traemos el main y la pantalla de destino
import 'main.dart'; 
import 'detalle_servicio_screen.dart'; 

// REGLA DE GOLDEN DE FIREBASE: El manejador en segundo plano debe ser una función global (fuera de la clase)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("💤 Notificación recibida en Segundo Plano/App Cerrada: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> inicializarNotificaciones() async {
    // 1. Pedimos permiso al usuario
    NotificationSettings settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Permiso de notificaciones CONCEDIDO");

      // 2. Conseguimos el Token único
      String? token = await _firebaseMessaging.getToken();
      print("📱 Mi Token es: $token");
      _guardarToken(token);

      _firebaseMessaging.onTokenRefresh.listen(_guardarToken);

      // ====================================================================
      // 🧠 CONFIGURACIÓN DE LOS "SENSORES" PARA AUTOMATIZACIÓN
      // ====================================================================

      // SENSOR 1: Activa el manejador de segundo plano/app cerrada
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // SENSOR 2: Recibir mensajes cuando la app está ABIERTA en pantalla
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('💌 App Abierta - Título: ${message.notification?.title}');
        _procesarNotificacionData(message);
      });

      // SENSOR 3: El usuario le da CLIC a la notificación con la app en SEGUNDO PLANO
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👆 Clic con App en Segundo Plano');
        _procesarNotificacionData(message);
      });

      // SENSOR 4: El usuario le da CLIC a la notificación estando la app TOTALMENTE CERRADA
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 Clic con App Totalmente Cerrada');
        _procesarNotificacionData(initialMessage);
      }

    } else {
      print("❌ Permiso de notificaciones DENEGADO");
    }
  }

  // ====================================================================
  // 🚀 FUNCIÓN CLAVE CORREGIDA: Redirección automática al hacer clic
  // ====================================================================
  static void _procesarNotificacionData(RemoteMessage message) {
    if (message.data.isEmpty) return;

    print("📊 Datos ocultos recibidos: ${message.data}");
    
    // Extraemos los datos que mandó tu servidor Node.js
    final tipoDePantalla = message.data['screen'];
    final idSolicitud = message.data['solicitud_id'];

    if (tipoDePantalla == 'detalle_servicio' && idSolicitud != null) {
      print("🚀 Redirigiendo automáticamente a la solicitud: $idSolicitud");
      
      // Usamos la llave global de main.dart para navegar sin usar "context"
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => DetalleServicioScreen(solicitudId: idSolicitud),
        ),
      );
    }
  }

  static Future<void> _guardarToken(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('tecnicos').doc(user.uid).update({'fcm_token': token});
        print("✅ Token actualizado en TÉCNICO");
      } catch (e) {}

      try {
        await FirebaseFirestore.instance.collection('clientes').doc(user.uid).update({'fcm_token': token});
        print("✅ Token actualizado en CLIENTE");
      } catch (e) {}
    }
  }
}