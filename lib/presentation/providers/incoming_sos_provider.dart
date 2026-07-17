import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/sos_event.dart';

/// Escucha en tiempo real si el usuario actual aparece como contacto
/// notificado en algun evento SOS activo (de otra persona).
class IncomingSosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _subscription;
  SosEvent? _incomingEvent;

  SosEvent? get incomingEvent => _incomingEvent;
  bool get hasIncomingAlert => _incomingEvent != null;

  void startListening() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _subscription?.cancel();
    _subscription = _firestore
        .collection('sos_events')
        .where('notifiedContactIds', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          // Tomamos el mas reciente si hubiera mas de uno.
          _incomingEvent = SosEvent.fromFirestore(snapshot.docs.first);
        } else {
          _incomingEvent = null;
        }
        notifyListeners();
      },
      onError: (error) {
        // Esto normalmente indica que falta crear un indice compuesto en
        // Firestore. El error trae un link directo para crearlo.
        debugPrint('Error escuchando SOS entrantes: $error');
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _incomingEvent = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}