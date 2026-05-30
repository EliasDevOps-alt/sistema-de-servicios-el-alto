import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Lista simulada de técnicos pendientes de aprobación
  final List<Map<String, String>> _solicitudesPendientes = [
    {
      "nombre": "Juan Pérez",
      "especialidad": "Electricista",
      "fecha": "27 Ene, 14:00",
      "estado": "Pendiente"
    },
    {
      "nombre": "Maria Choque",
      "especialidad": "Plomería",
      "fecha": "27 Ene, 10:30",
      "estado": "Pendiente"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Fondo sobrio tipo "Sistema"
      appBar: AppBar(
        title: const Text("Panel Administrativo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900], // Color oscuro de autoridad
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Text("A", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          // 1. BARRA LATERAL (SIDEBAR) - Típico de paneles web
          if (MediaQuery.of(context).size.width > 600) // Solo en pantallas grandes/web
            Container(
              width: 250,
              color: Colors.white,
              child: ListView(
                children: [
                  _buildMenuItem(Icons.dashboard, "Inicio", true),
                  _buildMenuItem(Icons.people_alt, "Usuarios", false),
                  _buildMenuItem(Icons.verified_user, "Validaciones", false, badge: _solicitudesPendientes.length),
                  _buildMenuItem(Icons.monetization_on, "Finanzas", false),
                  _buildMenuItem(Icons.settings, "Configuración", false),
                ],
              ),
            ),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Validación de Técnicos", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 5),
                  const Text("Revisa los documentos y antecedentes antes de aprobar.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  // TARJETAS DE SOLICITUD
                  Expanded(
                    child: _solicitudesPendientes.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _solicitudesPendientes.length,
                        itemBuilder: (context, index) {
                          return _buildSolicitudCard(_solicitudesPendientes[index], index);
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, String> solicitud, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO Y DATOS
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person, color: Colors.orange[800], size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(solicitud["nombre"]!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Postula para: ${solicitud["especialidad"]}", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Documentos: Carnet.pdf, Antecedentes.pdf, Titulo.jpg", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            // BOTONES DE ACCIÓN
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Simular aprobación
                    setState(() {
                      _solicitudesPendientes.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Técnico Aprobado Exitosamente")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("APROBAR"),
                ),
                const SizedBox(height: 5),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("RECHAZAR"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isActive, {int? badge}) {
    return Container(
      color: isActive ? Colors.blueGrey[50] : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.blueGrey[900] : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.blueGrey[900] : Colors.grey[700])),
        trailing: badge != null && badge > 0 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(badge.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ) 
          : null,
        onTap: () {},
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
          const SizedBox(height: 20),
          const Text("¡Todo al día!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("No hay solicitudes pendientes de revisión.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}