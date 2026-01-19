import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Permission categories and their permissions
const Map<String, List<Map<String, String>>> permissionCategories = {
  'Utilisateurs': [
    {'key': 'users.view', 'label': 'Voir les utilisateurs', 'desc': 'Accéder à la liste des utilisateurs'},
    {'key': 'users.create', 'label': 'Créer des utilisateurs', 'desc': 'Ajouter de nouveaux étudiants ou staff'},
    {'key': 'users.edit', 'label': 'Modifier les utilisateurs', 'desc': 'Éditer les profils utilisateurs'},
    {'key': 'users.delete', 'label': 'Supprimer des utilisateurs', 'desc': 'Supprimer des comptes utilisateurs'},
    {'key': 'users.reset_password', 'label': 'Réinitialiser mot de passe', 'desc': 'Générer de nouveaux mots de passe'},
  ],
  'Notes & Résultats': [
    {'key': 'grades.view', 'label': 'Voir les notes', 'desc': 'Accéder aux notes des étudiants'},
    {'key': 'grades.create', 'label': 'Saisir des notes', 'desc': 'Ajouter des notes aux bulletins'},
    {'key': 'grades.edit', 'label': 'Modifier les notes', 'desc': 'Corriger les notes existantes'},
    {'key': 'grades.delete', 'label': 'Supprimer des notes', 'desc': 'Effacer des notes'},
  ],
  'Paiements': [
    {'key': 'payments.view', 'label': 'Voir les paiements', 'desc': 'Accéder à l\'historique des paiements'},
    {'key': 'payments.create', 'label': 'Enregistrer des paiements', 'desc': 'Ajouter des paiements reçus'},
    {'key': 'payments.edit', 'label': 'Modifier les paiements', 'desc': 'Corriger les informations de paiement'},
    {'key': 'payments.refund', 'label': 'Effectuer des remboursements', 'desc': 'Gérer les remboursements'},
  ],
  'Présences': [
    {'key': 'attendance.view', 'label': 'Voir les présences', 'desc': 'Accéder aux registres de présence'},
    {'key': 'attendance.create', 'label': 'Saisir les présences', 'desc': 'Enregistrer les absences/présences'},
    {'key': 'attendance.edit', 'label': 'Modifier les présences', 'desc': 'Corriger les registres'},
  ],
  'Annonces': [
    {'key': 'announcements.view', 'label': 'Voir les annonces', 'desc': 'Lire les annonces'},
    {'key': 'announcements.create', 'label': 'Créer des annonces', 'desc': 'Publier de nouvelles annonces'},
    {'key': 'announcements.edit', 'label': 'Modifier les annonces', 'desc': 'Éditer les annonces existantes'},
    {'key': 'announcements.delete', 'label': 'Supprimer des annonces', 'desc': 'Effacer des annonces'},
  ],
  'Suggestions': [
    {'key': 'suggestions.view', 'label': 'Voir les suggestions', 'desc': 'Lire les suggestions des étudiants'},
    {'key': 'suggestions.respond', 'label': 'Répondre aux suggestions', 'desc': 'Traiter et répondre aux suggestions'},
  ],
  'Emplois du temps': [
    {'key': 'timetable.view', 'label': 'Voir les emplois du temps', 'desc': 'Accéder aux plannings'},
    {'key': 'timetable.edit', 'label': 'Modifier les emplois du temps', 'desc': 'Éditer les créneaux'},
  ],
  'Classes & Groupes': [
    {'key': 'classes.view', 'label': 'Voir les classes', 'desc': 'Accéder aux informations des classes'},
    {'key': 'classes.manage', 'label': 'Gérer les classes', 'desc': 'Créer/modifier/supprimer des classes'},
    {'key': 'enrollments.manage', 'label': 'Gérer les inscriptions', 'desc': 'Inscrire des étudiants aux classes'},
  ],
  'Rapports': [
    {'key': 'reports.view', 'label': 'Voir les rapports', 'desc': 'Accéder aux tableaux de bord et statistiques'},
    {'key': 'reports.export', 'label': 'Exporter les données', 'desc': 'Télécharger les rapports en PDF/Excel'},
  ],
};

/// Provider for user permissions
final userPermissionsProvider = FutureProvider.family<Set<String>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('user_permissions')
        .select('permission_key')
        .eq('user_id', userId)
        .eq('granted', true);
    
    return (response as List).map((p) => p['permission_key'] as String).toSet();
  } catch (e) {
    return <String>{};
  }
});

class ManagerPermissionsDialog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const ManagerPermissionsDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<ManagerPermissionsDialog> createState() => _ManagerPermissionsDialogState();
}

class _ManagerPermissionsDialogState extends ConsumerState<ManagerPermissionsDialog> {
  late Set<String> _selectedPermissions;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = {};
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('user_permissions')
          .select('permission_key')
          .eq('user_id', widget.userId)
          .eq('granted', true);
      
      setState(() {
        _selectedPermissions = (response as List).map((p) => p['permission_key'] as String).toSet();
      });
    } catch (e) {
      // Ignore errors, start with empty set
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Delete all existing permissions for this user
      await supabase.from('user_permissions').delete().eq('user_id', widget.userId);
      
      // Insert new permissions
      if (_selectedPermissions.isNotEmpty) {
        final inserts = _selectedPermissions.map((perm) => {
          'user_id': widget.userId,
          'permission_key': perm,
          'granted': true,
        }).toList();
        
        await supabase.from('user_permissions').insert(inserts);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions enregistrées'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _togglePermission(String key) {
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
      } else {
        _selectedPermissions.add(key);
      }
    });
  }

  void _selectAllInCategory(String category) {
    final perms = permissionCategories[category] ?? [];
    setState(() {
      for (final perm in perms) {
        _selectedPermissions.add(perm['key']!);
      }
    });
  }

  void _deselectAllInCategory(String category) {
    final perms = permissionCategories[category] ?? [];
    setState(() {
      for (final perm in perms) {
        _selectedPermissions.remove(perm['key']!);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final category in permissionCategories.values) {
        for (final perm in category) {
          _selectedPermissions.add(perm['key']!);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPermissions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permissions de ${widget.userName}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Définissez ce que ce manager peut faire',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Quick actions
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Tout sélectionner'),
                  ),
                  TextButton(
                    onPressed: _deselectAll,
                    child: const Text('Tout désélectionner'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: permissionCategories.entries.map((entry) {
                        final category = entry.key;
                        final permissions = entry.value;
                        final allSelected = permissions.every((p) => _selectedPermissions.contains(p['key']));
                        final someSelected = permissions.any((p) => _selectedPermissions.contains(p['key']));
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: Icon(
                              _getCategoryIcon(category),
                              color: someSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Row(
                              children: [
                                Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: someSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${permissions.where((p) => _selectedPermissions.contains(p['key'])).length}/${permissions.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: someSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!allSelected)
                                  TextButton(
                                    onPressed: () => _selectAllInCategory(category),
                                    child: const Text('Tout', style: TextStyle(fontSize: 12)),
                                  ),
                                if (someSelected)
                                  TextButton(
                                    onPressed: () => _deselectAllInCategory(category),
                                    child: const Text('Aucun', style: TextStyle(fontSize: 12)),
                                  ),
                                const Icon(Icons.expand_more),
                              ],
                            ),
                            children: permissions.map((perm) {
                              final isSelected = _selectedPermissions.contains(perm['key']);
                              return ListTile(
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _togglePermission(perm['key']!),
                                ),
                                title: Text(perm['label']!),
                                subtitle: Text(perm['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                onTap: () => _togglePermission(perm['key']!),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedPermissions.length} permission(s) sélectionnée(s)',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, color: Colors.white),
                    label: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Utilisateurs': return Icons.people;
      case 'Notes & Résultats': return Icons.grade;
      case 'Paiements': return Icons.payment;
      case 'Présences': return Icons.event_available;
      case 'Annonces': return Icons.campaign;
      case 'Suggestions': return Icons.lightbulb;
      case 'Emplois du temps': return Icons.schedule;
      case 'Classes & Groupes': return Icons.class_;
      case 'Rapports': return Icons.assessment;
      default: return Icons.settings;
    }
  }
}

/// Show the permissions dialog for a manager
void showManagerPermissionsDialog(BuildContext context, String userId, String userName) {
  showDialog(
    context: context,
    builder: (ctx) => ManagerPermissionsDialog(userId: userId, userName: userName),
  );
}
