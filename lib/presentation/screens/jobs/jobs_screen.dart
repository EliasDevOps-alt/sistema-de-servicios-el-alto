import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';     
import '../home/chat_screen.dart'; 

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _miId = FirebaseAuth.instance.currentUser!.uid;

  final Color _clientBlue = Colors.blue[900]!; 
  final Color _accentColor = Colors.amberAccent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- DIÁLOGOS DE ACCIÓN ---

  void _confirmarCancelacion(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Cancelar Solicitud", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas cancelar esta solicitud? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("NO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({
                'estado': 'cancelado'
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud cancelada"), backgroundColor: Colors.red));
              }
            },
            child: const Text("SÍ, CANCELAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(String docId, String tituloActual, String descActual) {
    TextEditingController tituloCtrl = TextEditingController(text: tituloActual);
    TextEditingController descCtrl = TextEditingController(text: descActual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Editar Solicitud", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(labelText: "Título breve", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Descripción del problema", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _clientBlue),
              onPressed: () async {
                if (tituloCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                
                await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({
                  'titulo': tituloCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim(),
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solicitud actualizada"), backgroundColor: Colors.green));
                }
              },
              child: const Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  // --- DIÁLOGO DE CALIFICACIÓN ---
  void _mostrarDialogoCalificar(String docId, String tecnicoUid) {
    int estrellas = 5;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Califica el servicio", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("¿Qué tal estuvo el trabajo?", textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < estrellas ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStateDialog(() => estrellas = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text("$estrellas Estrellas", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('solicitudes').doc(docId).update({
                      'calificacion': estrellas,
                      'estado_calificacion': 'calificado'
                    });
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("¡Gracias por calificar!"), backgroundColor: Colors.green)
                      );
                    }
                  },
                  child: const Text("ENVIAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Mis Solicitudes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _clientBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 5,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: _accentColor,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "EN CURSO"),
            Tab(text: "HISTORIAL"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaConectada(activos: true),
          _buildListaConectada(activos: false),
        ],
      ),
    );
  }

  Widget _buildListaConectada({required bool activos}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where('cliente_uid', isEqualTo: _miId)
          .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(activos ? Icons.search_off : Icons.history, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  activos ? "No tienes solicitudes activas" : "No tienes historial", 
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)
                ),
              ],
            ),
          );
        }

        var documentos = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String estado = data['estado'] ?? 'pendiente';
          
          if (activos) {
            return ['pendiente', 'aceptado', 'en_proceso'].contains(estado);
          } else {
            return ['finalizado', 'cancelado'].contains(estado);
          }
        }).toList();

        documentos.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;

          Timestamp t1 = (dataA['fecha'] is Timestamp) ? dataA['fecha'] : Timestamp.now();
          Timestamp t2 = (dataB['fecha'] is Timestamp) ? dataB['fecha'] : Timestamp.now();
          
          return t2.compareTo(t1); 
        });

        if (documentos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(activos ? Icons.search_off : Icons.history, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  activos ? "No tienes solicitudes activas" : "No tienes historial", 
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            var doc = documentos[index];
            var data = doc.data() as Map<String, dynamic>;
            String estado = data['estado'] ?? 'pendiente';

            String fechaTexto = "Hace un momento";
            if (data['fecha'] is Timestamp) {
              DateTime fechaDateTime = (data['fecha'] as Timestamp).toDate();
              fechaTexto = "${fechaDateTime.day}/${fechaDateTime.month}/${fechaDateTime.year} ${fechaDateTime.hour}:${fechaDateTime.minute.toString().padLeft(2, '0')}";
            }

            if (estado == 'pendiente') {
              return _buildActiveJobCard(
                docId: doc.id,
                descripcion: data['descripcion'] ?? "",
                estadoRaw: estado,
                titulo: data['titulo'] ?? "Solicitud",
                estado: "Buscando Técnico...",
                colorEstado: Colors.orange[800]!,
                fondoEstado: Colors.orange[50]!,
                iconEstado: Icons.radar_rounded,
                fecha: fechaTexto,
                ubicacion: data['ubicacion'] ?? "Ubicación sin referencia",
                isLoading: true,
              );
            } else if (estado == 'aceptado' || estado == 'en_proceso') {
              return _buildActiveJobCard(
                docId: doc.id,
                descripcion: data['descripcion'] ?? "",
                estadoRaw: estado,
                titulo: data['titulo'] ?? "Servicio",
                estado: estado == 'aceptado' ? "Técnico en Camino" : "Trabajo en Proceso",
                colorEstado: Colors.blue[800]!,
                fondoEstado: Colors.blue[50]!,
                iconEstado: estado == 'aceptado' ? Icons.directions_car : Icons.handyman,
                fecha: fechaTexto,
                ubicacion: data['ubicacion'] ?? "-",
                tecnico: data['tecnico_email'] ?? "Profesional Asignado",
                rolTecnico: data['tecnico_especialidad'] ?? "Técnico General",
                receptorId: data['tecnico_uid'], 
                chatHabilitado: true,
              );
            } else {
              int? calificacion = data['calificacion']; 
              
              return _buildHistoryCard(
                docId: doc.id,
                titulo: data['titulo'] ?? "Servicio",
                fecha: fechaTexto,
                tecnico: data['tecnico_email'] ?? "Técnico Anónimo",
                tecnicoUid: data['tecnico_uid'] ?? "",
                precio: data['precio'] != null ? "Bs. ${data['precio']}" : "Precio no fijado", 
                estado: estado.toUpperCase(),
                colorEstado: estado == 'finalizado' ? Colors.green[700]! : Colors.red[700]!,
                calificacion: calificacion ?? 0, 
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActiveJobCard({
    required String docId,
    required String descripcion,
    required String estadoRaw,
    required String titulo,
    required String estado,
    required Color colorEstado,
    required Color fondoEstado,
    required IconData iconEstado,
    required String fecha,
    required String ubicacion,
    String? tecnico,
    String? rolTecnico,
    String? receptorId, 
    bool isLoading = false,
    bool chatHabilitado = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colorEstado, width: 6)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              color: fondoEstado,
              child: Row(
                children: [
                  Icon(iconEstado, color: colorEstado, size: 22),
                  const SizedBox(width: 10),
                  Text(estado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.w900, fontSize: 15)),
                  if (isLoading) ...[
                    const Spacer(),
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorEstado)),
                  ]
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(fecha, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: _clientBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(ubicacion, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                    ],
                  ),
                  if (tecnico != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))]
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: _clientBlue.withOpacity(0.1), radius: 22, child: Icon(Icons.person, color: _clientBlue)),
                          const SizedBox(width: 12),
                          Expanded( 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tecnico, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 1),
                                Text(rolTecnico ?? "Técnico", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ),
                          ),
                          if (chatHabilitado)
                            CircleAvatar(
                              backgroundColor: _clientBlue.withOpacity(0.1), 
                              radius: 20, 
                              child: IconButton( 
                                icon: Icon(Icons.message, color: _clientBlue, size: 20),
                                onPressed: () {
                                  if (receptorId != null && receptorId.isNotEmpty) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                      nombreTecnico: tecnico, 
                                      receptorId: receptorId, 
                                    )));
                                  }
                                },
                                padding: EdgeInsets.zero, 
                              )
                            ),
                        ],
                      ),
                    )
                  ],

                  // ===============================================
                  // SECCIÓN CORREGIDA: LÓGICA DE CANCELACIÓN
                  // ===============================================
                  if (estadoRaw == 'pendiente') ...[
                    const SizedBox(height: 15),
                    const Divider(height: 1, thickness: 1),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _mostrarDialogoEditar(docId, titulo, descripcion), 
                            icon: Icon(Icons.edit, color: _clientBlue, size: 18), 
                            label: Text("EDITAR", style: TextStyle(color: _clientBlue, fontWeight: FontWeight.bold))
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _confirmarCancelacion(docId), 
                            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 18), 
                            label: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                          ),
                        ),
                      ],
                    )
                  ] else if (estadoRaw == 'aceptado' || estadoRaw == 'en_proceso') ...[
                    // Si el técnico ya aceptó, bloqueamos la cancelación rápida para proteger al trabajador
                    const SizedBox(height: 15),
                    const Divider(height: 1, thickness: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: double.infinity,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange[800], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "El técnico ya está en camino. Si necesitas cancelar urgentemente, comunícate con él usando el botón de chat arriba.",
                              style: TextStyle(color: Colors.orange[900], fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String docId,
    required String titulo,
    required String fecha,
    required String tecnico,
    required String tecnicoUid,
    required String precio,
    required String estado,
    required Color colorEstado,
    required int calificacion,
  }) {
    bool yaCalificado = calificacion > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Container(
        decoration: BoxDecoration(
           border: Border(right: BorderSide(color: colorEstado, width: 6)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(precio, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorEstado, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(estado, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          tecnico, 
                          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (yaCalificado)
                  Row(
                    children: List.generate(5, (index) => Icon(
                      Icons.star_rounded, 
                      size: 18, 
                      color: index < calificacion ? Colors.amber : Colors.grey[300]
                    )),
                  )
                else if (estado == 'FINALIZADO')
                  SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => _mostrarDialogoCalificar(docId, tecnicoUid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12), 
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: const Text("CALIFICAR"),
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}