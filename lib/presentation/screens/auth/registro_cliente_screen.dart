import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart'; // IMPORTANTE: Para mandar al usuario al Home de Cliente

class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key});

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
  final _nombreController = TextEditingController();
  final _celularController = TextEditingController(); 
  bool _isLoading = false;

  Future<void> registrarCliente() async {
    // Validación básica
    if (_nombreController.text.isEmpty || _celularController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa todos los campos', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Obtener el usuario actual que acaba de iniciar sesión con Google
      User? usuarioActivo = FirebaseAuth.instance.currentUser;
      
      if (usuarioActivo == null) {
        throw Exception("No se encontró una sesión de Google activa.");
      }

      // CORRECCIÓN 1: Guardamos en la colección 'clientes'
      // Usamos SetOptions(merge: true) por seguridad, igual que en el perfil
      await FirebaseFirestore.instance.collection('clientes').doc(usuarioActivo.uid).set({
        'uid': usuarioActivo.uid,
        'nombre': _nombreController.text.trim(),
        'email': usuarioActivo.email, 
        // CORRECCIÓN 2: Guardamos la variable como 'telefono'
        'telefono': _celularController.text.trim(), 
        'rol': 'cliente', 
        'fecha_registro': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta Creada con Éxito'), backgroundColor: Colors.green));
      
      // 3. Mandarlo directo al Dashboard del Cliente
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Círculo de foto (Visual)
            Center(
              child: Container(
                height: 100, width: 100,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.blue, size: 40),
              ),
            ),
            const SizedBox(height: 30),

            const Text('Registro de Cliente', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Text('Completa tu perfil para encontrar expertos cerca de ti.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            _buildTextField('Nombre Completo', Icons.person, _nombreController),
            _buildTextField('Número de Celular / WhatsApp', Icons.phone, _celularController, tipo: TextInputType.phone),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : registrarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800], // AZUL CLIENTE
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREAR CUENTA', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[800]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
          ),
        ),
      ),
    );
  }
}