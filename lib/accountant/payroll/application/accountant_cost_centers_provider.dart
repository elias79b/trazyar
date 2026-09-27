import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantCostCentersProvider =
    FutureProvider.family<List<AccountantCostCenter>, String>((
      ref,
      companyId,
    ) async {
      return AccountantCostCentersRepository.fetch(companyId);
    });

class AccountantCostCenter {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantCostCenter({
    required this.id,
    required this.companyId,
    required this.name,
    this.code,
    this.description,
    required this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AccountantCostCenter.fromMap(Map<String, dynamic> map) {
    return AccountantCostCenter(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
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

class AccountantCostCentersRepository {
  AccountantCostCentersRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<AccountantCostCenter>> fetch(String companyId) async {
    final response = await _supabase
        .from('cost_centers')
        .select(
          'id, company_id, name, code, description, is_active, '
          'created_by, created_at, updated_at',
        )
        .eq('company_id', companyId)
        .order('is_active', ascending: false)
        .order('name');

    return (response as List)
        .map(
          (row) => AccountantCostCenter.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  static Future<void> create({
    required String companyId,
    required String name,
    String? code,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('cost_centers').insert({
      'company_id': companyId,
      'name': name.trim(),
      'code': _nullableText(code),
      'description': _nullableText(description),
      'is_active': true,
      'created_by': userId,
    });
  }

  static Future<void> update({
    required String id,
    required String name,
    String? code,
    String? description,
    required bool isActive,
  }) async {
    await _supabase
        .from('cost_centers')
        .update({
          'name': name.trim(),
          'code': _nullableText(code),
          'description': _nullableText(description),
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    await _supabase
        .from('cost_centers')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> delete({required String id}) async {
    await _supabase.from('cost_centers').delete().eq('id', id);
  }

  static String? _nullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
