import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/emergency_contact.dart';

class ContactsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmergencyContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _firestore.collection('users').doc(_uid).collection('contacts');

  /// Escucha los contactos en tiempo real. Llamar una vez, por ejemplo
  /// en initState de la pantalla de contactos.
  void listenToContacts() {
    _contactsRef.orderBy('createdAt', descending: true).snapshots().listen(
      (snapshot) {
        _contacts = snapshot.docs
            .map((doc) => EmergencyContact.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Error al cargar contactos';
        notifyListeners();
      },
    );
  }

  Future<bool> addContact({
    required String name,
    required String phone,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Buscamos si ese email pertenece a un usuario registrado en SafeWalk.
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      final String? linkedUserId = query.docs.isNotEmpty ? query.docs.first.id : null;

      await _contactsRef.add({
        'name': name.trim(),
        'phone': phone.trim(),
        'email': normalizedEmail,
        'linkedUserId': linkedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'No se pudo agregar el contacto';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      await _contactsRef.doc(contactId).delete();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar el contacto';
      notifyListeners();
      return false;
    }
  }
}