import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

// TUS PANTALLAS
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/role_selector_screen.dart'; 

// NUEVO IMPORT: Traemos el cerebro de las notificaciones
import 'push_notification_service.dart'; 

// ====================================================================
// 🔑 NUEVO: LA LLAVE MAESTRA DEL NAVEGADOR (Global)
// Esto permite que el servicio de notificaciones cambie de pantalla sin 'context'
// ====================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZACIÓN INTELIGENTE (Detecta si es Web o Celular)
  if (kIsWeb) {
    // --- CONFIGURACIÓN PARA WEB (Chrome) NUEVA ---
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAAbMlTKwfg7ubbJZbOZaY8vE_tECEfB3w",
        authDomain: "ervicios-el-altopro.firebaseapp.com",
        projectId: "ervicios-el-altopro",
        storageBucket: "ervicios-el-altopro.firebasestorage.app",
        messagingSenderId: "299480835203",
        appId: "1:299480835203:web:093c05feb26b493ae6e7b6",
      ),
    );
  } else {
    // --- CONFIGURACIÓN PARA MÓVIL (Android) ---
    await Firebase.initializeApp();
  }

  // =========================================================
  // ¡AQUÍ DESPERTAMOS EL SERVICIO DE NOTIFICACIONES PUSH!
  // =========================================================
  await PushNotificationService.inicializarNotificaciones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🚀 ENLACE CLAVE: Vinculamos la llave global a MaterialApp
      navigatorKey: navigatorKey, 
      debugShowCheckedModeBanner: false,
      title: 'Servicios El Alto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      // --- MAGIA: EL PORTERO AUTOMÁTICO ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras verifica el token guardado en el celular
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          // ¡Si tiene token (ya inició sesión antes)!
          if (snapshot.hasData) {
            return const RoleSelectorScreen(); 
          }
          
          // Si no tiene cuenta o cerró sesión
          return const LoginScreen(); 
        },
      ), 
    );
  }
}