import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final incomeAccessProvider =
FutureProvider.family<IncomeAccess, String>(
      (ref, companyId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      return const IncomeAccess.none();
    }

    // ==========================================================
    // GLOBAL USER ROLE
    // ==========================================================

    final userRow = await client
        .from('users')
        .select(
      'id, role, is_active',
    )
        .eq(
      'id',
      user.id,
    )
        .maybeSingle();

    if (userRow == null ||
        userRow['is_active'] != true) {
      return const IncomeAccess.none();
    }

    final globalRole =
    userRow['role']?.toString();

    // ==========================================================
    // GLOBAL OWNER HAS FULL ACCESS
    //
    // مهم:
    // اگر کاربر owner باشد، حتی اگر در company_users
    // نقش دیگری داشته باشد، مالک اصلی شرکت باید دسترسی
    // کامل ماژول درآمد را داشته باشد.
    // ==========================================================

    if (globalRole == 'owner') {
      return const IncomeAccess(
        canView: true,
        canViewCategories: true,
        canManageCategories: true,
        canViewPeriods: true,
        canCreatePeriods: true,
        canEnterPeriods: true,
        canSubmitPeriods: true,
        canViewRecognition: true,
        canEnterRecognition: true,
        canViewReceivables: true,
        canEnterReceivables: true,
        canViewReports: true,
        canViewAlerts: true,
      );
    }

    // ==========================================================
    // COMPANY MEMBERSHIP
    // ==========================================================

    final companyUser = await client
        .from('company_users')
        .select(
      'id, company_id, user_id, role, is_active',
    )
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'user_id',
      user.id,
    )
        .eq(
      'is_active',
      true,
    )
        .maybeSingle();

    // ==========================================================
    // COMPANY OWNER
    //
    // حتی اگر company_users رکورد نداشته باشد، مالک شرکت
    // باید دسترسی کامل داشته باشد.
    // ==========================================================

    final companyRow = await client
        .from('companies')
        .select(
      'id, owner_user_id, owner_id',
    )
        .eq(
      'id',
      companyId,
    )
        .maybeSingle();

    if (companyRow != null) {
      final ownerUserId =
      companyRow['owner_user_id']
          ?.toString();

      final ownerId =
      companyRow['owner_id']
          ?.toString();

      if (ownerUserId == user.id ||
          ownerId == user.id) {
        return const IncomeAccess(
          canView: true,
          canViewCategories: true,
          canManageCategories: true,
          canViewPeriods: true,
          canCreatePeriods: true,
          canEnterPeriods: true,
          canSubmitPeriods: true,
          canViewRecognition: true,
          canEnterRecognition: true,
          canViewReceivables: true,
          canEnterReceivables: true,
          canViewReports: true,
          canViewAlerts: true,
        );
      }
    }

    // ==========================================================
    // COMPANY ROLE
    // ==========================================================

    final companyRole =
    companyUser?['role']?.toString();

    // اگر عضویت شرکت وجود دارد، نقش شرکت را ملاک قرار می‌دهیم.
    if (companyRole != null &&
        companyRole.isNotEmpty) {
      return _accessForRole(companyRole);
    }

    // ==========================================================
    // GLOBAL NON-OWNER ROLE
    // ==========================================================

    if (globalRole != null &&
        globalRole.isNotEmpty) {
      return _accessForRole(globalRole);
    }

    return const IncomeAccess.none();
  },
);

// ============================================================
// ROLE → ACCESS
// ============================================================

IncomeAccess _accessForRole(String role) {
  switch (role) {
  // ----------------------------------------------------------
  // ACCOUNTANT
  // ----------------------------------------------------------

    case 'accountant':
      return const IncomeAccess(
        canView: true,
        canViewCategories: true,
        canManageCategories: true,
        canViewPeriods: true,
        canCreatePeriods: true,
        canEnterPeriods: true,
        canSubmitPeriods: true,
        canViewRecognition: true,
        canEnterRecognition: true,
        canViewReceivables: true,
        canEnterReceivables: true,
        canViewReports: true,
        canViewAlerts: false,
      );

  // ----------------------------------------------------------
  // COMPANY ADMIN
  // ----------------------------------------------------------

    case 'company_admin':
      return const IncomeAccess(
        canView: true,
        canViewCategories: true,
        canManageCategories: true,
        canViewPeriods: true,
        canCreatePeriods: true,
        canEnterPeriods: false,
        canSubmitPeriods: false,
        canViewRecognition: true,
        canEnterRecognition: false,
        canViewReceivables: true,
        canEnterReceivables: false,
        canViewReports: true,
        canViewAlerts: true,
      );

  // ----------------------------------------------------------
  // CONSULTANT
  // ----------------------------------------------------------

    case 'consultant':
      return const IncomeAccess(
        canView: true,
        canViewCategories: true,
        canManageCategories: false,
        canViewPeriods: true,
        canCreatePeriods: false,
        canEnterPeriods: false,
        canSubmitPeriods: false,
        canViewRecognition: true,
        canEnterRecognition: false,
        canViewReceivables: true,
        canEnterReceivables: false,
        canViewReports: true,
        canViewAlerts: true,
      );

  // ----------------------------------------------------------
  // CASHIER
  // ----------------------------------------------------------

    case 'cashier':
      return const IncomeAccess(
        canView: true,
        canViewCategories: false,
        canManageCategories: false,
        canViewPeriods: false,
        canCreatePeriods: false,
        canEnterPeriods: false,
        canSubmitPeriods: false,
        canViewRecognition: false,
        canEnterRecognition: false,
        canViewReceivables: false,
        canEnterReceivables: false,
        canViewReports: false,
        canViewAlerts: false,
      );

  // ----------------------------------------------------------
  // HR / WAREHOUSE / UNKNOWN
  // ----------------------------------------------------------

    default:
      return const IncomeAccess.none();
  }
}

// ============================================================
// ACCESS MODEL
// ============================================================

class IncomeAccess {
  final bool canView;

  final bool canViewCategories;
  final bool canManageCategories;

  final bool canViewPeriods;
  final bool canCreatePeriods;
  final bool canEnterPeriods;
  final bool canSubmitPeriods;

  final bool canViewRecognition;
  final bool canEnterRecognition;

  final bool canViewReceivables;
  final bool canEnterReceivables;

  final bool canViewReports;
  final bool canViewAlerts;

  const IncomeAccess({
    required this.canView,
    required this.canViewCategories,
    required this.canManageCategories,
    required this.canViewPeriods,
    required this.canCreatePeriods,
    required this.canEnterPeriods,
    required this.canSubmitPeriods,
    required this.canViewRecognition,
    required this.canEnterRecognition,
    required this.canViewReceivables,
    required this.canEnterReceivables,
    required this.canViewReports,
    required this.canViewAlerts,
  });

  const IncomeAccess.none()
      : canView = false,
        canViewCategories = false,
        canManageCategories = false,
        canViewPeriods = false,
        canCreatePeriods = false,
        canEnterPeriods = false,
        canSubmitPeriods = false,
        canViewRecognition = false,
        canEnterRecognition = false,
        canViewReceivables = false,
        canEnterReceivables = false,
        canViewReports = false,
        canViewAlerts = false;

  bool get hasAnyAccess =>
      canView ||
          canViewCategories ||
          canViewPeriods ||
          canViewRecognition ||
          canViewReceivables ||
          canViewReports ||
          canViewAlerts;
}