import 'package:cloud_firestore/cloud_firestore.dart';

enum SosStatus { active, finished }

class SosEvent {
  final String id;
  final String ownerId;
  final String ownerName;
  final SosStatus status;
  final GeoPoint? location;
  final DateTime? locationUpdatedAt;
  final List<String> notifiedContactIds;
  final DateTime createdAt;
  final DateTime? finishedAt;

  SosEvent({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    this.location,
    this.locationUpdatedAt,
    required this.notifiedContactIds,
    required this.createdAt,
    this.finishedAt,
  });

  bool get isActive => status == SosStatus.active;

  factory SosEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosEvent(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      status: (data['status'] == 'finished') ? SosStatus.finished : SosStatus.active,
      location: data['location'],
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      notifiedContactIds: List<String>.from(data['notifiedContactIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': 'active',
      'location': location,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'notifiedContactIds': notifiedContactIds,
      'createdAt': FieldValue.serverTimestamp(),
      'finishedAt': null,
    };
  }
}