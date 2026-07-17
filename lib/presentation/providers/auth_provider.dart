import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _displayName;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
      if (user != null) {
        _ensureUserProfile(user);
        _saveFcmToken(user.uid);
        _listenToDisplayName(user.uid);
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _displayName = null;
      }
    });

    // Si Firebase le asigna un token nuevo al dispositivo mientras hay
    // sesion activa, lo actualizamos tambien.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final uid = _user?.uid;
      if (uid != null) {
        _firestore.collection('users').doc(uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      }
    });
  }

  /// Escucha en tiempo real el nombre del perfil, para que el saludo
  /// en el Home se actualice apenas el usuario lo cambie en su perfil.
  void _listenToDisplayName(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        _displayName = doc.data()?['name'];
        notifyListeners();
      },
      onError: (e) => debugPrint('Error escuchando nombre de perfil: $e'),
    );
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  /// Nombre para mostrar en saludos. Si aun no ha cargado el nombre
  /// del perfil (o el usuario no lo ha llenado), cae de vuelta al email.
  String get displayName => (_displayName != null && _displayName!.trim().isNotEmpty)
      ? _displayName!
      : (_user?.email ?? '');

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Guardamos el perfil basico en Firestore para poder
      // buscarlo despues por email al agregar contactos.
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': '',
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Trae los datos del perfil (nombre, telefono) desde Firestore.
  /// Se usa en la pantalla de perfil para precargar los campos.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = _user?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Actualiza nombre y telefono en Firestore. El email no se puede
  /// cambiar aqui porque es el mismo que se usa para iniciar sesion.
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final uid = _user?.uid;
    if (uid == null) return false;

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'name': name.trim(),
          'phone': phone.trim(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      return false;
    }
  }

  /// Garantiza que el documento del usuario en Firestore tenga al menos
  /// el campo 'email', sin importar si la cuenta se creo via el registro
  /// de la app o directamente desde la consola de Firebase (donde ese
  /// documento nunca se llega a crear con los datos completos).
  /// Esto es clave porque la busqueda de contactos depende de este campo.
  Future<void> _ensureUserProfile(User user) async {
    if (user.email == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'email': user.email!.trim().toLowerCase()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error asegurando perfil de usuario: $e');
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      // En Android 13+ y iOS es necesario pedir permiso explicito
      // para poder mostrar notificaciones.
      await FirebaseMessaging.instance.requestPermission();

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Usamos set + merge (no update) porque este metodo puede ejecutarse
        // antes de que el documento del usuario termine de crearse en register().
        await _firestore.collection('users').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Error guardando fcmToken: $e');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      default:
        return 'Ocurrió un error. Intenta de nuevo.';
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}