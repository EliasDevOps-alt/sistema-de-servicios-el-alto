import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart'; // <--- Necesario para coordenadas
import 'location_picker_screen.dart';   // <--- Importamos tu mapa

class SolicitudServicioScreen extends StatefulWidget {
  const SolicitudServicioScreen({super.key});

  @override
  State<SolicitudServicioScreen> createState() => _SolicitudServicioScreenState();
}

class _SolicitudServicioScreenState extends State<SolicitudServicioScreen> {
  // --- VARIABLES ---
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController(); 
  
  // Guardamos las coordenadas aquí
  LatLng? _coordenadasGPS; 
  
  String? _categoriaSeleccionada;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categoriasData = [
    {"id": "1", "nombre": "Plomería", "icon": Icons.water_drop_outlined},
    {"id": "2", "nombre": "Electricidad", "icon": Icons.bolt_rounded},
    {"id": "3", "nombre": "Albañilería", "icon": Icons.foundation_rounded},
    {"id": "4", "nombre": "Limpieza", "icon": Icons.cleaning_services_rounded},
    {"id": "5", "nombre": "Cerrajería", "icon": Icons.vpn_key_rounded},
    {"id": "6", "nombre": "Pintura", "icon": Icons.format_paint_rounded},
    {"id": "7", "nombre": "Gasfitería", "icon": Icons.fire_extinguisher},
    {"id": "8", "nombre": "Otros", "icon": Icons.more_horiz_rounded},
  ];

  final Color _primaryColor = Colors.blue[700]!;

  // --- FUNCIÓN PARA ABRIR EL MAPA (CORREGIDA PARA EVITAR CHOQUES) ---
  Future<void> _seleccionarUbicacion() async {
    try {
      // Quitamos el forzado de tipo "LatLng?" para que acepte cualquier resultado
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );

      if (resultado != null) {
        setState(() {
          // Si recibe un GeoPoint (lo que envía tu mapa corregido)
          if (resultado is GeoPoint) {
            _coordenadasGPS = LatLng(resultado.latitude, resultado.longitude);
          } 
          // Si por alguna razón recibe un LatLng directo
          else if (resultado is LatLng) {
            _coordenadasGPS = resultado;
          }

          // Actualizamos el texto si logramos capturar la coordenada
          if (_coordenadasGPS != null) {
            _ubicacionController.text = "GPS: ${_coordenadasGPS!.latitude.toStringAsFixed(5)}, ${_coordenadasGPS!.longitude.toStringAsFixed(5)}";
          }
        });
      }
    } catch (e) {
      debugPrint("Error de navegación: $e");
    }
  }

  // --- LÓGICA DE ENVÍO A FIREBASE ---
  Future<void> enviarSolicitud() async {
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona una categoría"), backgroundColor: Colors.red));
      return;
    }
    if (_tituloController.text.isEmpty || _descripcionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Completa el título y descripción"), backgroundColor: Colors.orange));
      return;
    }
    // Opcional: Obligar a usar GPS
    /*
    if (_coordenadasGPS == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Por favor selecciona tu ubicación en el mapa"), backgroundColor: Colors.red));
      return;
    }
    */

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Guardar en Firestore con Coordenadas Reales
      await FirebaseFirestore.instance.collection('solicitudes').add({
        'cliente_uid': user?.uid,
        'cliente_email': user?.email,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'ubicacion': _ubicacionController.text.trim(), // Texto (ej: "Mi casa")
        'latitud': _coordenadasGPS?.latitude,          // GPS Lat
        'longitud': _coordenadasGPS?.longitude,        // GPS Lng
        'estado': 'pendiente',
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, "PUBLICADO");

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Nueva Solicitud", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Qué necesitas reparar?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 5),
            Text("Selecciona una categoría y describe tu problema.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 25),

            // 1. SELECTOR DE CATEGORÍA
            const Text("Categoría del Servicio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categoriasData.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 15),
                itemBuilder: (ctx, i) {
                  final cat = _categoriasData[i];
                  final isSelected = _categoriaSeleccionada == cat["nombre"];
                  return GestureDetector(
                    onTap: () => setState(() => _categoriaSeleccionada = cat["nombre"]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? _primaryColor : Colors.grey[300]!, width: 2),
                        boxShadow: [if (!isSelected) BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 3))]
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat["icon"], color: isSelected ? Colors.white : Colors.grey[600], size: 30),
                          const SizedBox(height: 8),
                          Text(
                            cat["nombre"], 
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 2. TÍTULO
            _buildModernInput(controller: _tituloController, label: "Título breve (Ej. Grifo goteando)", icon: Icons.title_rounded),
            const SizedBox(height: 20),

            // 3. DETALLES
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]),
              child: TextField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe el problema con detalle...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 4. UBICACIÓN CON BOTÓN DE MAPA
            Row(
              children: [
                Expanded(
                  child: _buildModernInput(
                    controller: _ubicacionController,
                    label: "Ubicación o Referencia", 
                    icon: Icons.location_on
                  ),
                ),
                const SizedBox(width: 10),
                // BOTÓN MAPA
                InkWell(
                  onTap: _seleccionarUbicacion,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    height: 55, width: 55,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange)
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.deepOrange),
                  ),
                )
              ],
            ),
            if (_coordenadasGPS != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 10),
                child: Text("✅ Coordenadas guardadas", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 40),

            // BOTÓN PUBLICAR
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryColor, Colors.blue[500]!]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : enviarSolicitud,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR SOLICITUD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput({required String label, required IconData icon, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: _primaryColor),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}