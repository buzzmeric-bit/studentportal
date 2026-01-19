import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../providers/users_provider.dart';
import '../../widgets/admin_sidebar.dart';

/// Provider for pending password reset count (for notification badges)
final pendingPasswordResetCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('password_reset_requests')
        .select('id')
        .eq('status', 'pending');
    debugPrint('Pending password reset count: ${(response as List).length}');
    return (response as List).length;
  } catch (e) {
    debugPrint('Error fetching pending count: $e');
    return 0;
  }
});

/// Provider for password reset requests - uses data directly from the table
final passwordResetRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final supabase = Supabase.instance.client;

      try {
        debugPrint('Fetching password reset requests...');
        // The table stores full_name and email directly, no need to join with users
        final response = await supabase
            .from('password_reset_requests')
            .select('*')
            .order('requested_at', ascending: false);

        debugPrint('Got ${(response as List).length} password reset requests');
        return (response as List).cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint('Error fetching password reset requests: $e');
        return [];
      }
    });

class PasswordResetRequestsScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestsScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestsScreen> createState() =>
      _PasswordResetRequestsScreenState();
}

class _PasswordResetRequestsScreenState
    extends ConsumerState<PasswordResetRequestsScreen> {
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    // Force refresh on page load
    Future.microtask(() {
      ref.invalidate(passwordResetRequestsProvider);
      ref.invalidate(pendingPasswordResetCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(passwordResetRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/password-resets'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                _buildFilterBar(context),
                Expanded(
                  child: requestsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text('Erreur: $e', textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                ref.invalidate(passwordResetRequestsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                    data: (requests) {
                      debugPrint(
                        'Rendering ${requests.length} requests, filter: $_filter',
                      );
                      return _buildContent(context, requests);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_reset,
              color: Colors.orange.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Demandes de réinitialisation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gérez les demandes de nouveaux mots de passe',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(passwordResetRequestsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _FilterChip(
            label: 'En attente',
            icon: Icons.hourglass_empty,
            isSelected: _filter == 'pending',
            color: Colors.orange,
            onTap: () => setState(() => _filter = 'pending'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Approuvées',
            icon: Icons.check_circle,
            isSelected: _filter == 'approved',
            color: Colors.green,
            onTap: () => setState(() => _filter = 'approved'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Rejetées',
            icon: Icons.cancel,
            isSelected: _filter == 'rejected',
            color: Colors.red,
            onTap: () => setState(() => _filter = 'rejected'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Toutes',
            icon: Icons.list,
            isSelected: _filter == 'all',
            color: Colors.blue,
            onTap: () => setState(() => _filter = 'all'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> requests,
  ) {
    final filtered = _filter == 'all'
        ? requests
        : requests.where((r) => r['status'] == _filter).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucune demande ${_filter == 'pending' ? 'en attente' : ''}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _buildRequestCard(context, filtered[index]),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    // Data is stored directly in the table, not from a joined users table
    final fullName = request['full_name'] as String? ?? 'Inconnu';
    final email = request['email'] as String? ?? '';
    final status = request['status'] as String;
    final requestedAt = DateTime.parse(request['requested_at']);
    final userId = request['user_id'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                fullName.isNotEmpty
                    ? fullName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (userId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Utilisateur vérifié',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(requestedAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 16,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (status == 'pending') ...[
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Approuver',
                onPressed: () => _approveRequest(context, request),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Rejeter',
                onPressed: () => _rejectRequest(context, request),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'En attente';
    }
  }

  Future<void> _approveRequest(
    BuildContext context,
    Map<String, dynamic> request,
  ) async {
    final userId = request['user_id'] as String?;
    final requestId = request['id'] as String;
    final fullName = request['full_name'] as String? ?? 'l\'utilisateur';
    final email = request['email'] as String? ?? '';

    // Check if we have a user_id to update password
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible: cet email n\'est pas associé à un compte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate new password
    final newPassword = ref.read(usersProvider.notifier).generatePassword();

    // Show confirmation dialog with password
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('Approuver la demande'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouveau mot de passe pour $fullName ($email):'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    newPassword,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: newPassword));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Copié!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notez ce mot de passe et transmettez-le à l\'utilisateur.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Confirmer et réinitialiser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;
      final adminClient = SupabaseConfig.adminClient;

      // Reset password using admin client with service role
      await adminClient.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(password: newPassword),
      );

      // Update request status
      await supabase
          .from('password_reset_requests')
          .update({
            'status': 'approved',
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': supabase.auth.currentUser?.id,
            'new_password_sent': true,
          })
          .eq('id', requestId);

      ref.invalidate(passwordResetRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    Map<String, dynamic> request,
  ) async {
    final requestId = request['id'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Rejeter la demande'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment rejeter cette demande de réinitialisation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('password_reset_requests')
          .update({
            'status': 'rejected',
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': supabase.auth.currentUser?.id,
          })
          .eq('id', requestId);

      ref.invalidate(passwordResetRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande rejetée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
