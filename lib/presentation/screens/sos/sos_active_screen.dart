import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../providers/sos_provider.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/theme/app_theme.dart';

class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> {
  final _messageController = TextEditingController();
  final _mapController = MapController();
  latlong.LatLng? _lastCenteredOn;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String eventId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      id: '',
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'Usuario',
      text: text,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('sos_events')
        .doc(eventId)
        .collection('messages')
        .add(message.toMap());

    _messageController.clear();
  }

  Future<void> _confirmAndFinishSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Finalizar SOS?'),
        content: const Text('Se dejará de compartir tu ubicación y el chat se cerrará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SosProvider>().finishSos();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = context.watch<SosProvider>();
    final event = sosProvider.activeEvent;

    if (event == null) {
      // El evento ya se cerro (por ejemplo desde otro dispositivo) -> regresamos.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final center = event.location != null
        ? latlong.LatLng(event.location!.latitude, event.location!.longitude)
        : const latlong.LatLng(0, 0);

    // Si la ubicacion cambio desde el ultimo build, movemos la camara
    // del mapa automaticamente para seguir el punto, sin que el usuario
    // tenga que desplazarlo manualmente.
    if (_lastCenteredOn == null || _lastCenteredOn != center) {
      _lastCenteredOn = center;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(center, _mapController.camera.zoom);
        } catch (_) {
          // El mapa puede no estar listo todavia en el primer frame; se ignora.
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS activo'),
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _confirmAndFinishSos(context),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa con la ubicacion en tiempo real
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safewalk',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.emergencyRed, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat de emergencia
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sos_events')
                        .doc(event.id)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs
                          .map((doc) => ChatMessage.fromFirestore(doc))
                          .toList();

                      if (messages.isEmpty) {
                        return const Center(child: Text('Aún no hay mensajes'));
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMine = msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMine ? AppColors.greenLight : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.senderName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(msg.text),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(event.id),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendMessage(event.id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}