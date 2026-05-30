import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisTrabajosTecnicoScreen extends StatelessWidget {
  const MisTrabajosTecnicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mis Trabajos Ganados", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('tecnico_uid', isEqualTo: user?.uid) // ✔️ CORREGIDO AQUÍ
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no has aceptado ningún trabajo."));
          }

          final trabajos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: trabajos.length,
            itemBuilder: (context, index) {
              final doc = trabajos[index];
              final datos = doc.data() as Map<String, dynamic>;
              final estado = datos['estado'] ?? 'aceptado';

              return Card(
                margin: const EdgeInsets.only(bottom: 15), // ✔️ CORREGIDO AQUÍ
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✔️ CORREGIDO AQUÍ
                        children: [
                          Text("Categoría: ${datos['categoria']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Chip(
                            label: Text(estado.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: estado == 'completado' ? Colors.green : Colors.blue,
                          ),
                        ],
                      ),
                      Text(datos['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Descripción: ${datos['descripcion']}"),
                      const SizedBox(height: 5),
                      Text("📍 Dirección: ${datos['ubicacion']}", style: const TextStyle(color: Colors.redAccent)),
                      const Divider(height: 25),
                      
                      if (estado == 'aceptado')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('solicitudes')
                                  .doc(doc.id)
                                  .update({'estado': 'completado'});

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("✅ Trabajo marcado como Completado"), backgroundColor: Colors.green)
                              );
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("TERMINAR TRABAJO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        )
                      else
                        const Center(
                          child: Text("🎉 ¡Ya finalizaste este servicio!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )
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