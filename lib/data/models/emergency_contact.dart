import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? linkedUserId; // null si el email no coincide con ningún usuario de SafeWalk
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.linkedUserId,
    required this.createdAt,
  });

  bool get isAppUser => linkedUserId != null;

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      linkedUserId: data['linkedUserId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'linkedUserId': linkedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}