import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Solo importamos el selector, porque él es el cerebro que decide a dónde ir
import 'role_selector_screen.dart';          

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoadingGoogle = false; 

  // --- FUNCIÓN DE LOGIN CON GOOGLE (VERSIÓN 7.0+ ) ---
  Future<void> iniciarSesionConGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      // 1. Instancia única global
      final googleSignIn = GoogleSignIn.instance;
      
      // 2. Inicialización obligatoria pasando tu Client ID Web
      // ---------------------------------------------------------
      // 🔥 AQUÍ ESTÁ EL CAMBIO: El ID de tu NUEVO proyecto (ervicios-el-altopro)
      // ---------------------------------------------------------
      await googleSignIn.initialize(
        serverClientId: "241627293072-p0sldeullp4bp3mdagufokrnlhmfj4th.apps.googleusercontent.com",
      );

      // 3. Iniciar el flujo de autenticación (ahora se llama authenticate)
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      if (googleUser == null) {
        setState(() => _isLoadingGoogle = false);
        return; 
      }

      // 4. Obtenemos los datos de identidad base (ahora sin "await")
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // 5. Solicitamos los permisos de acceso (Scopes) al usuario
      final authorization = await googleUser.authorizationClient?.authorizeScopes(['email', 'profile']);

      // 6. Armamos la credencial juntando el ID y los permisos
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // 7. Iniciamos sesión en Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 8. Redirigimos al Selector Inteligente
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error con Google: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.indigo; 

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 370, // <-- AQUÍ: Aumentamos la altura de la zona azul a 370
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.indigo[800]!, Colors.blue[600]!],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500), 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 50), // <-- AQUÍ: Damos más espacio superior (50 en vez de 20) para bajar todo el bloque
                              
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]
                                ),
                                child: Icon(Icons.handyman_rounded, size: 60, color: primaryColor),
                              ),
                              
                              const SizedBox(height: 20),
                              const Text(
                                "Servicios El Alto", 
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), 
                                textAlign: TextAlign.center
                              ),
                              const Text("Acceso Seguro", style: TextStyle(fontSize: 16, color: Colors.white70)),

                              const SizedBox(height: 60), 

                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Para garantizar la seguridad de nuestra comunidad, el acceso es exclusivo mediante cuentas verificadas de Google.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.blueGrey, fontSize: 14, height: 1.4),
                                    ),
                                    
                                    const SizedBox(height: 30),

                                    SizedBox(
                                      width: double.infinity, height: 60,
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoadingGoogle ? null : iniciarSesionConGoogle,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                          elevation: 2,
                                        ),
                                        icon: _isLoadingGoogle 
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 45),
                                        label: const Text("Continuar con Google", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}