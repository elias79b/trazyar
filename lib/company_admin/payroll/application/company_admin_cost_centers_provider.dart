
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminCostCentersProvider =
FutureProvider.autoDispose<CompanyAdminCostCentersData>((ref) async {
  final repository = CompanyAdminCostCentersRepository(
    Supabase.instance.client,
  );

  return repository.load();
});

class CompanyAdminCostCentersRepository {
  final SupabaseClient _supabase;

  CompanyAdminCostCentersRepository(this._supabase);

  Future<String> _resolveCompanyId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final membership = await _supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .eq('role', 'company_admin')
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (membership == null) {
      throw Exception('شرکت فعال برای مدیرعامل پیدا نشد.');
    }

    final companyId = membership['company_id']?.toString();

    if (companyId == null || companyId.isEmpty) {
      throw Exception('شناسه شرکت معتبر نیست.');
    }

    return companyId;
  }

  Future<CompanyAdminCostCentersData> load() async {
    final companyId = await _resolveCompanyId();

    final response = await _supabase
        .from('cost_centers')
        .select(
      'id, company_id, name, code, description, is_active, '
          'created_by, created_at, updated_at',
    )
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    final centers = (response as List)
        .map(
          (item) => CompanyAdminCostCenter.fromMap(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();

    return CompanyAdminCostCentersData(
      companyId: companyId,
      centers: centers,
    );
  }

  Future<void> create({
    required String name,
    String? code,
    String? description,
  }) async {
    final companyId = await _resolveCompanyId();
    final user = _supabase.auth.currentUser!;

    await _supabase.from('cost_centers').insert({
      'company_id': companyId,
      'name': name.trim(),
      'code': _clean(code),
      'description': _clean(description),
      'is_active': true,
      'created_by': user.id,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    String? code,
    String? description,
  }) async {
    final companyId = await _resolveCompanyId();

    await _supabase
        .from('cost_centers')
        .update({
      'name': name.trim(),
      'code': _clean(code),
      'description': _clean(description),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    })
        .eq('id', id)
        .eq('company_id', companyId);
  }

  Future<void> updateActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    final companyId = await _resolveCompanyId();

    await _supabase
        .from('cost_centers')
        .update({
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    })
        .eq('id', id)
        .eq('company_id', companyId);
  }

  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}

class CompanyAdminCostCentersData {
  final String companyId;
  final List<CompanyAdminCostCenter> centers;

  const CompanyAdminCostCentersData({
    required this.companyId,
    required this.centers,
  });

  int get totalCount => centers.length;

  int get activeCount => centers.where((center) => center.isActive).length;

  int get inactiveCount => centers.where((center) => !center.isActive).length;
}

class CompanyAdminCostCenter {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyAdminCostCenter({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyAdminCostCenter.fromMap(Map<String, dynamic> map) {
    return CompanyAdminCostCenter(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      isActive: map['is_active'] == true,
      createdBy: map['created_by']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
