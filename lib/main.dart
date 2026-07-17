import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/contacts_provider.dart';
import 'presentation/providers/sos_provider.dart';
import 'presentation/providers/incoming_sos_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Mantiene visible el splash nativo hasta que lo quitemos manualmente,
  // en vez de que desaparezca apenas se dibuje el primer frame de Flutter.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SafeWalkApp());

  // Duracion minima garantizada del splash: 3 segundos, sin importar
  // que tan rapido haya terminado la inicializacion de arriba.
  await Future.delayed(const Duration(seconds: 3));
  FlutterNativeSplash.remove();
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => IncomingSosProvider()),
      ],
      child: MaterialApp(
        title: 'SafeWalk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide que pantalla mostrar segun si hay sesion activa o no.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoggedIn) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}