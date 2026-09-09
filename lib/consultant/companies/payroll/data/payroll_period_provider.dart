import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payroll_period_model.dart';
import '../data/payroll_period_repository.dart';

// ============================================================
// REPOSITORY PROVIDER
// ============================================================

final payrollPeriodRepositoryProvider =
Provider<PayrollPeriodRepository>((ref) {
  return PayrollPeriodRepository();
});

// ============================================================
// ALL PERIODS
// ============================================================

final payrollPeriodsProvider =
FutureProvider.family<
    List<PayrollPeriodModel>,
    String>((ref, companyId) async {
  final repository =
  ref.watch(
    payrollPeriodRepositoryProvider,
  );

  return repository.getPeriods(
    companyId,
  );
});

// ============================================================
// SINGLE PERIOD
// ============================================================

final payrollPeriodProvider =
FutureProvider.family<
    PayrollPeriodModel?,
    String>((ref, periodId) async {
  final repository =
  ref.watch(
    payrollPeriodRepositoryProvider,
  );

  return repository.getPeriodById(
    periodId,
  );
});

// ============================================================
// EXISTS
// ============================================================

final payrollPeriodExistsProvider =
FutureProvider.family<
    bool,
    PayrollPeriodExistsParams>(
      (ref, params) async {
    final repository =
    ref.watch(
      payrollPeriodRepositoryProvider,
    );

    return repository.periodExists(
      companyId:
      params.companyId,
      periodYear:
      params.periodYear,
      periodMonth:
      params.periodMonth,
      exceptId:
      params.exceptId,
    );
  },
);

// ============================================================
// EXISTS PARAMS
// ============================================================

class PayrollPeriodExistsParams {
  const PayrollPeriodExistsParams({
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
    this.exceptId,
  });

  final String companyId;
  final int periodYear;
  final int periodMonth;
  final String? exceptId;

  @override
  bool operator ==(
      Object other,
      ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
    is PayrollPeriodExistsParams &&
        other.companyId ==
            companyId &&
        other.periodYear ==
            periodYear &&
        other.periodMonth ==
            periodMonth &&
        other.exceptId ==
            exceptId;
  }

  @override
  int get hashCode {
    return Object.hash(
      companyId,
      periodYear,
      periodMonth,
      exceptId,
    );
  }
}

// ============================================================
// FIND PERIOD
// ============================================================

final payrollPeriodByYearMonthProvider =
FutureProvider.family<
    PayrollPeriodModel?,
    PayrollPeriodLookupParams>(
      (ref, params) async {
    final repository =
    ref.watch(
      payrollPeriodRepositoryProvider,
    );

    return repository.findPeriod(
      companyId:
      params.companyId,
      periodYear:
      params.periodYear,
      periodMonth:
      params.periodMonth,
    );
  },
);

// ============================================================
// LOOKUP PARAMS
// ============================================================

class PayrollPeriodLookupParams {
  const PayrollPeriodLookupParams({
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
  });

  final String companyId;
  final int periodYear;
  final int periodMonth;

  @override
  bool operator ==(
      Object other,
      ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
    is PayrollPeriodLookupParams &&
        other.companyId ==
            companyId &&
        other.periodYear ==
            periodYear &&
        other.periodMonth ==
            periodMonth;
  }

  @override
  int get hashCode {
    return Object.hash(
      companyId,
      periodYear,
      periodMonth,
    );
  }
}