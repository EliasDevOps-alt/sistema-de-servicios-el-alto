import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';     
import 'package:cloud_firestore/cloud_firestore.dart'; 

// NUEVOS IMPORTS PARA EL MINI-MAPA DEL MODAL
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// TUS PANTALLAS
import '../auth/login_screen.dart'; 
import 'chat_screen.dart';
import 'client_map_screen.dart'; 
import '../profile/profile_screen.dart'; 

// IMPORTS PARA WEB SCRAPING
import 'package:http/http.dart' as http; 
import 'package:html/parser.dart' as parser; 
import 'package:url_launcher/url_launcher.dart'; 
import '../auth/role_selector_screen.dart'; // Ajusta la ruta relativa si es necesario
 
import 'dart:convert'; // <--- AGREGAR ESTA LÍNEA ARRIBA
class HomeTecnicoScreen extends StatefulWidget {
  const HomeTecnicoScreen({super.key});

  @override
  State<HomeTecnicoScreen> createState() => _HomeTecnicoScreenState();
}

class _HomeTecnicoScreenState extends State<HomeTecnicoScreen> {
  int _currentIndex = 0;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // PALETA DE COLORES
  final Color _primaryColor = Colors.blue[800]!; 
  final Color _accentColor = Colors.blueAccent;
  final Color _successColor = Colors.green[700]!; 
  final Color _infoColor = Colors.teal[600]!; 

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  // ===========================================================================
  // LÓGICA DE CANCELACIÓN Y FINALIZACIÓN
  // ===========================================================================
  // ===========================================================================
  // LÓGICA DE CANCELACIÓN CON REGISTRO DE PENALIZACIÓN
  // ===========================================================================
  void _mostrarDialogoCancelar(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar servicio?"),
        content: const Text(
          "⚠️ ATENCIÓN: Si cancelas más de 3 trabajos en una semana, tu cuenta será suspendida temporalmente.",
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo primero

              // Usamos un Batch para escribir en dos lados al mismo tiempo de forma segura
              WriteBatch batch = FirebaseFirestore.instance.batch();

              // 1. Referencia de la solicitud para liberarla
              DocumentReference solicitudRef = FirebaseFirestore.instance.collection('solicitudes').doc(docId);
              batch.update(solicitudRef, {
                'estado': 'pendiente',
                'tecnico_uid': null,
                'tecnico_email': null,
              });

              // 2. Referencia en el historial del técnico para anotar la infracción
              DocumentReference infraccionRef = FirebaseFirestore.instance
                  .collection('tecnicos')
                  .doc(_uid)
                  .collection('cancelaciones')
                  .doc(); // ID automático
              
              batch.set(infraccionRef, {
                'fecha': FieldValue.serverTimestamp(), // Hora del servidor de Firebase, no del celular
                'solicitud_id': docId,
              });

              try {
                await batch.commit(); // Se ejecutan ambas operaciones juntas
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Trabajo liberado. Registro de cancelación anotado."), backgroundColor: Colors.orange)
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("SÍ, CANCELAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
// Verifica si el técnico superó el límite de cancelaciones permitidas en la semana
  // 1. REEMPLAZA TU FUNCIÓN POR ESTA:
  Future<int> _contarCancelaciones() async {
    DateTime haceUnaSemana = DateTime.now().subtract(const Duration(days: 7));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('tecnicos')
        .doc(_uid)
        .collection('cancelaciones')
        .where('fecha', isGreaterThanOrEqualTo: haceUnaSemana)
        .get();

    int cantidad = snapshot.docs.length;

    // Lo apaga en Firebase si llega a 3 (0 vidas)
    if (cantidad >= 3) {
      await FirebaseFirestore.instance.collection('tecnicos').doc(_uid).update({
        'disponible': false 
      });
    }

    return cantidad; // Ahora devuelve el número de cancelaciones
  }
  void _mostrarDialogoFinalizar(String docId) {
    final TextEditingController precioController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Finalizar Trabajo", style: TextStyle(color: Colors.blueGrey)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, size: 50, color: _successColor),
            const SizedBox(height: 10),
            const Text("Ingresa el monto cobrado:"),
            const SizedBox(height: 15),
            TextField(
              controller: precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), 
              ],
              decoration: InputDecoration(
                labelText: "Monto (Bs)",
                prefixText: "Bs. ",
                hintText: "Ej: 150.00",
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 2)),
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
            onPressed: () async {
              if (precioController.text.isNotEmpty) {
                String textoLimpio = precioController.text.replaceAll(',', '.');
                double precio = double.tryParse(textoLimpio) ?? 0.0;
                
                if (precio > 0) {
                  await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({
                    'estado': 'finalizado',
                    'precio': precio, 
                    'fecha_finalizado': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ Ganancia registrada: Bs. $precio"), backgroundColor: _successColor)
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Ingresa un monto válido"), backgroundColor: Colors.orange)
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _successColor, foregroundColor: Colors.white),
            child: const Text("COBRAR Y FINALIZAR"),
          )
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL CORREGIDO: VISTA PREVIA (SIN OVERFLOW)
  // ===========================================================================
 void _mostrarDetallesTrabajo(BuildContext context, String solicitudId, Map<String, dynamic> data) {
    double? lat = data['latitud'];
    double? lng = data['longitud'];
    String titulo = data['titulo'] ?? 'Solicitud sin título';
    String categoria = data['categoria'] ?? 'General';
    String ubicacion = data['ubicacion'] ?? 'Dirección no especificada';
    String descripcion = data['descripcion'] ?? 'El cliente no proporcionó detalles adicionales.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75, 
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 15),
                    height: 5, width: 50,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(categoria.toUpperCase(), style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey), 
                        onPressed: () => Navigator.pop(context)
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                if (lat != null && lng != null)
                  Container(
                    height: 130, 
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), 
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.servicios.elalto.v1',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 50, height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[700], shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 80, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text("El cliente no compartió GPS exacto", style: TextStyle(color: Colors.grey))),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.map_rounded, color: Colors.blueGrey[400], size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(ubicacion, style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const Divider(height: 30),
                        const Text("Detalles del problema:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text(descripcion, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); 
                      try { 
                        // 1. Actualizamos en Firebase
                        await FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId).update({
                          'estado': 'aceptado', 
                          'tecnico_uid': _uid, 
                          'tecnico_email': FirebaseAuth.instance.currentUser?.email
                        }); 

                        // ==========================================
                        // 2. DISPARAMOS LA NOTIFICACIÓN AL CLIENTE
                        // ==========================================
                        String? clienteUid = data['cliente_uid'];
                        if (clienteUid != null) {
                          await _enviarNotificacionCartero(clienteUid);
                        }

                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("¡Trabajo Aceptado! Ve a la pestaña Pendientes."), backgroundColor: _successColor)); 
                      } catch (e) { 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al aceptar: $e"))); 
                      } 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor, 
                      foregroundColor: Colors.white, 
                      minimumSize: const Size(double.infinity, 55), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.handshake_rounded, size: 24),
                    label: const Text("ACEPTAR ESTE TRABAJO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  // =================================================================
  // EL CARTERO: Función que busca el token y manda el mensaje
  // =================================================================
  Future<void> _enviarNotificacionCartero(String clienteUid) async {
    try {
      var clienteDoc = await FirebaseFirestore.instance.collection('clientes').doc(clienteUid).get();
      if (!clienteDoc.exists) return;
      
      String? tokenCliente = clienteDoc.data()?['fcm_token'];
      if (tokenCliente == null) return; 

      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=TU_CLAVE_DE_SERVIDOR_AQUI', // <-- ¡AQUÍ ESTÁ LO QUE FALTA!
        },
        body: jsonEncode({
          'to': tokenCliente, 
          'notification': {
            'title': '¡Técnico en camino! 🏃‍♂️',
            'body': 'Un experto ha aceptado tu solicitud y va hacia tu ubicación.',
            'sound': 'default'
          }
        }),
      );
      
      debugPrint("✅ Notificación enviada al cliente exitosamente.");
    } catch (e) {
      debugPrint("❌ Error enviando notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('tecnicos').doc(_uid).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator(color: _primaryColor)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion)]),
            body: const Center(child: Text("Error: No se encontró perfil de técnico")),
          );
        }

        var tecnicoData = snapshot.data!.data() as Map<String, dynamic>;
        bool estaDisponible = tecnicoData['disponible'] ?? false;
        String nombreReal = tecnicoData['nombre'] ?? "Técnico";
        String especialidadReal = tecnicoData['especialidad'] ?? "General";

        List<Widget> paginas = [
          _buildRadarOfertas(estaDisponible),
          _buildMisTrabajosActivos(),         
          _buildPerfilHistorial(nombreReal, especialidadReal), 
          _buildWebScraping(),                
        ];

        // ==========================================
        // AQUÍ AGREGAMOS EL ESCUDO: POPSCOPE
        // ==========================================
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
            appBar: AppBar(
              title: const Text("Panel Técnico", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              centerTitle: false,
              backgroundColor: _primaryColor, 
              foregroundColor: Colors.white,
              elevation: 5,
              actions: [
                if (_currentIndex == 0)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15), // Cambiado de withValues para mayor compatibilidad
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                    ),
                    child: Row(
                      children: [
                        Text(estaDisponible ? "ON" : "OFF", 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: estaDisponible,
                            activeTrackColor: _successColor,
                            activeThumbColor: Colors.white,
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: Colors.blueGrey[300],
                            // ==========================================
                            // AQUÍ ESTÁ LA CORRECCIÓN DEL BLOQUEO:
                            // ==========================================
                            onChanged: (nuevoValor) async {
                              if (nuevoValor == true) { 
                                int cancelaciones = await _contarCancelaciones();
                                if (cancelaciones >= 3) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Bloqueado: Tu cuenta está suspendida."),
                                        backgroundColor: Colors.red,
                                      )
                                    );
                                  }
                                  return; 
                                }
                              }
                              await FirebaseFirestore.instance.collection('tecnicos').doc(_uid).update({'disponible': nuevoValor});
                            },
                            // ==========================================
                          ),
                        ),
                      ],
                    ),
                  ),
                // BOTÓN PERFIL
                IconButton(
                  icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  tooltip: "Mi Perfil",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                ),
                // BOTÓN SALIR
                    // BOTÓN CAMBIAR A CLIENTE (Reemplaza al BOTÓN SALIR)
                    Container(
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2), 
                      shape: BoxShape.circle,
                     ),
                    child: IconButton(
                     icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                       tooltip: "Cambiar a modo Cliente",
                           onPressed: () {
                        Navigator.pushReplacement(
                       context,
                      MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                    );
                 },
                  ),
                  ),
                const SizedBox(width: 5),
              ],
            ),
            backgroundColor: Colors.grey[100], 
            body: paginas[_currentIndex],
            
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                selectedItemColor: _primaryColor,
                unselectedItemColor: Colors.blueGrey[300],
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: "Ofertas"),
                  BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: "Pendientes"),
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Ganancias"), 
                  BottomNavigationBarItem(icon: Icon(Icons.public_rounded), label: "Explorar"), 
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // --- PANTALLA 1: RADAR ---
  // --- PANTALLA 1: RADAR (CON FILTRO DE SUSPENSIÓN) ---
  // 3. REEMPLAZA TODO EL MÉTODO _buildRadarOfertas POR ESTE:
  Widget _buildRadarOfertas(bool disponible) {
    return FutureBuilder<int>(
      future: _contarCancelaciones(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        int cancelaciones = snapshot.data ?? 0;
        int vidasRestantes = 3 - cancelaciones;

        // CASO A: CUENTA SUSPENDIDA (0 Vidas)
        if (cancelaciones >= 3) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel_rounded, size: 100, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text("Cuenta Suspendida", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 15),
                  Text("Has cancelado 3 o más servicios asignados en los últimos 7 días. Tu acceso a nuevas ofertas del radar ha sido restringido.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[700], fontSize: 15, height: 1.4)),
                  const SizedBox(height: 25),
                  const Text("Las penalizaciones se limpian automáticamente de tu historial después de transcurridos 7 días de cada evento.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic))
                ],
              ),
            ),
          );
        }

        // CASO B: DESCONECTADO (Muestra el botón y la advertencia si gastó vidas)
        if (!disponible) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(Icons.power_off_rounded, size: 100, color: Colors.blueGrey.withValues(alpha: 0.3)), 
                const SizedBox(height: 20), 
                Text("Estás Desconectado", style: TextStyle(color: Colors.blueGrey[700], fontSize: 24, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 10), 
                const Text("Activa el interruptor en la barra superior\npara comenzar a recibir ofertas.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 20),
                if (cancelaciones > 0) // AVISO DE VIDAS RESTANTES
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange)),
                    child: Text("⚠️ Atención: Te quedan $vidasRestantes cancelaciones permitidas esta semana.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  )
              ]
            )
          );
        }

        // CASO C: CONECTADO Y BUSCANDO (Radar normal + Banner superior si gastó vidas)
        return Column(
          children: [
            if (cancelaciones > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade100,
                child: Text("⚠️ Cuidado: Te quedan solo $vidasRestantes cancelaciones esta semana.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('solicitudes').where('estado', isEqualTo: 'pendiente').orderBy('fecha', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _primaryColor));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.radar_rounded, size: 80, color: _accentColor.withValues(alpha: 0.5)), const SizedBox(height: 20), Text("Escaneando zona...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)), const Text("No hay solicitudes nuevas por ahora.", style: TextStyle(color: Colors.grey))]));
                  
                  var listaSolicitudes = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 15),
                    itemCount: listaSolicitudes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.notifications_active_rounded, color: _primaryColor, size: 28), const SizedBox(width: 10), const Text("Oportunidades Nuevas", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))]), const Padding(padding: EdgeInsets.only(left: 38), child: Text("Trabajos cercanos listos para tomar", style: TextStyle(color: Colors.grey)))]));
                      
                      var doc = listaSolicitudes[index - 1];
                      var data = doc.data() as Map<String, dynamic>;
                      
                      return _buildOfertaCardVibrante(doc.id, data['titulo'] ?? 'Solicitud', data['categoria'] ?? 'General', data['ubicacion'] ?? 'Ubicación desconocida', true, data);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildOfertaCardVibrante(String solicitudId, String titulo, String categoria, String zona, bool disponible, Map<String, dynamic> dataCompleta) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: _primaryColor.withValues(alpha: 0.2), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(categoria.toUpperCase(), style: TextStyle(color: _primaryColor, fontSize: 11, fontWeight: FontWeight.w900))), 
                Text("Nueva", style: TextStyle(fontSize: 12, color: _successColor, fontWeight: FontWeight.bold))
              ]
            ), 
            const SizedBox(height: 15), 
            Row(
              children: [
                CircleAvatar(backgroundColor: _primaryColor.withValues(alpha: 0.1), child: Icon(Icons.build_circle, color: _primaryColor)), 
                const SizedBox(width: 15), 
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(zona, style: TextStyle(color: Colors.blueGrey[600]))]))
              ]
            ), 
            const SizedBox(height: 15), 
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarDetallesTrabajo(context, solicitudId, dataCompleta), 
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor, 
                      side: BorderSide(color: _primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ), 
                    icon: const Icon(Icons.visibility_rounded), 
                    label: const Text("EVALUAR TRABAJO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
                  )
                )
              ]
            )
          ]
        ),
      ),
    );
  }

  // --- PANTALLA 2: MIS TRABAJOS ---
  Widget _buildMisTrabajosActivos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('solicitudes').where('tecnico_uid', isEqualTo: _uid).where('estado', isEqualTo: 'aceptado').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _infoColor));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.blueGrey[200]), const SizedBox(height: 20), Text("Sin trabajos activos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])), const Text("Ve al Radar para aceptar nuevos pedidos.", style: TextStyle(color: Colors.grey))]));
        
        var trabajos = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 15),
          itemCount: trabajos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("Tu Agenda de Hoy", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.blueGrey)));
            var doc = trabajos[index - 1];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTrabajoActivoCard(doc.id, data['titulo'] ?? 'Trabajo', data['descripcion'] ?? 'Sin detalles', data['cliente_email'] ?? 'Cliente', data['cliente_uid'] ?? '', data['ubicacion'] ?? 'Ubicación remota', data['latitud'], data['longitud']);
          },
        );
      },
    );
  }

  // CORRECCIÓN: Agregamos "String clienteUid" a los parámetros de la función
Widget _buildTrabajoActivoCard(String docId, String titulo, String descripcion, String cliente, String clienteUid, String ubicacion, double? lat, double? lng) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: _infoColor.withValues(alpha: 0.3), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _infoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.engineering_rounded, size: 16, color: _infoColor), const SizedBox(width: 5), Text("EN PROCESO", style: TextStyle(color: _infoColor, fontWeight: FontWeight.w900, fontSize: 11))])), 
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  tooltip: "Cancelar Trabajo",
                  onPressed: () => _mostrarDialogoCancelar(docId),
                )
              ]
            ),
            const SizedBox(height: 5),
            Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(descripcion, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            const SizedBox(height: 15),
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: Colors.blueGrey[50], child: Icon(Icons.person, size: 20, color: Colors.blueGrey[400])), 
                const SizedBox(width: 10), 
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Cliente:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)), Text(cliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)])), 
                IconButton(
                  onPressed: () { 
                    // ==========================================
                    // CORRECCIÓN APLICADA: Pasamos el receptorId
                    // ==========================================
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                      nombreTecnico: cliente,
                      receptorId: clienteUid, // <--- ESTO SOLUCIONA EL ERROR ROJO
                    ))); 
                  }, 
                  icon: const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 20, child: Icon(Icons.chat_bubble, color: Colors.white, size: 20))
                )
              ]
            ),
            const Divider(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.map_rounded, color: _primaryColor), 
                    label: Text("VER MAPA", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)), 
                    style: OutlinedButton.styleFrom(side: BorderSide(color: _primaryColor, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                    onPressed: () {
                      if (lat != null && lng != null) { Navigator.push(context, MaterialPageRoute(builder: (context) => ClientMapScreen(latitud: lat, longitud: lng, nombreCliente: cliente))); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dirección: $ubicacion"), backgroundColor: _infoColor)); }
                    }
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _successColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                    icon: const Icon(Icons.task_alt_rounded), 
                    label: const Text("FINALIZAR", style: TextStyle(fontWeight: FontWeight.bold)), 
                    onPressed: () => _mostrarDialogoFinalizar(docId) 
                  )
                ),
              ]
            )
          ]
        ),
      ),
    );
  }

  // --- PANTALLA 3: HISTORIAL ---
  Widget _buildPerfilHistorial(String nombre, String especialidad) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where('tecnico_uid', isEqualTo: _uid)
          .where('estado', isEqualTo: 'finalizado')
          .orderBy('fecha', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
        }

        double gananciasTotales = 0;
        List<DocumentSnapshot> trabajos = [];
        double sumaEstrellas = 0;
        int trabajosCalificados = 0;

        if (snapshot.hasData) {
          trabajos = snapshot.data!.docs;
          for (var doc in trabajos) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['calificacion'] != null) {
              sumaEstrellas += (data['calificacion'] as num).toDouble();
              trabajosCalificados++;
            }
            if (data['precio'] != null) {
              gananciasTotales += (data['precio'] as num).toDouble();
            }
          }
        }

        // LÓGICA DE ESTRELLAS REALES
        String textoPromedio;
        bool tieneCalificaciones = trabajosCalificados > 0;
        
        if (tieneCalificaciones) {
          textoPromedio = (sumaEstrellas / trabajosCalificados).toStringAsFixed(1);
        } else {
          textoPromedio = "Nuevo";
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.bottomRight, 
                children: [
                  CircleAvatar(radius: 50, backgroundColor: _primaryColor.withValues(alpha: 0.1), child: Icon(Icons.person_rounded, size: 60, color: _primaryColor)), 
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!, width: 2)), child: const Icon(Icons.verified, size: 18, color: Colors.blue))
                ]
              ),
              const SizedBox(height: 10),
              Text(nombre, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey[800])),
              Text(especialidad, style: TextStyle(color: Colors.blueGrey[500], fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, Colors.blue[600]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ganancias Totales", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text("Bs. ${gananciasTotales.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(tieneCalificaciones ? Icons.star : Icons.new_releases, color: Colors.amber, size: 18), 
                        const SizedBox(width: 5), 
                        Text(textoPromedio, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      ]),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              Align(alignment: Alignment.centerLeft, child: Text("Historial de Trabajos", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blueGrey[800]))),
              const SizedBox(height: 10),

              if (trabajos.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Text("Aún no has completado trabajos.", style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trabajos.length,
                  itemBuilder: (context, index) {
                    var data = trabajos[index].data() as Map<String, dynamic>;
                    String titulo = data['titulo'] ?? "Servicio";
                    double precio = (data['precio'] as num? ?? 0).toDouble();
                    int? estrellas = data['calificacion'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _successColor.withValues(alpha: 0.1),
                          child: Icon(Icons.monetization_on_rounded, color: _successColor),
                        ),
                        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          children: [
                            if (estrellas != null) ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < estrellas ? Colors.amber : Colors.grey[300])),
                            if (estrellas == null) const Text("Sin calificar", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Text(
                          "Bs. ${precio.toStringAsFixed(0)}", 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _successColor)
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- PANTALLA 4: SCRAPING ---
  final List<Map<String, String>> _ofertasScraped = [];
  bool _cargandoScraping = false;

  Future<void> _iniciarScraping() async {
    setState(() { _cargandoScraping = true; _ofertasScraped.clear(); });
    try {
      final url = Uri.parse('https://trabajito.com.bo/trabajo/location/la-paz'); 
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var titulos = document.querySelectorAll('h4 a');
        for (var elemento in titulos) {
          var titulo = elemento.text.trim();
          var linkRelativo = elemento.attributes['href'] ?? "";
          var linkCompleto = linkRelativo.startsWith("http") ? linkRelativo : "https://trabajito.com.bo$linkRelativo";
          var contenedorPadre = elemento.parent?.parent; 
          var infoAdicional = contenedorPadre?.querySelector('ul')?.text.trim() ?? "Ver detalles en la web";
          infoAdicional = infoAdicional.replaceAll("\n", " • ").replaceAll(RegExp(r'\s+'), ' ');
          if (titulo.isNotEmpty) { setState(() { _ofertasScraped.add({ "titulo": titulo, "empresa": "Fuente: Trabajito.com.bo", "salario": infoAdicional, "link": linkCompleto }); }); }
        }
      }
    } catch (e) { debugPrint("Error: $e"); } finally { if (mounted) setState(() => _cargandoScraping = false); }
  }

  Widget _buildWebScraping() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color: Colors.blueGrey[50], border: Border(bottom: BorderSide(color: Colors.blueGrey[100]!))), 
          child: Row(
            children: [
              const Icon(Icons.public, color: Colors.blueGrey, size: 30), 
              const SizedBox(width: 15), 
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text("Buscador Externo (La Paz)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
                    Text("Ofertas de trabajito.com.bo", style: TextStyle(fontSize: 12, color: Colors.grey))
                  ]
                )
              ), 
              ElevatedButton(
                onPressed: _cargandoScraping ? null : _iniciarScraping, 
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white), 
                child: _cargandoScraping 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("ESCANEAR")
              )
            ]
          )
        ), 
        Expanded(
          child: _ofertasScraped.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.screen_search_desktop_rounded, size: 80, color: Colors.blueGrey[200]), 
                    const SizedBox(height: 10), 
                    const Text("Presiona ESCANEAR para buscar", style: TextStyle(color: Colors.grey))
                  ]
                )
              ) 
            : ListView.builder(
                padding: const EdgeInsets.all(10), 
                itemCount: _ofertasScraped.length, 
                itemBuilder: (context, index) { 
                  var oferta = _ofertasScraped[index]; 
                  return Card(
                    elevation: 1, 
                    margin: const EdgeInsets.only(bottom: 10), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blueGrey[50], child: const Icon(Icons.link, color: Colors.blueGrey)), 
                      title: Text(oferta['titulo']!, style: const TextStyle(fontWeight: FontWeight.bold)), 
                      subtitle: Text("${oferta['salario']}", maxLines: 2, overflow: TextOverflow.ellipsis), 
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey), 
                      onTap: () async { 
                        final Uri url = Uri.parse(oferta['link']!); 
                        if (!await launchUrl(url)) { 
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el enlace"))); 
                        } 
                      }
                    )
                  ); 
                }
              )
        )
      ]
    );
  }
}