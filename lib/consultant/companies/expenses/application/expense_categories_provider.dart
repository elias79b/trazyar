import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_provider.dart';

import '../data/expense_category_model.dart';

final expenseCategoriesProvider =
    FutureProvider.family<List<ExpenseCategoryModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getCategories(companyId);
    });

final activeExpenseCategoriesProvider =
    FutureProvider.family<List<ExpenseCategoryModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getCategories(companyId, activeOnly: true);
    });

final expenseCategoryProvider =
    FutureProvider.family<ExpenseCategoryModel?, String>((
      ref,
      categoryId,
    ) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getCategoryById(categoryId);
    });
