import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionService {
  PermissionService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static Future<bool> hasPermission(
      String permissionCode,
      ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final result = await _supabase
          .from('role_permissions')
          .select('permission_id, permissions!inner(code)')
          .eq('role', (await _resolveRole()) as Object)
          .eq('permissions.code', permissionCode)
          .limit(1);

      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _resolveRole() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final userId = user.id;

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return profile?['role']?.toString();
  }

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