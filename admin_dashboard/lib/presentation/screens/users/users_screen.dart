import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';
import '../../providers/users_provider.dart';
import '../../widgets/admin_sidebar.dart';
import 'user_form_dialog.dart';
import 'user_detail_screen.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _roleFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showFilters = false;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/users'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, usersAsync),
                if (_showFilters) _buildFilterBar(context),
                Expanded(child: usersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(usersProvider),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                  data: (state) => _buildContent(context, state),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AsyncValue<UsersState> usersAsync) {
    final userCount = usersAsync.whenOrNull(data: (s) => s.users.length) ?? 0;
    final studentCount = usersAsync.whenOrNull(data: (s) => s.users.where((u) => u.role == 'student').length) ?? 0;
    
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text('Utilisateurs', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          // Statistics badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$userCount utilisateurs', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$studentCount étudiants', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
          ),
          const SizedBox(width: 24),
          // Search bar - same style as announcements/suggestions
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter toggle button
          Badge(
            isLabelVisible: _roleFilter != 'all',
            child: IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              tooltip: 'Filtres',
              onPressed: () => setState(() => _showFilters = !_showFilters),
              color: _showFilters ? Colors.blue : null,
            ),
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(usersProvider),
          ),
          const SizedBox(width: 8),
          // Add button
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Role filter
          DropdownButton<String>(
            value: _roleFilter,
            hint: const Text('Rôle'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les rôles')),
              DropdownMenuItem(value: 'admin', child: Text('Admins')),
              DropdownMenuItem(value: 'staff', child: Text('Staff')),
              DropdownMenuItem(value: 'teacher', child: Text('Enseignants')),
              DropdownMenuItem(value: 'student', child: Text('Étudiants')),
            ],
            onChanged: (v) => setState(() => _roleFilter = v!),
          ),
          // Sort dropdown
          DropdownButton<String>(
            value: _sortBy,
            hint: const Text('Trier par'),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Nom')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'role', child: Text('Rôle')),
              DropdownMenuItem(value: 'date', child: Text('Date création')),
            ],
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
          // Clear filters
          if (_roleFilter != 'all')
            TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser'),
              onPressed: () => setState(() {
                _roleFilter = 'all';
                _sortBy = 'name';
                _sortAscending = true;
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UsersState state) {
    var users = state.users;
    
    // Apply role filter
    if (_roleFilter != 'all') {
      users = users.where((u) => u.role == _roleFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      users = users.where((u) => 
        u.fullName.toLowerCase().contains(query) || 
        u.email.toLowerCase().contains(query) ||
        (u.studentCode?.toLowerCase().contains(query) ?? false) ||
        (u.phone?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    // Apply sorting
    users.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'email':
          result = a.email.compareTo(b.email);
          break;
        case 'role':
          result = a.role.compareTo(b.role);
          break;
        case 'date':
          result = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          result = a.fullName.compareTo(b.fullName);
      }
      return _sortAscending ? result : -result;
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: _buildTable(users),
      ),
    );
  }

  Widget _buildTable(List<UserModel> users) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 1000,
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
      columns: const [
        DataColumn2(label: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Rôle', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Date création', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 140),
      ],
      rows: users.map((u) => DataRow2(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserDetailScreen(userId: u.id, userName: u.fullName)),
        ),
        cells: [
          DataCell(Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _getRoleColor(u.role).withOpacity(0.2),
              backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
              child: u.photoUrl == null 
                  ? Text(u.fullName.substring(0, 1).toUpperCase(), style: TextStyle(color: _getRoleColor(u.role), fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (u.studentCode != null)
                    Text(u.studentCode!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
          ])),
          DataCell(Text(u.email)),
          DataCell(Text(u.phone ?? '-', style: TextStyle(color: u.phone == null ? Colors.grey : null))),
          DataCell(_RoleChip(role: u.role)),
          DataCell(Text(DateFormat('dd/MM/yyyy').format(u.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          DataCell(Row(children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserDetailScreen(userId: u.id, userName: u.fullName)),
              ),
              tooltip: 'Voir détails',
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showUserDialog(context, user: u),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDelete(context, u),
              tooltip: 'Supprimer',
            ),
          ])),
        ],
      )).toList(),
      empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Aucun utilisateur', style: TextStyle(color: Colors.grey[600])),
        if (_searchQuery.isNotEmpty || _roleFilter != 'all')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Essayez de modifier les filtres', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
      ])),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'staff': return Colors.blue;
      case 'teacher': return Colors.green;
      default: return Colors.orange;
    }
  }

  void _showUserDialog(BuildContext context, {UserModel? user}) {
    showDialog(context: context, builder: (ctx) => UserFormDialog(user: user));
  }

  void _confirmDelete(BuildContext context, UserModel u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer utilisateur ?'),
        content: Text('Voulez-vous supprimer "${u.fullName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { ref.read(usersProvider.notifier).deleteUser(u.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'admin':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        label = 'Admin';
        break;
      case 'staff':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        label = 'Staff';
        break;
      case 'teacher':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Enseignant';
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        label = 'Etudiant';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}