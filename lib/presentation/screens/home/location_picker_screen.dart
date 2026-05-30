import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-16.5034, -68.1627); // El Alto
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion(); 
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permisos de ubicación denegados"))
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentPosition, 16.0);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Ubicación", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. MAPA (Ya no tiene el pin dibujado adentro)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicios.elalto.v1',
              ),
            ],
          ),
          
          // ===============================================
          // 2. PIN ROJO FIJO EN EL CENTRO (ESTILO UBER)
          // ===============================================
          const IgnorePointer( // Para que no interfiera al mover el mapa
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.0), // Eleva el ícono para que la punta apunte al centro exacto
                child: Icon(Icons.location_on, color: Colors.red, size: 55),
              ),
            ),
          ),

          // ===============================================
          // 3. LETRERO DE INSTRUCCIÓN FLOTANTE
          // ===============================================
          Positioned(
            top: 15, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.blue[900]?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))]
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Mueve el mapa para ajustar el pin rojo exactamente sobre tu casa.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 4. BOTÓN RE-CENTRAR GPS
          Positioned(
            bottom: 100, right: 20,
            child: FloatingActionButton(
              heroTag: 'gps_btn', 
              backgroundColor: Colors.white,
              onPressed: _obtenerUbicacion,
              child: _isLoading 
                ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 3)) 
                : const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // 5. BOTÓN CONFIRMAR
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                // CAPTURAMOS EL CENTRO EXACTO DEL MAPA EN ESE INSTANTE
                final centroExacto = _mapController.camera.center;
                
                GeoPoint ubicacionFinal = GeoPoint(centroExacto.latitude, centroExacto.longitude);
                Navigator.pop(context, ubicacionFinal);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text("ESTA ES MI UBICACIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}