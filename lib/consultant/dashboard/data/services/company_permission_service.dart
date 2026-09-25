import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyPermissionService {
  CompanyPermissionService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> can(
      String companyId,
      String permissionCode,
      ) async {
    final result = await _supabase.rpc(
      'user_has_company_permission',
      params: {
        'target_company_id': companyId,
        'required_permission_code': permissionCode,
      },
    );

    return result == true;
  }
}