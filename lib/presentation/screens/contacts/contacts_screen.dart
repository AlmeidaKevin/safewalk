import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/contacts_provider.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../core/theme/app_theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Se activa la escucha en tiempo real una sola vez.
    context.read<ContactsProvider>().listenToContacts();
  }

  Future<void> _callContact(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el marcador telefónico')),
      );
    }
  }

  void _showAddContactSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nuevo contacto de emergencia',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final contactsProvider = context.read<ContactsProvider>();
                    final success = await contactsProvider.addContact(
                      name: nameController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                    );

                    if (success && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: const Text('Guardar contacto'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de emergencia')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactSheet,
        child: const Icon(Icons.person_add_alt),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estos contactos serán notificados si activas el SOS. El icono verde indica que ya tienen SafeWalk.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: contactsProvider.contacts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Aún no tienes contactos de emergencia.\nToca + para agregar uno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: contactsProvider.contacts.length,
                    itemBuilder: (context, index) {
                final EmergencyContact contact = contactsProvider.contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (contact.isAppUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: 'Tiene SafeWalk',
                            child: Icon(Icons.verified, color: AppColors.green, size: 20),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.green),
                        tooltip: 'Llamar',
                        onPressed: () => _callContact(context, contact.phone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context.read<ContactsProvider>().deleteContact(contact.id),
                      ),
                    ],
                  ),
                );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}