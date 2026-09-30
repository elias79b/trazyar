import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantExpenseCategoriesProvider =
FutureProvider.autoDispose.family<
    AccountantExpenseCategoriesData,
    String>((ref, companyId) async {
  final repository = AccountantExpenseCategoriesRepository(
    Supabase.instance.client,
  );

  return repository.load(companyId);
});

class AccountantExpenseCategoriesRepository {
  AccountantExpenseCategoriesRepository(this._client);

  final SupabaseClient _client;

  Future<AccountantExpenseCategoriesData> load(
      String companyId,
      ) async {
    final response = await _client
        .from('expense_categories')
        .select(
      'id, company_id, name, code, description, '
          'expense_type, is_active, is_system, created_by, '
          'created_at, updated_at',
    )
        .eq('company_id', companyId)
        .order('expense_type', ascending: true)
        .order('is_system', ascending: false)
        .order('name', ascending: true);

    final categories = (response as List)
        .map(
          (row) => AccountantExpenseCategory.fromMap(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();

    return AccountantExpenseCategoriesData(
      companyId: companyId,
      categories: categories,
    );
  }

  Future<AccountantExpenseCategory> createCategory({
    required String companyId,
    required String name,
    String? code,
    String? description,
    required String expenseType,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام سرفصل هزینه الزامی است.');
    }

    _validateExpenseType(expenseType);

    final response = await _client
        .from('expense_categories')
        .insert({
      'company_id': companyId,
      'name': cleanName,
      'code': _nullableText(code),
      'description': _nullableText(description),
      'expense_type': expenseType,
      'is_active': true,
      'is_system': false,
      'created_by': userId,
    })
        .select(
      'id, company_id, name, code, description, '
          'expense_type, is_active, is_system, created_by, '
          'created_at, updated_at',
    )
        .single();

    return AccountantExpenseCategory.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<AccountantExpenseCategory> updateCategory({
    required String categoryId,
    required String companyId,
    required String name,
    String? code,
    String? description,
    required String expenseType,
    required bool isActive,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام سرفصل هزینه الزامی است.');
    }

    _validateExpenseType(expenseType);

    final response = await _client
        .from('expense_categories')
        .update({
      'name': cleanName,
      'code': _nullableText(code),
      'description': _nullableText(description),
      'expense_type': expenseType,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', categoryId)
        .eq('company_id', companyId)
        .select(
      'id, company_id, name, code, description, '
          'expense_type, is_active, is_system, created_by, '
          'created_at, updated_at',
    )
        .single();

    return AccountantExpenseCategory.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> deleteCategory({
    required String categoryId,
    required String companyId,
  }) async {
    try {
      await _client
          .from('expense_categories')
          .delete()
          .eq('id', categoryId)
          .eq('company_id', companyId);
    } on PostgrestException catch (error) {
      if (error.message.contains(
        'SYSTEM_EXPENSE_CATEGORY_CANNOT_BE_DELETED',
      ) ||
          error.code == 'P0001') {
        throw Exception('سرفصل سیستمی قابل حذف نیست.');
      }

      rethrow;
    }
  }

  Future<void> setActive({
    required String categoryId,
    required String companyId,
    required bool isActive,
  }) async {
    await _client
        .from('expense_categories')
        .update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', categoryId)
        .eq('company_id', companyId);
  }

  void _validateExpenseType(String expenseType) {
    if (expenseType != 'operational' &&
        expenseType != 'non_operational') {
      throw Exception('نوع هزینه نامعتبر است.');
    }
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

class AccountantExpenseCategoriesData {
  const AccountantExpenseCategoriesData({
    required this.companyId,
    required this.categories,
  });

  final String companyId;
  final List<AccountantExpenseCategory> categories;

  List<AccountantExpenseCategory> get activeCategories {
    return categories
        .where((category) => category.isActive)
        .toList();
  }

  List<AccountantExpenseCategory> get operationalCategories {
    return categories
        .where(
          (category) =>
      category.expenseType == 'operational',
    )
        .toList();
  }

  List<AccountantExpenseCategory> get nonOperationalCategories {
    return categories
        .where(
          (category) =>
      category.expenseType == 'non_operational',
    )
        .toList();
  }

  List<AccountantExpenseCategory>
  get activeOperationalCategories {
    return categories
        .where(
          (category) =>
      category.isActive &&
          category.expenseType == 'operational',
    )
        .toList();
  }

  List<AccountantExpenseCategory>
  get activeNonOperationalCategories {
    return categories
        .where(
          (category) =>
      category.isActive &&
          category.expenseType == 'non_operational',
    )
        .toList();
  }
}

class AccountantExpenseCategory {
  const AccountantExpenseCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    required this.expenseType,
    required this.isActive,
    required this.isSystem,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final String expenseType;
  final bool isActive;
  final bool isSystem;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOperational {
    return expenseType == 'operational';
  }

  bool get isNonOperational {
    return expenseType == 'non_operational';
  }

  String get expenseTypeTitle {
    switch (expenseType) {
      case 'operational':
        return 'عملیاتی';

      case 'non_operational':
        return 'غیرعملیاتی';

      default:
        return 'نامشخص';
    }
  }

  String get statusTitle {
    return isActive ? 'فعال' : 'غیرفعال';
  }

  factory AccountantExpenseCategory.fromMap(
      Map<String, dynamic> map,
      ) {
    return AccountantExpenseCategory(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      expenseType:
      map['expense_type']?.toString() ?? 'operational',
      isActive: _parseBool(
        map['is_active'],
        true,
      ),
      isSystem: _parseBool(
        map['is_system'],
        false,
      ),
      createdBy: map['created_by']?.toString(),
      createdAt: _parseDateTime(
        map['created_at'],
      ),
      updatedAt: _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  static bool _parseBool(
      dynamic value,
      bool fallback,
      ) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return fallback;
  }

  static DateTime? _parseDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}