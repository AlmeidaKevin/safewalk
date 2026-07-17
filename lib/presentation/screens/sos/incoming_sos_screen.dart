import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../data/models/sos_event.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/theme/app_theme.dart';

class IncomingSosScreen extends StatefulWidget {
  final String eventId;

  const IncomingSosScreen({super.key, required this.eventId});

  @override
  State<IncomingSosScreen> createState() => _IncomingSosScreenState();
}

class _IncomingSosScreenState extends State<IncomingSosScreen> {
  final _messageController = TextEditingController();
  final _mapController = MapController();
  latlong.LatLng? _lastCenteredOn;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
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
        .doc(widget.eventId)
        .collection('messages')
        .add(message.toMap());

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerta SOS'),
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_events')
            .doc(widget.eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = SosEvent.fromFirestore(snapshot.data!);

          if (!event.isActive) {
            // El dueño finalizo la emergencia -> regresamos automaticamente.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) Navigator.of(context).pop();
            });
            return const Center(child: Text('Esta emergencia ha finalizado'));
          }

          final center = event.location != null
              ? latlong.LatLng(event.location!.latitude, event.location!.longitude)
              : const latlong.LatLng(0, 0);

          // Sigue automaticamente la ubicacion del dueño del SOS,
          // recentrando la camara cada vez que se mueve.
          if (_lastCenteredOn == null || _lastCenteredOn != center) {
            _lastCenteredOn = center;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _mapController.move(center, _mapController.camera.zoom);
              } catch (_) {
                // El mapa puede no estar listo todavia en el primer frame.
              }
            });
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.emergencyRed.withOpacity(0.08),
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${event.ownerName} necesita ayuda',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
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
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const Divider(height: 1),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('sos_events')
                            .doc(widget.eventId)
                            .collection('messages')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, msgSnapshot) {
                          if (!msgSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messages = msgSnapshot.data!.docs
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
                              final isMine =
                                  msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                              return Align(
                                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}