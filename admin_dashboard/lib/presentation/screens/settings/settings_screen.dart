import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/admin_sidebar.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/settings'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(context, 'Profil', [
                        _buildCard(context, [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(authState.user?.fullName.substring(0, 1).toUpperCase() ?? 'A', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                            title: Text(authState.user?.fullName ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text(authState.user?.email ?? ''),
                            trailing: TextButton(onPressed: () {}, child: const Text('Modifier')),
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(context, 'Securite', [
                        _buildCard(context, [
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: const Text('Changer mot de passe'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showChangePasswordDialog(context, ref),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.security),
                            title: const Text('Authentification a deux facteurs'),
                            trailing: Switch(value: false, onChanged: (v) {}),
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(context, 'Notifications', [
                        _buildCard(context, [
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text('Notifications email'),
                            trailing: Switch(value: true, onChanged: (v) {}),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.notifications),
                            title: const Text('Notifications push'),
                            trailing: Switch(value: true, onChanged: (v) {}),
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(context, 'Ecole', [
                        _buildCard(context, [
                          ListTile(
                            leading: const Icon(Icons.school),
                            title: const Text('Informations de lecole'),
                            subtitle: const Text('Nom, adresse, logo...'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.contact_phone, color: Color(0xFF3B82F6)),
                            title: const Text('Informations de contact'),
                            subtitle: const Text('Téléphone, email, réseaux sociaux...'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/settings/contact-info'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Annees academiques'),
                            subtitle: const Text('Gerer les periodes scolaires'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection(context, 'Danger', [
                        _buildCard(context, [
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Deconnexion', style: TextStyle(color: Colors.red)),
                            onTap: () => ref.read(authProvider.notifier).signOut(),
                          ),
                        ]),
                      ]),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Parametres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPwd = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentPwd, decoration: const InputDecoration(labelText: 'Mot de passe actuel', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: newPwd, decoration: const InputDecoration(labelText: 'Nouveau mot de passe', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: confirmPwd, decoration: const InputDecoration(labelText: 'Confirmer', border: OutlineInputBorder()), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (newPwd.text != confirmPwd.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red));
                return;
              }
              // TODO: Implement password change
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe modifie'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Modifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}