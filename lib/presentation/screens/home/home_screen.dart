import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:geolocator/geolocator.dart'; // <-- IMPORTANTE: Para el GPS automático

import 'solicitud_servicio_screen.dart';
import '../jobs/jobs_screen.dart';     
import '../profile/profile_cliente_screen.dart'; 
import '../auth/role_selector_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),            
    const JobsScreen(),             
    const ProfileClienteScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) async {
        if (didPop) return; 

        final bool? confirmarSalida = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Salir de la app", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("¿Estás seguro de que deseas salir de la aplicación?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), 
                child: const Text("NO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("SÍ, SALIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirmarSalida == true) {
          SystemNavigator.pop(); 
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Mapa"),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Mis Pedidos"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// AHORA HOME CONTENT ES STATEFUL PARA MANEJAR EL GPS
// ==========================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-16.5034, -68.1627); // El Alto por defecto temporal
  bool _isLoadingGPS = true;

  @override
  void initState() {
    super.initState();
    _centrarEnUsuario(); // Busca el GPS automáticamente al abrir
  }

  // --- FUNCIÓN QUE BUSCA EL GPS Y MUEVE EL MAPA ---
  Future<void> _centrarEnUsuario() async {
    setState(() => _isLoadingGPS = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingGPS = false;
        });
        // Mueve la cámara del mapa automáticamente
        _mapController.move(_currentPosition, 15.0); 
      }
    } else {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid; 

    return Stack(
      children: [
        // 1. MAPA EN TIEMPO REAL
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tecnicos')
              .where('disponible', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            List<Marker> marcadores = [];

            if (snapshot.hasData) {
              var documentos = snapshot.data!.docs;
              
              for (var doc in documentos) {
                var data = doc.data() as Map<String, dynamic>;
                GeoPoint? ubicacionReal = data['ubicacion'];

                if (ubicacionReal != null) {
                  LatLng posTecnico = LatLng(ubicacionReal.latitude, ubicacionReal.longitude);
                  marcadores.add(_buildMarker(context, posTecnico, Colors.orange, data));
                }
              }
            }

            return FlutterMap(
              mapController: _mapController, // <-- Conectamos el controlador del mapa
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.servicios.elalto',
                ),
                MarkerLayer(markers: marcadores), // Los técnicos
                
                // ==========================================
                // MARCADOR DINÁMICO DEL CLIENTE (TÚ)
                // ==========================================
                if (!_isLoadingGPS)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition,
                        width: 55,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                      )
                    ],
                  )
              ],
            );
          },
        ),

        // 2. BARRA SUPERIOR CORREGIDA
        Positioned(
          top: 50, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                // Hacemos que el ícono sea tocable para re-centrar el mapa al GPS actual
                GestureDetector(
                  onTap: _centrarEnUsuario,
                  child: _isLoadingGPS 
                    ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.blue[800], strokeWidth: 2))
                    : Icon(Icons.my_location_rounded, color: Colors.blue[800], size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: uid != null ? FirebaseFirestore.instance.collection('clientes').doc(uid).get() : null,
                    builder: (context, snapshot) {
                      String nombre = "Cliente";
                      
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        nombre = data['nombre'] ?? data['name'] ?? "Cliente";
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hola, ${nombre.split(' ')[0]} 👋", 
                            style: TextStyle(color: Colors.blue[900], fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _isLoadingGPS ? "Buscando tu zona..." : "Ubicación activa",
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.swap_horiz_rounded, color: Colors.blue[800], size: 26),
                    tooltip: 'Cambiar de Perfil',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. BOTÓN INFERIOR DE ACCIÓN
        Positioned(
          bottom: 30, left: 20, right: 20,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[800]!, Colors.blue[500]!]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SolicitudServicioScreen()),
                  );

                  if (resultado == "PUBLICADO") {
                    if (context.mounted) _mostrarDialogoBusqueda(context);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text("BUSCAR TÉCNICO AHORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MARCADOR DINÁMICO DE LOS TÉCNICOS
  // ==========================================
  Marker _buildMarker(BuildContext context, LatLng point, Color color, Map<String, dynamic> datosTecnico) {
    return Marker(
      point: point,
      width: 50, // Ajustado para que el ícono redondo se vea bien
      height: 50,
      child: GestureDetector(
        onTap: () => _mostrarFichaTecnico(context, datosTecnico, color),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: Icon(Icons.handyman_rounded, color: color, size: 28), // Ícono de técnico
        ),
      ),
    );
  }
}

void _mostrarFichaTecnico(BuildContext context, Map<String, dynamic> datos, Color color) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(radius: 35, backgroundColor: color.withOpacity(0.1), child: Icon(Icons.person, size: 40, color: color)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(datos['nombre'] ?? "Técnico", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(datos['especialidad'] ?? "General", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(" ${datos['calificacion'] ?? 5.0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SolicitudServicioScreen()));
                },
                child: const Text("SOLICITAR SERVICIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _mostrarDialogoBusqueda(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Solicitud Enviada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            Text("Estamos notificando a los técnicos disponibles. Te avisaremos cuando acepten.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO")),
        ],
      );
    },
  );
}