import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payroll_record_model.dart';
import '../data/payroll_record_repository.dart';

final payrollRecordRepositoryProvider = Provider<PayrollRecordRepository>((
  ref,
) {
  return PayrollRecordRepository();
});

// ============================================================
// ALL COMPANY RECORDS
// ============================================================

final payrollRecordsProvider =
    FutureProvider.family<List<PayrollRecordModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(payrollRecordRepositoryProvider);

      return repository.getRecords(companyId);
    });

// ============================================================
// RECORDS BY PERIOD
// ============================================================

final payrollRecordsByPeriodProvider =
    FutureProvider.family<List<PayrollRecordModel>, String>((
      ref,
      payrollPeriodId,
    ) async {
      final repository = ref.watch(payrollRecordRepositoryProvider);

      return repository.getRecordsByPeriod(payrollPeriodId);
    });

// ============================================================
// SINGLE RECORD
// ============================================================

final payrollRecordProvider =
    FutureProvider.family<PayrollRecordModel?, String>((ref, recordId) async {
      final repository = ref.watch(payrollRecordRepositoryProvider);

      return repository.getRecordById(recordId);
    });

// ============================================================
// EMPLOYEE RECORD IN PERIOD
// ============================================================

final payrollEmployeeRecordProvider =
    FutureProvider.family<PayrollRecordModel?, PayrollEmployeeRecordParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(payrollRecordRepositoryProvider);

      return repository.getEmployeeRecord(
        payrollPeriodId: params.payrollPeriodId,
        employeeId: params.employeeId,
      );
    });

class PayrollEmployeeRecordParams {
  const PayrollEmployeeRecordParams({
    required this.payrollPeriodId,
    required this.employeeId,
  });

  final String payrollPeriodId;
  final String employeeId;

  @override
  bool operator ==(Object other) {
    return other is PayrollEmployeeRecordParams &&
        other.payrollPeriodId == payrollPeriodId &&
        other.employeeId == employeeId;
  }

  @override
  int get hashCode {
    return Object.hash(payrollPeriodId, employeeId);
  }
}
