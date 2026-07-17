import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/sos_event.dart';

class SosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SosEvent? _activeEvent;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<DocumentSnapshot>? _eventSubscription;
  StreamSubscription<Position>? _positionSubscription;

  SosEvent? get activeEvent => _activeEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveEvent => _activeEvent != null && _activeEvent!.isActive;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    return user.uid;
  }

  bool _hasCheckedExisting = false;

  /// Limpia todo el estado en memoria. Debe llamarse al cerrar sesion,
  /// para que la siguiente cuenta que inicie sesion no herede el
  /// evento SOS de la cuenta anterior.
  void reset() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeEvent = null;
    _isLoading = false;
    _errorMessage = null;
    _hasCheckedExisting = false;
    notifyListeners();
  }

  /// Verifica si el usuario ya tiene un evento SOS propio activo (por ejemplo
  /// si la app se cerro de golpe sin presionar "Finalizar"), y si existe,
  /// reconecta los listeners como si acabara de crearlo.
  /// Se debe llamar al abrir el Home, una sola vez por sesion.
  Future<void> checkForExistingActiveEvent() async {
    if (_hasCheckedExisting) return;
    _hasCheckedExisting = true;

    try {
      final snapshot = await _firestore
          .collection('sos_events')
          .where('ownerId', isEqualTo: _uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final eventId = snapshot.docs.first.id;
        _activeEvent = SosEvent.fromFirestore(snapshot.docs.first);
        _listenToEvent(eventId);
        _startLocationUpdates(eventId);
        notifyListeners();
      }
    } catch (e) {
      // Si falla (por ejemplo sin conexion), simplemente no reconectamos;
      // el usuario puede iniciar un SOS nuevo normalmente.
    }
  }

  /// Inicia una emergencia: pide permisos de ubicacion, obtiene la posicion
  /// actual, resuelve los contactos que tienen SafeWalk, y crea el documento.
  Future<bool> startSos() async {
    // Idempotencia: si ya hay un SOS activo (propio), NUNCA creamos uno
    // nuevo -- simplemente confirmamos que ya existe. Esto evita
    // duplicados si el usuario presiona el boton mas de una vez.
    if (hasActiveEvent) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        _errorMessage = 'Permiso de ubicación denegado';
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition();
      final ownerName = _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Usuario';

      // Contactos que tienen cuenta en SafeWalk (linkedUserId != null)
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('contacts')
          .where('linkedUserId', isNull: false)
          .get();

      final notifiedContactIds = contactsSnapshot.docs
          .map((doc) => doc.data()['linkedUserId'] as String)
          .toList();

      final newEvent = SosEvent(
        id: '',
        ownerId: _uid,
        ownerName: ownerName,
        status: SosStatus.active,
        location: GeoPoint(position.latitude, position.longitude),
        notifiedContactIds: notifiedContactIds,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('sos_events').add(newEvent.toCreateMap());

      // Marcamos el evento como activo de inmediato en memoria, sin esperar
      // a que llegue la primera actualizacion del listener de Firestore
      // (eso podria tardar y dejar la UI en un estado inconsistente).
      _activeEvent = SosEvent(
        id: docRef.id,
        ownerId: newEvent.ownerId,
        ownerName: newEvent.ownerName,
        status: SosStatus.active,
        location: newEvent.location,
        notifiedContactIds: newEvent.notifiedContactIds,
        createdAt: newEvent.createdAt,
      );

      _listenToEvent(docRef.id);
      _startLocationUpdates(docRef.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'No se pudo iniciar el SOS';
      debugPrint('Error en startSos: $e');
      notifyListeners();
      return false;
    }
  }

  void _listenToEvent(String eventId) {
    _eventSubscription?.cancel();
    _eventSubscription = _firestore
        .collection('sos_events')
        .doc(eventId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _activeEvent = SosEvent.fromFirestore(doc);
        notifyListeners();

        if (!_activeEvent!.isActive) {
          _stopLocationUpdates();
        }
      }
    });
  }

  void _startLocationUpdates(String eventId) {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metros minimos antes de emitir una nueva posicion
      ),
    ).listen((position) {
      _firestore.collection('sos_events').doc(eventId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> finishSos() async {
    if (_activeEvent == null) return;

    await _firestore.collection('sos_events').doc(_activeEvent!.id).update({
      'status': 'finished',
      'finishedAt': FieldValue.serverTimestamp(),
    });

    _stopLocationUpdates();
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _activeEvent = null;
    notifyListeners();
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}