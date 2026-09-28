import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeCategoriesProvider =
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
        is_system,
        category_type,
        created_by,
        created_at,
        updated_at
      ''')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('category_type', ascending: true)
          .order('is_system', ascending: false)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

final accountantIncomeOperationalCategoriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      companyId,
    ) async {
      final categories = await ref.watch(
        accountantIncomeCategoriesProvider(companyId).future,
      );

      return categories
          .where((item) => item['category_type'] == 'operational')
          .toList();
    });

final accountantIncomeNonOperationalCategoriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      companyId,
    ) async {
      final categories = await ref.watch(
        accountantIncomeCategoriesProvider(companyId).future,
      );

      return categories
          .where((item) => item['category_type'] == 'non_operational')
          .toList();
    });

class AccountantIncomeCategoriesService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> ensureDefaultCategories(String companyId) async {
    await _client.rpc(
      'ensure_default_income_categories',
      params: {'p_company_id': companyId},
    );
  }

  static Future<Map<String, dynamic>> createCategory({
    required String companyId,
    required String name,
    required String categoryType,
    String? code,
    String? description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام سرفصل الزامی است.');
    }

    if (categoryType != 'operational' && categoryType != 'non_operational') {
      throw Exception('نوع سرفصل نامعتبر است.');
    }

    final cleanCode = code?.trim();

    final data = <String, dynamic>{
      'company_id': companyId,
      'name': cleanName,
      'description': _cleanText(description),
      'is_active': true,
      'is_system': false,
      'category_type': categoryType,
      'created_by': user.id,
    };

    if (cleanCode != null && cleanCode.isNotEmpty) {
      data['code'] = cleanCode;
    }

    final response =
        await _client.from('income_categories').insert(data).select('''
          id,
          company_id,
          name,
          code,
          description,
          is_active,
          is_system,
          category_type,
          created_by,
          created_at,
          updated_at
        ''').single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> updateCategory({
    required String id,
    required String name,
    required String categoryType,
    String? code,
    String? description,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام سرفصل الزامی است.');
    }

    if (categoryType != 'operational' && categoryType != 'non_operational') {
      throw Exception('نوع سرفصل نامعتبر است.');
    }

    final existing =
        await _client
            .from('income_categories')
            .select('id,is_system')
            .eq('id', id)
            .maybeSingle();

    if (existing == null) {
      throw Exception('سرفصل موردنظر پیدا نشد.');
    }

    if (existing['is_system'] == true) {
      throw Exception('سرفصل‌های سیستمی قابل ویرایش نیستند.');
    }

    final cleanCode = code?.trim();

    final data = <String, dynamic>{
      'name': cleanName,
      'description': _cleanText(description),
      'category_type': categoryType,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (cleanCode == null || cleanCode.isEmpty) {
      data['code'] = null;
    } else {
      data['code'] = cleanCode;
    }

    final response =
        await _client
            .from('income_categories')
            .update(data)
            .eq('id', id)
            .select('''
          id,
          company_id,
          name,
          code,
          description,
          is_active,
          is_system,
          category_type,
          created_by,
          created_at,
          updated_at
        ''')
            .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<void> deleteCategory(String id) async {
    final existing =
        await _client
            .from('income_categories')
            .select('id,is_system')
            .eq('id', id)
            .maybeSingle();

    if (existing == null) {
      throw Exception('سرفصل موردنظر پیدا نشد.');
    }

    if (existing['is_system'] == true) {
      throw Exception('سرفصل‌های سیستمی قابل حذف نیستند.');
    }

    await _client
        .from('income_categories')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static String? _cleanText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
