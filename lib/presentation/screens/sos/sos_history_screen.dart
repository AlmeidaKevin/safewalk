import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/sos_event.dart';
import '../../../core/theme/app_theme.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return '';
    final duration = end.difference(start);
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'menos de 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = duration.inHours;
    final remainingMinutes = minutes % 60;
    return '$hours h $remainingMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final dateFormat = DateFormat('d/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de SOS')),
      body: uid == null
          ? const Center(child: Text('No hay sesión activa'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sos_events')
                  .where('ownerId', isEqualTo: uid)
                  .where('status', isEqualTo: 'finished')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No se pudo cargar el historial.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data!.docs
                    .map((doc) => SosEvent.fromFirestore(doc))
                    .toList();

                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Aún no tienes emergencias finalizadas en tu historial.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final duration = _formatDuration(event.createdAt, event.finishedAt);

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.emergencyRed,
                        child: Icon(Icons.sos, color: AppColors.white),
                      ),
                      title: Text(dateFormat.format(event.createdAt)),
                      subtitle: Text(
                        duration.isEmpty
                            ? 'Contactos notificados: ${event.notifiedContactIds.length}'
                            : 'Duración: $duration · Contactos notificados: ${event.notifiedContactIds.length}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      trailing: const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                    );
                  },
                );
              },
            ),
    );
  }
}