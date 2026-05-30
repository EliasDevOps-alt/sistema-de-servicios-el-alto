import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // <-- IMPORTANTE: Rastreará al técnico

// Ahora es StatefulWidget para poder actualizar el GPS en tiempo real
class ClientMapScreen extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String nombreCliente;

  const ClientMapScreen({
    super.key, 
    required this.latitud, 
    required this.longitud,
    this.nombreCliente = "Ubicación del Cliente"
  });

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  final MapController _mapController = MapController();
  
  LatLng? _posicionTecnico;
  StreamSubscription<Position>? _positionStream;
  bool _isLoadingGPS = true;
  double _distancia = 0.0;

  @override
  void initState() {
    super.initState();
    _iniciarRastreo();
  }

  @override
  void dispose() {
    // IMPORTANTE: Apagar el GPS cuando cierre el mapa para no gastar batería
    _positionStream?.cancel();
    super.dispose();
  }

  // --- FUNCIÓN QUE SIGUE AL TÉCNICO MIENTRAS CONDUCE/CAMINA ---
  Future<void> _iniciarRastreo() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // 1. Obtener la ubicación inicial rápido
      Position posInicial = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _posicionTecnico = LatLng(posInicial.latitude, posInicial.longitude);
          _isLoadingGPS = false;
          _calcularDistancia();
        });
        _mapController.move(_posicionTecnico!, 15.0); // Centra en el técnico al abrir
      }

      // 2. Encender el "Radar" que actualiza su posición cada 5 metros
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _posicionTecnico = LatLng(position.latitude, position.longitude);
            _calcularDistancia(); // Recalcula la distancia a medida que avanza
          });
        }
      });
    } else {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  // --- MATEMÁTICA: CALCULA A CUÁNTOS METROS ESTÁ DEL CLIENTE ---
  void _calcularDistancia() {
    if (_posicionTecnico != null) {
      _distancia = Geolocator.distanceBetween(
        _posicionTecnico!.latitude, _posicionTecnico!.longitude,
        widget.latitud, widget.longitud,
      );
    }
  }

  // --- FUNCIÓN PARA VOLVER A CENTRAR LA CÁMARA EN EL TÉCNICO ---
  void _centrarEnTecnico() {
    if (_posicionTecnico != null) {
      _mapController.move(_posicionTecnico!, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng puntoCliente = LatLng(widget.latitud, widget.longitud);

    return Scaffold(
      appBar: AppBar(
        title: Text("Ruta: ${widget.nombreCliente}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[800], // Color del módulo Técnico
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Si el GPS tarda, iniciamos centrados en el cliente
              initialCenter: puntoCliente, 
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicios.elalto',
              ),
              MarkerLayer(
                markers: [
                  // ==========================================
                  // 1. MARCADOR DEL CLIENTE (DESTINO - AZUL)
                  // ==========================================
                  Marker(
                    point: puntoCliente,
                    width: 55, height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ),

                  // ==========================================
                  // 2. MARCADOR DEL TÉCNICO (EN MOVIMIENTO - NARANJA)
                  // ==========================================
                  if (_posicionTecnico != null)
                    Marker(
                      point: _posicionTecnico!,
                      width: 55, height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // --- TARJETA DE INFORMACIÓN (Distancia en vivo) ---
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
                    child: Icon(Icons.directions_run_rounded, color: Colors.orange[800], size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Distancia al cliente:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        _isLoadingGPS 
                          ? const Text("Calculando ruta...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          : Text(
                              _distancia > 1000 
                                ? "${(_distancia / 1000).toStringAsFixed(1)} km de distancia"
                                : "${_distancia.toStringAsFixed(0)} metros de distancia",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey[800]),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTÓN PARA RE-CENTRAR EN EL TÉCNICO ---
          Positioned(
            bottom: 30, right: 20,
            child: FloatingActionButton(
              heroTag: 'center_tech',
              backgroundColor: Colors.white,
              onPressed: _centrarEnTecnico,
              child: _isLoadingGPS 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.orange),
                  )
                : Icon(Icons.my_location_rounded, color: Colors.orange[800], size: 28),
            ),
          ),
        ],
      ),
    );
  }
}