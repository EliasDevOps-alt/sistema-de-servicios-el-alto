import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- Importación para Google Sign-In

import '../home/home_screen.dart';           
import '../home/home_tecnico_screen.dart';   
import 'registro_cliente_screen.dart';       
import 'registro_tecnico_screen.dart';       
import 'login_screen.dart'; 

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  Future<Map<String, bool>> _verificarPerfiles(String uid) async {
    // Busca en las colecciones correctas
    final docCliente = await FirebaseFirestore.instance.collection('clientes').doc(uid).get();
    final docTecnico = await FirebaseFirestore.instance.collection('tecnicos').doc(uid).get();

    return {
      'isCliente': docCliente.exists,
      'isTecnico': docTecnico.exists,
    };
  }

  // --- FUNCIÓN DE CERRAR SESIÓN TOTAL (CORREGIDA V7+) ---
  // --- FUNCIÓN DE CERRAR SESIÓN TOTAL (CORREGIDA DEFINITIVA V7+) ---
  Future<void> _cerrarSesionTotal(BuildContext context) async {
    // Usamos la instancia global directamente para cerrar sesión
    await GoogleSignIn.instance.signOut(); 
    await FirebaseAuth.instance.signOut(); 
    
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }
  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return PopScope(
      canPop: false, // Bloquea el botón de retroceso del celular
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        // Barra superior transparente con botón de Salir
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () => _cerrarSesionTotal(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: FutureBuilder<Map<String, bool>>(
          future: _verificarPerfiles(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 20),
                    Text("Cargando tu perfil...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final perfiles = snapshot.data ?? {'isCliente': false, 'isTecnico': false};
            final bool isCliente = perfiles['isCliente']!;
            final bool isTecnico = perfiles['isTecnico']!;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle, size: 80, color: Colors.indigo[300]),
                    const SizedBox(height: 20),
                    const Text(
                      "¿Cómo deseas usar la app hoy?", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                    ),
                    const SizedBox(height: 40),
                    
                    // ==========================================
                    // MÓDULO CLIENTE (AZUL)
                    // ==========================================
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCliente ? Colors.blue[600] : Colors.white,
                        foregroundColor: isCliente ? Colors.white : Colors.blue[600],
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: Colors.blue[600]!, width: 2),
                        elevation: isCliente ? 3 : 0,
                      ),
                      icon: const Icon(Icons.person, size: 28),
                      label: Text(
                        isCliente ? "ENTRAR COMO CLIENTE" : "Registrarme como Cliente", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      onPressed: () {
                        if (isCliente) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroClienteScreen()));
                        }
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // ==========================================
                    // MÓDULO TÉCNICO (NARANJA)
                    // ==========================================
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTecnico ? Colors.orange[800] : Colors.white,
                        foregroundColor: isTecnico ? Colors.white : Colors.orange[800],
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: Colors.orange[800]!, width: 2),
                        elevation: isTecnico ? 3 : 0,
                      ),
                      icon: const Icon(Icons.handyman_rounded, size: 26),
                      label: Text(
                        isTecnico ? "ENTRAR COMO TÉCNICO" : "Registrarme como Técnico", 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      onPressed: () {
                        if (isTecnico) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeTecnicoScreen()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroTecnicoScreen()));
                        }
                      },
                    ),
                    const SizedBox(height: 60), 
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}