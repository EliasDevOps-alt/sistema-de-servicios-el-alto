import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// IMPORTANTE: Cambiamos la ruta del login por la del selector
import '../auth/role_selector_screen.dart'; 

class ProfileClienteScreen extends StatefulWidget {
  const ProfileClienteScreen({super.key});

  @override
  State<ProfileClienteScreen> createState() => _ProfileClienteScreenState();
}

class _ProfileClienteScreenState extends State<ProfileClienteScreen> {
  final User? _usuarioAuth = FirebaseAuth.instance.currentUser;
  final Color _clientBlue = Colors.blue[900]!;

  // ==========================================
  // MÉTODO NUEVO: CAMBIAR DE ROL (REEMPLAZA A CERRAR SESIÓN)
  // ==========================================
  void _cambiarDeRol() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
    );
  }

  // MÉTODO REAL PARA EDITAR EL PERFIL
  void _mostrarDialogoEditar(String nombreActual, String telefonoActual) {
    final TextEditingController nombreController = TextEditingController(text: nombreActual == "Cliente" ? "" : nombreActual);
    final TextEditingController telefonoController = TextEditingController(text: telefonoActual == "No registrado" ? "" : telefonoActual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: "Nombre Completo", 
                  prefixIcon: Icon(Icons.person, color: _clientBlue),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _clientBlue))
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Teléfono / WhatsApp", 
                  prefixIcon: Icon(Icons.phone, color: _clientBlue),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _clientBlue))
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _clientBlue),
              onPressed: () async {
                if (nombreController.text.trim().isNotEmpty) {
                  // GUARDADO REAL BLINDADO CON SET+MERGE
                  await FirebaseFirestore.instance.collection('clientes').doc(_usuarioAuth!.uid).set({
                    'nombre': nombreController.text.trim(),
                    'telefono': telefonoController.text.trim(),
                  }, SetOptions(merge: true));
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green)
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("El nombre no puede estar vacío"), backgroundColor: Colors.red)
                  );
                }
              },
              child: const Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usuarioAuth == null) {
      return const Scaffold(
        body: Center(child: Text("No se encontró una sesión activa.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _clientBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          // ==========================================
          // BOTÓN ACTUALIZADO (FLECHAS EN LUGAR DE PUERTA DE SALIDA)
          // ==========================================
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
            onPressed: _cambiarDeRol,
            tooltip: "Cambiar de Perfil",
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('clientes').doc(_usuarioAuth!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar perfil: ${snapshot.error}"));
          }

          String nombre = "Cliente";
          String telefono = "No registrado";
          String email = _usuarioAuth!.email ?? "Sin correo";
          String ciudad = "El Alto"; 

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            nombre = data['nombre'] ?? data['name'] ?? (email.split('@')[0]);
            telefono = data['telefono'] ?? data['phone'] ?? "No registrado";
            ciudad = data['ciudad'] ?? "El Alto";
          }

          String iniciales = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : "C";

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _clientBlue,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          iniciales,
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _clientBlue),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Cuenta de Cliente",
                        style: TextStyle(fontSize: 14, color: Colors.blue[200], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Información Personal",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),

                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              _buildProfileItem(Icons.person_outline, "Nombre Completo", nombre),
                              const Divider(height: 25),
                              _buildProfileItem(Icons.email_outlined, "Correo Electrónico", email),
                              const Divider(height: 25),
                              _buildProfileItem(Icons.phone_android_outlined, "Teléfono / WhatsApp", telefono),
                              const Divider(height: 25),
                              _buildProfileItem(Icons.location_city_rounded, "Ciudad de Cobertura", ciudad),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: OutlinedButton.icon(
                          onPressed: () => _mostrarDialogoEditar(nombre, telefono),
                          icon: Icon(Icons.edit_rounded, color: _clientBlue),
                          label: Text("EDITAR MI PERFIL", style: TextStyle(color: _clientBlue, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _clientBlue, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String titulo, String valor) {
    return Row(
      children: [
        Icon(icon, color: _clientBlue, size: 26),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}