import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_tecnico_screen.dart';
import '../home/location_picker_screen.dart'; 

class RegistroTecnicoScreen extends StatefulWidget {
  const RegistroTecnicoScreen({super.key});

  @override
  State<RegistroTecnicoScreen> createState() => _RegistroTecnicoScreenState();
}

class _RegistroTecnicoScreenState extends State<RegistroTecnicoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();

  bool _isLoading = false;

  GeoPoint? _ubicacionBase;
  int _radioSeleccionado = 3; 
  final List<int> _opcionesRadio = [1, 3, 5, 10, 15];

  Future<void> _seleccionarUbicacion() async {
    final GeoPoint? resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (resultado != null) {
      setState(() {
        _ubicacionBase = resultado;
      });
    }
  }

  void _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      if (_ubicacionBase == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes fijar tu ubicación base en el mapa"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // 1. Obtener el usuario de Google activo
        User? usuarioActivo = FirebaseAuth.instance.currentUser;

        if (usuarioActivo == null) {
           throw Exception("No se encontró una sesión de Google activa.");
        }

        // 2. Guardar datos en la colección técnicos
        await FirebaseFirestore.instance.collection('tecnicos').doc(usuarioActivo.uid).set({
          'uid': usuarioActivo.uid,
          'nombre': _nombreController.text.trim(),
          'email': usuarioActivo.email, // Tomado de Google
          'telefono': _telefonoController.text.trim(),
          'especialidad': _especialidadController.text.trim(),
          'rol': 'tecnico',
          'disponible': true,
          'verificado': false,
          'calificacion': 5.0,
          'fecha_registro': FieldValue.serverTimestamp(),
          'ubicacion': _ubicacionBase,
          'radio_cobertura_km': _radioSeleccionado,
        });

        if (mounted) {
           _mostrarDialogoExito();
        }

      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar datos: $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.verified_user_rounded, size: 60, color: Colors.green),
            SizedBox(height: 10),
            Text("¡Registro Exitoso!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Tus datos han sido guardados en la nube de Google.", textAlign: TextAlign.center),
            SizedBox(height: 10),
            Text(
              "⚡ ACCESO CONCEDIDO ⚡\nEntrando al sistema...",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeTecnicoScreen()),
                (route) => false,
              );
            },
            child: const Text("COMENZAR A TRABAJAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Técnico")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Únete al equipo", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("Completa tus datos para recibir trabajos", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // YA NO PEDIMOS CORREO NI CONTRASEÑA
              _buildInput(_nombreController, "Nombre Completo", Icons.person),
              const SizedBox(height: 15),
              _buildInput(_telefonoController, "Celular", Icons.phone, tipo: TextInputType.phone),
              const SizedBox(height: 15),
              _buildInput(_especialidadController, "Especialidad (ej. Plomero)", Icons.work),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Configuración de Trabajo", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Radio de cobertura",
                        prefixIcon: Icon(Icons.radar, color: Colors.orange),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      value: _radioSeleccionado,
                      items: _opcionesRadio.map((radio) {
                        return DropdownMenuItem<int>(
                          value: radio,
                          child: Text("$radio km a la redonda"),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => _radioSeleccionado = valor);
                        }
                      },
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarUbicacion,
                        icon: Icon(
                          _ubicacionBase == null ? Icons.add_location_alt : Icons.check_circle, 
                          color: _ubicacionBase == null ? Colors.orange : Colors.green
                        ),
                        label: Text(
                          _ubicacionBase == null ? "Fijar mi Taller / Base en el mapa" : "Ubicación fijada correctamente",
                          style: TextStyle(color: _ubicacionBase == null ? Colors.black87 : Colors.green),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _ubicacionBase == null ? Colors.orange : Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarFormulario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("ENVIAR POSTULACIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {TextInputType tipo = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      validator: (value) {
        if (value == null || value.isEmpty) return "Este campo es obligatorio";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}