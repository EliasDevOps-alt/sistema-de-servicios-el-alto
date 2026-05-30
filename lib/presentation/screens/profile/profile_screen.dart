import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Asegúrate de que esta ruta apunte bien a tu mapa
import '../home/location_picker_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los datos editables
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  
  // Controlador para el correo (Solo lectura)
  final TextEditingController _emailController = TextEditingController();

  GeoPoint? _ubicacionBase;
  int _radioSeleccionado = 3;
  final List<int> _opcionesRadio = [1, 3, 5, 10, 15]; // Opciones de kilómetros
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
  }

  // 1. CARGAMOS LOS DATOS DESDE FIRESTORE
  Future<void> _cargarDatosActuales() async {
    setState(() => _isLoading = true);
    try {
      User? usuarioActual = FirebaseAuth.instance.currentUser;
      if (usuarioActual != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('tecnicos')
            .doc(usuarioActual.uid)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _telefonoController.text = data['telefono'] ?? '';
            _especialidadController.text = data['especialidad'] ?? '';
            _emailController.text = data['email'] ?? ''; 
            
            _ubicacionBase = data['ubicacion'];
            _radioSeleccionado = data['radio_cobertura_km'] ?? 3;
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. FUNCIÓN PARA ABRIR EL MAPA
  Future<void> _actualizarUbicacion() async {
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

  // 3. GUARDAR SOLO LO PERMITIDO USANDO .update()
  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      if (_ubicacionBase == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes tener una ubicación base en el mapa"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        User? usuarioActual = FirebaseAuth.instance.currentUser;
        
        await FirebaseFirestore.instance.collection('tecnicos').doc(usuarioActual!.uid).update({
          'nombre': _nombreController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'especialidad': _especialidadController.text.trim(),
          'ubicacion': _ubicacionBase,
          'radio_cobertura_km': _radioSeleccionado,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil Profesional")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CAMPO BLOQUEADO (Seguridad)
                  TextFormField(
                    controller: _emailController,
                    readOnly: true, 
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico (No editable)",
                      prefixIcon: const Icon(Icons.email, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CAMPOS EDITABLES
                  _buildInput(_nombreController, "Nombre Completo", Icons.person),
                  const SizedBox(height: 15),
                  _buildInput(_telefonoController, "Celular", Icons.phone),
                  const SizedBox(height: 15),
                  _buildInput(_especialidadController, "Especialidad", Icons.work),
                  const SizedBox(height: 25),

                  // SECCIÓN DE COBERTURA Y MAPA
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.orange.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Configuración de Trabajo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 15),
                        
                        // Selector de kilómetros
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "Radio de cobertura",
                            prefixIcon: Icon(Icons.radar, color: Colors.orange),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                          value: _opcionesRadio.contains(_radioSeleccionado) ? _radioSeleccionado : 3,
                          items: _opcionesRadio.map((radio) {
                            return DropdownMenuItem<int>(
                              value: radio,
                              child: Text("$radio km a la redonda"),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            if (valor != null) setState(() => _radioSeleccionado = valor);
                          },
                        ),
                        const SizedBox(height: 15),

                        // Botón para actualizar la ubicación
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _actualizarUbicacion,
                            icon: Icon(
                              _ubicacionBase == null ? Icons.add_location_alt : Icons.map, 
                              color: _ubicacionBase == null ? Colors.red : Colors.green
                            ),
                            label: Text(
                              _ubicacionBase == null ? "Falta fijar Taller/Base" : "Actualizar mi Taller en el Mapa",
                              style: TextStyle(color: _ubicacionBase == null ? Colors.red : Colors.green),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _ubicacionBase == null ? Colors.red : Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // BOTÓN GUARDAR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}