import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incoming_sos_provider.dart';
import '../../providers/sos_provider.dart';
import '../contacts/contacts_screen.dart';
import '../sos/sos_screen.dart';
import '../sos/sos_active_screen.dart';
import '../sos/incoming_sos_screen.dart';
import '../sos/sos_history_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomingSosProvider>().startListening();
      context.read<SosProvider>().checkForExistingActiveEvent();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    // Importante: limpiamos el estado en memoria de los providers de SOS
    // ANTES de cerrar sesion, para que la siguiente cuenta que inicie
    // sesion en este mismo dispositivo no herede el evento SOS anterior.
    context.read<SosProvider>().reset();
    context.read<IncomingSosProvider>().stopListening();
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final incomingSosProvider = context.watch<IncomingSosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeWalk'),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppColors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.white,
                      child: Icon(Icons.shield, color: AppColors.blue, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.displayName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.blue),
                title: const Text('Mi perfil'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts_outlined, color: AppColors.blue),
                title: const Text('Contactos de emergencia'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.blue),
                title: const Text('Historial de SOS'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SosHistoryScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.textMuted),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner de alerta entrante: solo aparece si algun contacto
          // que te agrego activo un SOS. Se mantiene en rojo a proposito
          // (color universal de alerta/peligro).
          if (incomingSosProvider.hasIncomingAlert)
            Material(
              color: AppColors.emergencyRed,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IncomingSosScreen(
                        eventId: incomingSosProvider.incomingEvent!.id,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${incomingSosProvider.incomingEvent!.ownerName} necesita ayuda. Toca para ver.',
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Bienvenido, ${authProvider.displayName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu seguridad, siempre contigo.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Consumer<SosProvider>(
                      builder: (context, sosProvider, _) {
                        return Column(
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.emergencyRed,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                ),
                                onPressed: () {
                                  if (sosProvider.hasActiveEvent) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SosActiveScreen()),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SosScreen()),
                                    );
                                  }
                                },
                                child: Text(
                                  sosProvider.hasActiveEvent ? 'SOS\nACTIVO' : 'SOS',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              sosProvider.hasActiveEvent
                                  ? 'Toca para ver tu emergencia activa'
                                  : 'Presiona en caso de emergencia',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.blue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Al activar el SOS se notifica a tus contactos con SafeWalk y podrán ver tu ubicación en tiempo real.',
                            style: TextStyle(color: AppColors.textDark, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.contacts_outlined),
                    label: const Text('Contactos de emergencia'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}