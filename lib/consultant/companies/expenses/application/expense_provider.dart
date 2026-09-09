import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final expensesProvider = FutureProvider.family<List<ExpenseModel>, String>((
  ref,
  companyId,
) async {
  final repository = ref.watch(expenseRepositoryProvider);

  return repository.getExpenses(companyId);
});

final expenseProvider = FutureProvider.family<ExpenseModel?, String>((
  ref,
  expenseId,
) async {
  final repository = ref.watch(expenseRepositoryProvider);

  return repository.getExpenseById(expenseId);
});

final payrollExpenseSourcesProvider =
    FutureProvider.family<List<PayrollExpenseSource>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getPayrollExpenseSources(companyId);
    });

final payrollExpenseSourceProvider =
    FutureProvider.family<PayrollExpenseSource?, String>((
      ref,
      payrollPeriodId,
    ) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getPayrollExpenseSource(payrollPeriodId);
    });
