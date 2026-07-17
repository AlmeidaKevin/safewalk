import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sos_provider.dart';
import 'sos_active_screen.dart';
import '../../../core/theme/app_theme.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  Future<void> _confirmAndStartSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Activar SOS?'),
        content: const Text(
          'Se compartirá tu ubicación en tiempo real con tus contactos de emergencia que tengan SafeWalk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Activar SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final sosProvider = context.read<SosProvider>();
    final success = await sosProvider.startSos();

    if (success && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SosActiveScreen()),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sosProvider.errorMessage ?? 'No se pudo activar el SOS')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = context.watch<SosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'En caso de emergencia, presiona el botón.\nSe notificará a tus contactos con SafeWalk\ny podrán ver tu ubicación en tiempo real.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 200,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    shape: const CircleBorder(),
                  ),
                  onPressed: sosProvider.isLoading ? null : () => _confirmAndStartSos(context),
                  child: sosProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SOS',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}