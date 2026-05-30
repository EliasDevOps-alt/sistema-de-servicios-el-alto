import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORTANTE: Para identificar al técnico que acepta

class DetalleServicioScreen extends StatelessWidget {
  final String solicitudId;

  const DetalleServicioScreen({super.key, required this.solicitudId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Trabajo Disponible", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Este trabajo ya no está disponible."));
          }

          final datos = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO Y CATEGORÍA
                Text(datos['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Chip(
                  label: Text(datos['categoria'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold)), 
                  backgroundColor: Colors.orange[100],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(),
                ),

                // DESCRIPCIÓN
                const Text("Descripción del problema:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 5),
                Text(datos['descripcion'] ?? 'No hay descripción disponible.', style: const TextStyle(fontSize: 18)),
                
                const SizedBox(height: 20),
                
                // UBICACIÓN
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text("${datos['ubicacion'] ?? 'Ubicación no especificada'}", style: const TextStyle(fontSize: 16))),
                  ],
                ),

                const Spacer(),
                
                // ====================================================================
                // 🛠️ BOTÓN DE ACEPTAR CON CONCURRENCIA CONTROLADA (TRANSACCIÓN)
                // ====================================================================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      // Apuntamos al documento de la solicitud actual
                      final docRef = FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId);

                      try {
                        // Mostramos un indicador de carga rápido en la barra inferior
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Procesando solicitud..."), duration: Duration(milliseconds: 500))
                        );

                        // Iniciamos la transacción segura en Firestore
                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                          DocumentSnapshot freshSnapshot = await transaction.get(docRef);

                          if (!freshSnapshot.exists) {
                            throw Exception("La solicitud ya no existe.");
                          }

                          final datosSolicitud = freshSnapshot.data() as Map<String, dynamic>;

                          // 1. Verificamos si sigue disponible
                          if (datosSolicitud['estado'] == 'pendiente') {
                            // 2. Si está libre, este técnico gana el trabajo
                            transaction.update(docRef, {
                              'estado': 'aceptado',
                              'tecnico_uid': user.uid,
                              'tecnico_email': user.email ?? 'tecnico@gmail.com',
                            });
                          } else {
                            // 3. Si ya cambió de estado, rebota al segundo técnico
                            throw Exception("¡Demasiado tarde! Otro técnico ya aceptó este trabajo.");
                          }
                        });

                        // Éxito: notificamos y sacamos al técnico de esta pantalla
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🎉 ¡Excelente! El trabajo ahora es tuyo."), backgroundColor: Colors.green)
                        );
                        Navigator.pop(context);

                      } catch (e) {
                        // Error o rebote de competencia
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll("Exception:", "")), backgroundColor: Colors.orange)
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: const Text("ACEPTAR TRABAJO", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}