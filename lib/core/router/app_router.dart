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
import 'package:tarazyar/consultant/companies/banking/presentation/pages/bank_loans_report_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/banking_alerts_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/banking_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/banking_reports_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/cash_boxes_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/cash_ceo_review_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/cash_consultant_review_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/cash_fiscal_periods_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/paid_checks_report_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/petty_cash_accounts_page.dart';
import 'package:tarazyar/consultant/companies/banking/presentation/pages/received_checks_report_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_monthly_report_page.dart';

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
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_fiscal_periods_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_monthly_report_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_receivables_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_recognition_page.dart';

// ============================================================
// EXPENSES
// ============================================================

import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_categories_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_fiscal_periods_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_recognition_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_records_page.dart';

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

    refreshListenable: GoRouterRefreshStream(
      client.auth.onAuthStateChange,
    ),

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

      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),

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
          return CompanyOverviewPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // BANKING
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/banking',
        builder: (context, state) {
          return BankingDashboardPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/fiscal-periods',
        builder: (context, state) {
          return CashFiscalPeriodsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/accounts',
        builder: (context, state) {
          return BankAccountsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/cash-boxes',
        builder: (context, state) {
          return CashBoxesPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/petty-cash',
        builder: (context, state) {
          return PettyCashAccountsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/ceo-review/:periodId',
        builder: (context, state) {
          return CashCeoReviewPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/consultant-review/:periodId',
        builder: (context, state) {
          return CashConsultantReviewPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/reports',
        builder: (context, state) {
          return BankingReportsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/alerts',
        builder: (context, state) {
          return BankingAlertsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/loans',
        builder: (context, state) {
          return BankLoansReportPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/received-checks',
        builder: (context, state) {
          return ReceivedChecksReportPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/banking/paid-checks',
        builder: (context, state) {
          return PaidChecksReportPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      // ======================================================
      // PAYROLL
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/payroll',
        builder: (context, state) {
          return PayrollDashboardPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/employees',
        builder: (context, state) {
          return EmployeesPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/contracts',
        builder: (context, state) {
          return EmploymentContractsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/periods',
        builder: (context, state) {
          return PayrollPeriodsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/payroll/cost-centers',
        builder: (context, state) {
          return CostCentersPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // INCOME
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/income',
        builder: (context, state) {
          return IncomeDashboardPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/periods',
        builder: (context, state) {
          return IncomeFiscalPeriodsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/categories',
        builder: (context, state) {
          return IncomeCategoriesPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/recognition/:periodId',
        builder: (context, state) {
          return IncomeRecognitionPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/receivables/:periodId',
        builder: (context, state) {
          return IncomeReceivablesPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/reports',
        builder: (context, state) {
          return IncomeMonthlyReportPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      // ======================================================
      // EXPENSES
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/expenses',
        builder: (context, state) {
          return ExpenseDashboardPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/expenses/periods',
        builder: (context, state) {
          return ExpenseFiscalPeriodsPage(
            companyId: state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/expenses/recognition/:periodId',
        builder: (context, state) {
          return ExpenseRecognitionPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/expenses/reports/:periodId',
        builder: (context, state) {
          return ExpenseMonthlyReportPage(
            companyId: state.pathParameters['companyId']!,
            periodId: state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/expenses/records',
        builder: (context, state) {
          return ExpenseRecordsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:id/expenses/categories',
        builder: (context, state) {
          return ExpenseCategoriesPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY REPORTS
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/reports',
        builder: (context, state) {
          return CompanyReportsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY ACTIONS
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/actions',
        builder: (context, state) {
          return CompanyActionsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY WORKFLOW
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/workflow',
        builder: (context, state) {
          return CompanyWorkflowPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY DOCUMENTS
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/documents',
        builder: (context, state) {
          return CompanyDocumentsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY NOTES
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/notes',
        builder: (context, state) {
          return CompanyNotesPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // COMPANY ANALYTICS
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/analytics',
        builder: (context, state) {
          return CompanyAnalyticsPage(
            companyId: state.pathParameters['id']!,
          );
        },
      ),

      // ======================================================
      // CONSULTANT FINANCIAL ANALYSIS
      // ======================================================

      GoRoute(
        path: '/consultant/companies/:id/financial-analysis',
        builder: (context, state) {
          return FinancialAnalysisPage(
            companyId: state.pathParameters['id']!,
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
      // OWNER
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