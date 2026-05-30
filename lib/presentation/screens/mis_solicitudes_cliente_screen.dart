import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisSolicitudesClienteScreen extends StatelessWidget {
  const MisSolicitudesClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mis Solicitudes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('cliente_uid', isEqualTo: user?.uid) // ✔️ CORREGIDO AQUÍ
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no has realizado ninguna solicitud."));
          }

          final solicitudes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final datos = solicitudes[index].data() as Map<String, dynamic>;
              final estado = datos['estado'] ?? 'pendiente';

              Color colorEstado = Colors.orange;
              if (estado == 'aceptado') colorEstado = Colors.blue;
              if (estado == 'completado') colorEstado = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 15), // ✔️ CORREGIDO AQUÍ
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✔️ CORREGIDO AQUÍ
                        children: [
                          Text(datos['categoria'] ?? 'General', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorEstado.withValues(alpha: 0.1), // ✔️ CORREGIDO AQUÍ
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(datos['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(datos['descripcion'] ?? '', style: TextStyle(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Divider(height: 20),
                      if (estado == 'aceptado')
                        Row(
                          children: [
                            const Icon(Icons.engineering, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Técnico asignado: ${datos['tecnico_email']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          ],
                        )
                      else if (estado == 'completado')
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text("Trabajo finalizado con éxito", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text("Esperando técnicos disponibles...", style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}