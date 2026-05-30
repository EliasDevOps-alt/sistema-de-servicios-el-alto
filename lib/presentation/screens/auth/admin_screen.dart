import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrativo"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // BOTÓN DE PERFIL DEL ADMIN
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.indigo),
            ),
            onPressed: () {
              _mostrarPerfilAdmin(context);
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Validación de Técnicos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // TARJETA DE TÉCNICO PENDIENTE
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Beymar Condori", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Solicitud: Electricista", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: const Text("PENDIENTE", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.badge, color: Colors.indigo),
                    title: Text("Carnet de Identidad"),
                    subtitle: Text("1234567 LP"),
                    trailing: Icon(Icons.visibility, color: Colors.grey),
                  ),
                  const ListTile(
                    leading: Icon(Icons.security, color: Colors.indigo),
                    title: Text("Antecedentes FELCC"),
                    subtitle: Text("Sin antecedentes penales"),
                    trailing: Icon(Icons.check_circle, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){}, 
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text("RECHAZAR")
                        )
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){}, 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text("APROBAR")
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CORRECCIÓN DEL OVERFLOW AQUÍ ---
  void _mostrarPerfilAdmin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que se ajuste mejor al teclado o contenido largo
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ESTO ES CLAVE: Se encoge al tamaño del contenido
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              
              const CircleAvatar(radius: 40, backgroundColor: Colors.indigo, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Administrador Principal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("admin@servicioselalto.com", style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 30),
              
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text("Cambiar Contraseña"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Ver Logs del Sistema"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              
              const SizedBox(height: 30), // Espacio fijo en vez de Spacer()
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst); // Cerrar sesión
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("CERRAR SESIÓN"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, 
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15) // Botón más alto para que sea fácil tocar
                  ),
                ),
              ),
              
              const SizedBox(height: 10), // Un pequeño margen abajo
            ],
          ),
        );
      },
    );
  }
}