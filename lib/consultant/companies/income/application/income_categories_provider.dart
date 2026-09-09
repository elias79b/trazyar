import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CATEGORIES PROVIDER
// ============================================================

final incomeCategoriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      companyId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('income_categories')
          .select('''
          id,
          company_id,
          name,
          code,
          description,
          is_active,
          created_by,
          created_at,
          updated_at
        ''')
          .eq('company_id', companyId)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

// ============================================================
// CATEGORY SERVICE
// ============================================================

final incomeCategoryServiceProvider = Provider<IncomeCategoryService>((ref) {
  return IncomeCategoryService(Supabase.instance.client);
});

class IncomeCategoryService {
  IncomeCategoryService(this.client);

  final SupabaseClient client;

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<void> createCategory({
    required String companyId,
    required String name,
    String? code,
    String? description,
    bool isActive = true,
  }) async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await client.from('income_categories').insert({
      'company_id': companyId,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
      'created_by': user.id,
    });
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<void> updateCategory({
    required String id,
    required String name,
    String? code,
    String? description,
    required bool isActive,
  }) async {
    await client
        .from('income_categories')
        .update({
          'name': name,
          'code': code,
          'description': description,
          'is_active': isActive,
        })
        .eq('id', id);
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteCategory(String id) async {
    await client.from('income_categories').delete().eq('id', id);
  }
}
