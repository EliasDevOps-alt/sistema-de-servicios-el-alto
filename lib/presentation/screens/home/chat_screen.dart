import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';     

class ChatScreen extends StatefulWidget {
  final String nombreTecnico; 
  final String receptorId; // <--- NUEVO Y VITAL: El UID de la otra persona
  
  const ChatScreen({super.key, required this.nombreTecnico, required this.receptorId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final String _miId = FirebaseAuth.instance.currentUser!.uid;

  // --- EL CEREBRO DEL CHAT PRIVADO ---
  // Genera un ID de sala único y exacto para estos dos usuarios
  String get _chatRoomId {
    List<String> ids = [_miId, widget.receptorId];
    ids.sort(); // Lo ordenamos alfabéticamente para que siempre sea igual sin importar quién escriba primero
    return ids.join("_"); // Resultado ej: "UID1_UID2"
  }

  Color get _myColor {
    if (widget.nombreTecnico.contains("(Cliente)")) {
       return Colors.orange[800]!; 
    } else {
       return Colors.blue[800]!;   
    }
  }

  // --- FUNCIÓN PARA ENVIAR A LA SALA PRIVADA ---
  void _enviarMensaje() {
    if (_textController.text.trim().isEmpty) return;

    // Guardamos dentro de chat_rooms -> [ID_SALA] -> mensajes
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_chatRoomId)
        .collection('mensajes')
        .add({
      'texto': _textController.text.trim(),
      'sender_id': _miId, 
      'email': FirebaseAuth.instance.currentUser!.email,
      'fecha': FieldValue.serverTimestamp(), 
    });

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _myColor.withOpacity(0.1),
              radius: 20,
              child: Icon(Icons.person, color: _myColor), // Foto genérica sin hardcodear internet
            ),
            const SizedBox(width: 10),
            Expanded( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nombreTecnico, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Text("Chat Seguro", style: TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. LISTA DE MENSAJES (AISLADA EN LA SALA PRIVADA)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(_chatRoomId) // <--- SOLO LEE LOS MENSAJES DE ESTA SALA
                  .collection('mensajes')
                  .orderBy('fecha', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Sin mensajes. ¡Inicia la conversación!", style: TextStyle(color: Colors.grey))
                  );
                }

                var mensajes = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.all(20),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    var data = mensajes[index].data() as Map<String, dynamic>;
                    bool esMio = data['sender_id'] == _miId;

                    // Formateo dinámico de hora
                    String horaTexto = "";
                    if (data['fecha'] != null) {
                      DateTime fecha = (data['fecha'] as Timestamp).toDate();
                      horaTexto = "${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
                    }

                    return _buildBurbujaMensaje(data['texto'] ?? '', esMio, horaTexto);
                  },
                );
              },
            ),
          ),

          // 2. INPUT PARA ESCRIBIR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: _myColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _enviarMensaje, 
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurbujaMensaje(String texto, bool esMio, String hora) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: esMio ? _myColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: esMio ? const Radius.circular(15) : Radius.zero,
            bottomRight: esMio ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              texto, 
              style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 15)
            ),
            const SizedBox(height: 4),
            Text(
              hora, 
              style: TextStyle(color: esMio ? Colors.white70 : Colors.grey, fontSize: 10)
            ),
          ],
        ),
      ),
    );
  }
}