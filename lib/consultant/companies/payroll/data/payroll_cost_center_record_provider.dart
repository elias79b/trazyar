import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'payroll_cost_center_record_model.dart';
import 'payroll_cost_center_record_repository.dart';

final payrollCostCenterRecordRepositoryProvider =
    Provider<PayrollCostCenterRecordRepository>((ref) {
      return PayrollCostCenterRecordRepository(
        client: Supabase.instance.client,
      );
    });

final payrollCostCenterRecordsProvider =
    FutureProvider.family<List<PayrollCostCenterRecordModel>, String>((
      ref,
      payrollPeriodId,
    ) async {
      final repository = ref.read(payrollCostCenterRecordRepositoryProvider);

      return repository.getByPeriod(payrollPeriodId);
    });

final payrollCostCenterRecordProvider =
    FutureProvider.family<PayrollCostCenterRecordModel?, String>((
      ref,
      id,
    ) async {
      final repository = ref.read(payrollCostCenterRecordRepositoryProvider);

      return repository.getById(id);
    });
