import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission_model.dart';

class PermissionRepository {
  final SupabaseClient _client;

  PermissionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all available permissions
  Future<List<Permission>> fetchAllPermissions() async {
    final response = await _client
        .from('permissions')
        .select()
        .order('group_name')
        .order('code');

    return (response as List)
        .map((json) => Permission.fromJson(json))
        .toList();
  }

  /// Fetch permissions grouped by group_name
  Future<Map<String, List<Permission>>> fetchPermissionsGrouped() async {
    final permissions = await fetchAllPermissions();
    final grouped = <String, List<Permission>>{};
    
    for (final perm in permissions) {
      grouped.putIfAbsent(perm.groupName, () => []).add(perm);
    }
    
    return grouped;
  }

  /// Fetch permissions for a specific manager
  Future<List<String>> fetchManagerPermissionCodes(String managerId) async {
    final response = await _client
        .from('manager_permissions')
        .select('permission_code')
        .eq('manager_id', managerId);

    return (response as List)
        .map((json) => json['permission_code'] as String)
        .toList();
  }

  /// Check if current user has a specific permission
  Future<bool> hasPermission(String permissionCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .rpc('has_permission', params: {
          'user_id': userId,
          'perm_code': permissionCode,
        });

    return response as bool? ?? false;
  }

  /// Check if current user is owner
  Future<bool> isOwner() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .rpc('is_owner', params: {'user_id': userId});

    return response as bool? ?? false;
  }

  /// Assign permission to manager (owner only)
  Future<void> assignPermission(String managerId, String permissionCode) async {
    await _client.from('manager_permissions').insert({
      'manager_id': managerId,
      'permission_code': permissionCode,
    });
  }

  /// Remove permission from manager (owner only)
  Future<void> removePermission(String managerId, String permissionCode) async {
    await _client
        .from('manager_permissions')
        .delete()
        .eq('manager_id', managerId)
        .eq('permission_code', permissionCode);
  }

  /// Set all permissions for a manager (replaces existing)
  Future<void> setManagerPermissions(String managerId, List<String> permissionCodes) async {
    // Remove all existing
    await _client
        .from('manager_permissions')
        .delete()
        .eq('manager_id', managerId);

    // Insert new ones
    if (permissionCodes.isNotEmpty) {
      await _client.from('manager_permissions').insert(
        permissionCodes.map((code) => {
          'manager_id': managerId,
          'permission_code': code,
        }).toList(),
      );
    }
  }
}
