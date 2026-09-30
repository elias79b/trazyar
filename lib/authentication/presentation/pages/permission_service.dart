
import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionService {
  PermissionService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // CHECK PERMISSION
  // ============================================================

  static Future<bool> hasPermission(
      String permissionCode,
      ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final role = await _resolveRole();

      if (role == null || role.isEmpty) {
        return false;
      }

      final result = await _supabase
          .from('role_permissions')
          .select(
        'permission_id, permissions!inner(code)',
      )
          .eq(
        'role',
        role,
      )
          .eq(
        'permissions.code',
        permissionCode,
      )
          .limit(1);

      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESOLVE CURRENT USER ROLE
  // ============================================================

  static Future<String?> _resolveRole() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final userId = user.id;

      final userRow = await _supabase
          .from('users')
          .select(
        'id, role, is_active',
      )
          .eq(
        'id',
        userId,
      )
          .maybeSingle();

      if (userRow == null) {
        return null;
      }

      final isActive =
          userRow['is_active'] == true;

      if (!isActive) {
        return null;
      }

      return userRow['role']
          ?.toString()
          .trim()
          .toLowerCase();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  static Future<bool> isOwner() async {
    final role = await _resolveRole();

    return role == 'owner';
  }

  static Future<bool> isConsultant() async {
    final role = await _resolveRole();

    return role == 'consultant';
  }

  static Future<bool> isAccountant() async {
    final role = await _resolveRole();

    return role == 'accountant';
  }

  static Future<bool> isCompanyAdmin() async {
    final role = await _resolveRole();

    return role == 'company_admin';
  }
}