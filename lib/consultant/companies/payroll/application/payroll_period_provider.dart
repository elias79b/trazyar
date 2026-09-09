import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payroll_period_model.dart';
import '../data/payroll_period_repository.dart';

final payrollPeriodRepositoryProvider = Provider<PayrollPeriodRepository>((
  ref,
) {
  return PayrollPeriodRepository();
});

final payrollPeriodsProvider =
    FutureProvider.family<List<PayrollPeriodModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(payrollPeriodRepositoryProvider);

      return repository.getPeriods(companyId);
    });

final payrollPeriodProvider =
    FutureProvider.family<PayrollPeriodModel?, String>((ref, periodId) async {
      final repository = ref.watch(payrollPeriodRepositoryProvider);

      return repository.getPeriodById(periodId);
    });
