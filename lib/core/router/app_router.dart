import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// AUTHENTICATION
// ============================================================

import 'package:tarazyar/authentication/application/auth_service.dart';
import 'package:tarazyar/authentication/presentation/pages/invite_acceptance_page.dart';
import 'package:tarazyar/authentication/presentation/pages/login_page.dart';
import 'package:tarazyar/authentication/presentation/pages/splash_page.dart';

// ============================================================
// BANKING
// ============================================================

import 'package:tarazyar/consultant/companies/banking/presentation/pages/bank_accounts_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/bank_loans_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/banking_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/cash_boxes_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/paid_checks_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/petty_cash_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/received_checks_page.dart';

// ============================================================
// EXPENSES
// ============================================================

import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_categories_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_records_page.dart';

// ============================================================
// PAYROLL
// ============================================================

import 'package:tarazyar/consultant/companies/payroll/presentation/pages/cost_centers_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/employees_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/employment_contracts_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/payroll_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/payroll_periods_page.dart';

// ============================================================
// INCOME
// ============================================================

import 'package:tarazyar/consultant/companies/income/presentation/pages/income_categories_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_records_page.dart';

// ============================================================
// COMPANY
// ============================================================

import 'package:tarazyar/consultant/companies/presentation/pages/company_dashboard_page.dart'
    show CompanyDashboardPage, CompanyOverviewPage;

// ============================================================
// CONSULTANT DASHBOARD
// ============================================================

import 'package:tarazyar/consultant/dashboard/analytics/pages/consultant_analytics_page.dart';
import 'package:tarazyar/consultant/dashboard/history/presentation/pages/consultant_history_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_actions_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_analytics_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_documents_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_notes_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_reports_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_workflow_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/consultant_companies_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/consultant_page.dart';
import 'package:tarazyar/consultant/dashboard/reports/presentation/pages/consultant_reports_page.dart';
import 'package:tarazyar/consultant/dashboard/settings/presentation/pages/consultant_settings_page.dart';
import 'package:tarazyar/consultant/dashboard/workflow/presentation/pages/consultant_workflow_page.dart';

// ============================================================
// OWNER
// ============================================================

import 'package:tarazyar/owner/companies/presentation/pages/companies_page.dart';
import 'package:tarazyar/owner/dashboard/presentation/pages/owner_page.dart';
import 'package:tarazyar/owner/reports/presentation/pages/reportspage.dart';
import 'package:tarazyar/owner/settings/presentation/pages/settings_page.dart';
import 'package:tarazyar/owner/users/presentation/pages/users_page.dart';

// ============================================================
// APP ROUTER
// ============================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;

  bool firstRedirect = true;

  return GoRouter(
    initialLocation: '/login',

    // ========================================================
    // AUTH REFRESH
    // ========================================================
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),

    // ========================================================
    // REDIRECT
    // ========================================================
    redirect: (context, state) async {
      final path = state.uri.path;
      final session = client.auth.currentSession;

      // ------------------------------------------------------
      // INVITE
      // ------------------------------------------------------

      if (path == '/auth/invite') {
        return null;
      }

      // ------------------------------------------------------
      // LOGIN
      // ------------------------------------------------------

      if (path == '/login') {
        if (firstRedirect) {
          firstRedirect = false;
          return null;
        }

        if (session == null) {
          return null;
        }

        final authService = AuthService(client);

        final role = await authService.fetchRole(session.user.id);

        if (role == null) {
          return null;
        }

        return AuthService.routeForRole(role);
      }

      // ------------------------------------------------------
      // SESSION REQUIRED
      // ------------------------------------------------------

      if (session == null) {
        return '/login';
      }

      // ------------------------------------------------------
      // ROLE
      // ------------------------------------------------------

      final authService = AuthService(client);

      final role = await authService.fetchRole(session.user.id);

      if (role == null) {
        return '/login';
      }

      // ------------------------------------------------------
      // ROOT / SPLASH
      // ------------------------------------------------------

      final target = AuthService.routeForRole(role);

      if (path == '/' || path == '/splash') {
        return target;
      }

      // ------------------------------------------------------
      // OWNER
      // ------------------------------------------------------

      if (role == 'owner') {
        if (path == '/owner' || path.startsWith('/owner/')) {
          return null;
        }

        return '/owner';
      }

      // ------------------------------------------------------
      // CONSULTANT
      // ------------------------------------------------------

      if (role == 'consultant') {
        if (path == '/consultant' || path.startsWith('/consultant/')) {
          return null;
        }

        return '/consultant';
      }

      return '/login';
    },

    // ========================================================
    // ROUTES
    // ========================================================
    routes: [
      // ======================================================
      // ROOT
      // ======================================================
      GoRoute(path: '/', redirect: (_, __) => '/login'),

      // ======================================================
      // SPLASH
      // ======================================================
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // ======================================================
      // LOGIN
      // ======================================================
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // ======================================================
      // INVITE
      // ======================================================
      GoRoute(
        path: '/auth/invite',
        builder: (context, state) {
          return const InviteAcceptancePage();
        },
      ),

      // ======================================================
      // CONSULTANT
      // ======================================================
      GoRoute(
        path: '/consultant',
        builder: (context, state) {
          return const ConsultantPage();
        },
      ),

      // ======================================================
      // CONSULTANT COMPANIES
      // ======================================================
      GoRoute(
        path: '/consultant/companies',
        builder: (context, state) {
          return const ConsultantCompaniesPage();
        },
      ),

      // ======================================================
      // COMPANY DASHBOARD
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyOverviewPage(companyId: id);
        },
      ),

      // ======================================================
      // ======================================================
      // BANKING
      // ======================================================
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/banking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return BankingDashboardPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/accounts',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return BankAccountsPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/cash-boxes',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CashBoxesPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/received-checks',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return ReceivedChecksPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/paid-checks',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return PaidChecksPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/petty-cash',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return PettyCashPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/banking/loans',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return BankLoansPage(companyId: id);
        },
      ),

      // ======================================================
      // ======================================================
      // PAYROLL
      // ======================================================
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/payroll',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return PayrollDashboardPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/employees',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return EmployeesPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/contracts',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return EmploymentContractsPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/periods',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return PayrollPeriodsPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/cost-centers',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CostCentersPage(companyId: id);
        },
      ),

      // ======================================================
      // ======================================================
      // INCOME
      // ======================================================
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/income',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return IncomeDashboardPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/income/records',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return IncomeRecordsPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/income/categories',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return IncomeCategoriesPage(companyId: id);
        },
      ),

      // ======================================================
      // ======================================================
      // EXPENSES
      // ======================================================
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/expenses',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return ExpenseDashboardPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/expenses/records',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return ExpenseRecordsPage(companyId: id);
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/expenses/categories',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return ExpenseCategoriesPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY REPORTS
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/reports',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyReportsPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY ACTIONS
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/actions',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyActionsPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY WORKFLOW
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/workflow',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyWorkflowPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY DOCUMENTS
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/documents',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyDocumentsPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY NOTES
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/notes',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyNotesPage(companyId: id);
        },
      ),

      // ======================================================
      // COMPANY ANALYTICS
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/analytics',
        builder: (context, state) {
          final id = state.pathParameters['id']!;

          return CompanyAnalyticsPage(companyId: id);
        },
      ),

      // ======================================================
      // CONSULTANT ANALYTICS
      // ======================================================
      GoRoute(
        path: '/consultant/companies/:id/financial-analysis',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;

          return FinancialAnalysisPage(
            companyId: companyId,
          );
        },
      ),

      // ======================================================
      // CONSULTANT REPORTS
      // ======================================================
      GoRoute(
        path: '/consultant/reports',
        builder: (context, state) {
          return const ConsultantReportsPage();
        },
      ),

      // ======================================================
      // CONSULTANT WORKFLOW
      // ======================================================
      GoRoute(
        path: '/consultant/workflow',
        builder: (context, state) {
          return const ConsultantWorkflowPage();
        },
      ),

      // ======================================================
      // CONSULTANT HISTORY
      // ======================================================
      GoRoute(
        path: '/consultant/history',
        builder: (context, state) {
          return const ConsultantHistoryPage();
        },
      ),

      // ======================================================
      // CONSULTANT SETTINGS
      // ======================================================
      GoRoute(
        path: '/consultant/settings',
        builder: (context, state) {
          return const ConsultantSettingsPage();
        },
      ),

      // ======================================================
      // ======================================================
      // OWNER
      // ======================================================
      // ======================================================
      GoRoute(
        path: '/owner',
        builder: (context, state) {
          return const OwnerPage();
        },
      ),

      GoRoute(
        path: '/owner/companies',
        builder: (context, state) {
          return const CompaniesPage();
        },
      ),

      GoRoute(
        path: '/owner/users',
        builder: (context, state) {
          return const UsersPage();
        },
      ),

      GoRoute(
        path: '/owner/reports',
        builder: (context, state) {
          return const ReportsPage();
        },
      ),

      GoRoute(
        path: '/owner/settings',
        builder: (context, state) {
          return const SettingsPage();
        },
      ),
    ],
  );
});

// ============================================================
// GO ROUTER AUTH REFRESH
// ============================================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
