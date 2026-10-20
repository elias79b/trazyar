

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
// ACCOUNTANT DASHBOARD
// ============================================================

import 'package:tarazyar/accountant/dashboard/application/accountant_dashboard_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/pages/accountant_page.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

// ============================================================
// ACCOUNTANT BANKING
// ============================================================

import 'package:tarazyar/accountant/banking/presentation/pages/accountant_banking_dashboard_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_banking_reports_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_bank_accounts_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_cash_boxes_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_petty_cash_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_bank_loans_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_received_checks_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_paid_checks_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_fiscal_periods_page.dart';
import 'package:tarazyar/accountant/banking/presentation/pages/accountant_fiscal_period_entry_page.dart';

// ============================================================
// ACCOUNTANT PAYROLL
// ============================================================

import 'package:tarazyar/accountant/payroll/pages/accountant_payroll_dashboard_page.dart';
import 'package:tarazyar/accountant/payroll/pages/accountant_payroll_employees_page.dart';
import 'package:tarazyar/accountant/payroll/pages/accountant_payroll_contracts_page.dart';
import 'package:tarazyar/accountant/payroll/pages/accountant_payroll_periods_page.dart';
import 'package:tarazyar/accountant/payroll/pages/accountant_payroll_records_page.dart';
import 'package:tarazyar/accountant/payroll/pages/accountant_cost_centers_page.dart';

// ============================================================
// ACCOUNTANT INCOME
// ============================================================

import 'package:tarazyar/accountant/income/application/accountant_income_fiscal_periods_provider.dart';
import 'package:tarazyar/accountant/income/presentation/pages/accountant_income_dashboard_page.dart';
import 'package:tarazyar/accountant/income/presentation/pages/accountant_income_fiscal_periods_page.dart';
import 'package:tarazyar/accountant/income/presentation/pages/accountant_income_categories_page.dart';
import 'package:tarazyar/accountant/income/presentation/pages/accountant_income_recognition_page.dart';
import 'package:tarazyar/accountant/income/presentation/pages/accountant_income_receivables_page.dart';


// ============================================================
// ACCOUNTANT EXPENSES
// ============================================================

import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_expense_dashboard_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_expense_fiscal_periods_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_expense_categories_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_expense_recognition_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_expense_reports_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_payable_fiscal_periods_page.dart';
import 'package:tarazyar/accountant/expenses/presentation/pages/accountant_payable_period_page.dart';

// ============================================================
// COMPANY ADMIN / CEO BANKING
// ============================================================

import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_bank_accounts_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_bank_loans_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_banking_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_cash_boxes_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_cash_fiscal_periods_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_paid_checks_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_petty_cash_page.dart';
import 'package:tarazyar/company_admin/banking/presentation/pages/company_admin_received_checks_page.dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_categories_page%20(1).dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_dashboard_page%20(1).dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_period_details_page%20(1).dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_periods_page%20(2).dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_recognitions_page%20(1).dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_expense_reports_page_fixed2.dart';
import 'package:tarazyar/company_admin/expense/presentation/pages/company_admin_payables_page_workflow_fixed.dart';

// ============================================================
// CONSULTANT BANKING
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
import 'package:tarazyar/consultant/companies/income/presentation/pages/expense_payables_period_detail_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/expense_payables_periods_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/expense_payables_years_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_receivable_years_page.dart';

// ============================================================
// CONSULTANT PAYROLL
// ============================================================

import 'package:tarazyar/consultant/companies/payroll/presentation/pages/cost_centers_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/employees_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/employment_contracts_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/payroll_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/payroll/presentation/pages/payroll_periods_page.dart';

// ============================================================
// CONSULTANT INCOME
// ============================================================

import 'package:tarazyar/consultant/companies/income/presentation/pages/income_categories_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_fiscal_periods_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_monthly_report_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_receivables_page.dart';
import 'package:tarazyar/consultant/companies/income/presentation/pages/income_recognition_page.dart';

// ============================================================
// CONSULTANT EXPENSES
// ============================================================

import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_categories_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_dashboard_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_fiscal_periods_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_recognition_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_records_page.dart';
import 'package:tarazyar/consultant/companies/expenses/presentation/pages/expense_monthly_report_page.dart';

// ============================================================
// COMPANY
// ============================================================

import 'package:tarazyar/consultant/companies/presentation/pages/company_dashboard_page.dart'
    show CompanyDashboardPage, CompanyOverviewPage;

// ============================================================
// CONSULTANT DASHBOARD
// ============================================================

import 'package:tarazyar/consultant/dashboard/analytics/pages/consultant_analytics_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_actions_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_analytics_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_documents_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_notes_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_reports_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/company_workflow_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/consultant_companies_page.dart';
import 'package:tarazyar/consultant/dashboard/presentation/pages/consultant_page.dart';

// ============================================================
// OWNER
// ============================================================

import 'package:tarazyar/owner/companies/presentation/pages/companies_page.dart';
import 'package:tarazyar/owner/dashboard/presentation/pages/owner_page.dart';
import 'package:tarazyar/owner/reports/presentation/pages/reportspage.dart';
import 'package:tarazyar/owner/settings/presentation/pages/settings_page.dart';
import 'package:tarazyar/owner/users/presentation/pages/users_page.dart';

// ============================================================
// COMPANY ADMIN / CEO DASHBOARD
// ============================================================

import 'package:tarazyar/company_admin/dashboard/presentation/pages/company_admin_dashboard_page.dart';

// ============================================================
// ROUTER
// ============================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/login',

    refreshListenable: GoRouterRefreshStream(
      client.auth.onAuthStateChange,
    ),

    redirect: (context, state) async {
      final path = state.uri.path;
      final session = client.auth.currentSession;

      // --------------------------------------------------------
      // INVITE
      // --------------------------------------------------------

      if (path == '/auth/invite') {
        return null;
      }

      // --------------------------------------------------------
      // LOGIN
      // --------------------------------------------------------

      // --------------------------------------------------------
      // NO SESSION
      // --------------------------------------------------------

      if (session == null) {
        if (path == '/login' || path == '/auth/invite') {
          return null;
        }

        return '/login';
      }

      // --------------------------------------------------------
      // AUTH REQUIRED / ROLE
      // --------------------------------------------------------

      final authService = AuthService(client);

      final role = await authService.fetchRole(
        session.user.id,
      );

      if (role == null) {
        return '/login';
      }

      final target = AuthService.routeForRole(role);

      // --------------------------------------------------------
      // ROOT / SPLASH
      // --------------------------------------------------------

      if (path == '/' || path == '/splash') {
        return target;
      }

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      if (role == 'owner') {
        if (
        path == '/owner' ||
            path.startsWith('/owner/')
        ) {
          return null;
        }

        return '/owner';
      }

      // --------------------------------------------------------
      // CONSULTANT
      // --------------------------------------------------------

      if (role == 'consultant') {
        if (
        path == '/consultant' ||
            path.startsWith('/consultant/')
        ) {
          return null;
        }

        return '/consultant';
      }

      // --------------------------------------------------------
      // ACCOUNTANT
      // --------------------------------------------------------

      if (role == 'accountant') {
        if (
        path == '/accountant' ||
            path.startsWith('/accountant/')
        ) {
          return null;
        }

        return '/accountant';
      }

      // --------------------------------------------------------
      // COMPANY ADMIN / CEO
      // --------------------------------------------------------

      if (role == 'company_admin') {
        if (
        path == '/company-admin' ||
            path.startsWith('/company-admin/')
        ) {
          return null;
        }

        return '/company-admin';
      }

      return '/login';
    },

    routes: [

      // ========================================================
      // ROOT
      // ========================================================

      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),

      // ========================================================
      // SPLASH
      // ========================================================

      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // ========================================================
      // LOGIN
      // ========================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // ========================================================
      // INVITE
      // ========================================================

      GoRoute(
        path: '/auth/invite',
        builder: (context, state) {
          return const InviteAcceptancePage();
        },
      ),

      // ========================================================
      // ACCOUNTANT DASHBOARD
      // ========================================================

      GoRoute(
        path: '/accountant',
        builder: (context, state) {
          return const AccountantPage();
        },
      ),

      // ========================================================
      // COMPANY ADMIN / CEO
      // ========================================================

      GoRoute(
        path: '/company-admin',
        builder: (context, state) {
          return const CompanyAdminDashboardPage();
        },
      ),

      // ========================================================
      // COMPANY ADMIN BANKING
      // ========================================================

      GoRoute(
        path: '/company-admin/banking',
        builder: (context, state) {
          return const CompanyAdminBankingPage();
        },
      ),

      // --------------------------------------------------------
      // BANK ACCOUNTS
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/accounts',
        builder: (context, state) {
          return const CompanyAdminBankAccountsPage();
        },
      ),

      // --------------------------------------------------------
      // CASH BOXES
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/cash-boxes',
        builder: (context, state) {
          return const CompanyAdminCashBoxesPage();
        },
      ),

      // --------------------------------------------------------
      // PETTY CASH
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/petty-cash',
        builder: (context, state) {
          return const CompanyAdminPettyCashPage();
        },
      ),

      // --------------------------------------------------------
      // BANK LOANS
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/loans',
        builder: (context, state) {
          return const CompanyAdminBankLoansPage();
        },
      ),

      // --------------------------------------------------------
      // RECEIVED CHECKS
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/received-checks',
        builder: (context, state) {
          return const CompanyAdminReceivedChecksPage();
        },
      ),

      // --------------------------------------------------------
      // PAID CHECKS
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/paid-checks',
        builder: (context, state) {
          return const CompanyAdminPaidChecksPage();
        },
      ),

      // --------------------------------------------------------
      // FISCAL PERIODS LIST
      // --------------------------------------------------------

      GoRoute(
        path: '/company-admin/banking/fiscal-periods',
        builder: (context, state) {
          return const CompanyAdminCashFiscalPeriodsPage();
        },
      ),

      // --------------------------------------------------------
      // FISCAL PERIOD DETAIL
      // --------------------------------------------------------
      // --------------------------------------------------------

      GoRoute(
        path:
        '/company-admin/banking/fiscal-periods/:periodId',
        builder: (context, state) {
          final periodId =
          state.pathParameters['periodId'];

          if (
          periodId == null ||
              periodId.isEmpty
          ) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره مالی معتبر نیست',
                  textDirection:
                  TextDirection.rtl,
                ),
              ),
            );
          }

          return CompanyAdminCashFiscalPeriodDetailsPage(
            periodId: periodId,
          );
        },
      ),

      // ========================================================
      // ACCOUNTANT PAYROLL
      // ========================================================

      GoRoute(
        path: '/accountant/payroll',
        builder: (context, state) {
          return const AccountantPayrollDashboardRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/payroll/employees',
        builder: (context, state) {
          return const AccountantPayrollEmployeesRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/payroll/contracts',
        builder: (context, state) {
          return const AccountantPayrollContractsRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/payroll/cost-centers',
        builder: (context, state) {
          return const AccountantCostCentersRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/payroll/periods',
        builder: (context, state) {
          return const AccountantPayrollPeriodsRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/payroll/records/:periodId',
        builder: (context, state) {
          final periodId =
          state.pathParameters['periodId'];

          if (
          periodId == null ||
              periodId.isEmpty
          ) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره حقوق معتبر نیست',
                  textDirection:
                  TextDirection.rtl,
                ),
              ),
            );
          }

          return AccountantPayrollRecordsPage(
            periodId: periodId,
          );
        },
      ),

      // ========================================================
      // ACCOUNTANT BANKING
      // ========================================================

      GoRoute(
        path: '/accountant/banking',
        builder: (context, state) {
          return const AccountantBankingDashboardRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/accounts',
        builder: (context, state) {
          return const AccountantBankAccountsRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/cash-boxes',
        builder: (context, state) {
          return const AccountantCashBoxesRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/petty-cash',
        builder: (context, state) {
          return const AccountantPettyCashRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/loans',
        builder: (context, state) {
          return const AccountantBankLoansRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/received-checks',
        builder: (context, state) {
          return const AccountantReceivedChecksRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/paid-checks',
        builder: (context, state) {
          return const AccountantPaidChecksRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/banking/fiscal-periods',
        builder: (context, state) {
          return const AccountantFiscalPeriodsRoutePage();
        },
      ),

      GoRoute(
        path:
        '/accountant/banking/fiscal-periods/:periodId',
        builder: (context, state) {
          final periodId =
          state.pathParameters['periodId'];

          if (
          periodId == null ||
              periodId.isEmpty
          ) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره مالی معتبر نیست',
                  textDirection:
                  TextDirection.rtl,
                ),
              ),
            );
          }

          return AccountantFiscalPeriodEntryPage(
            periodId: periodId,
          );
        },
      ),

      GoRoute(
        path: '/accountant/banking/reports',
        builder: (context, state) {
          return const AccountantBankingReportsRoutePage();
        },
      ),


      // ========================================================
      // ACCOUNTANT EXPENSES
      // ========================================================

      GoRoute(
        path: '/accountant/expenses',
        builder: (context, state) =>
        const AccountantExpenseDashboardRoutePage(),
      ),

      GoRoute(
        path: '/accountant/expenses/periods',
        builder: (context, state) =>
        const AccountantExpenseFiscalPeriodsRoutePage(),
      ),

      GoRoute(
        path: '/accountant/expenses/categories',
        builder: (context, state) =>
        const AccountantExpenseCategoriesRoutePage(),
      ),

      GoRoute(
        path: '/accountant/expenses/recognition/:periodId',
        builder: (context, state) {
          final periodId = state.pathParameters['periodId'];
          if (periodId == null || periodId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره هزینه معتبر نیست',
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          }
          return AccountantExpenseRecognitionRoutePage(
            periodId: periodId,
          );
        },
      ),

      GoRoute(
        path: '/accountant/expenses/reports',
        builder: (context, state) =>
        const AccountantExpenseReportsRoutePage(),
      ),

      GoRoute(
        path: '/accountant/expenses/payables/periods',
        builder: (context, state) =>
        const AccountantPayableFiscalPeriodsRoutePage(),
      ),

      GoRoute(
        path: '/accountant/expenses/payables/periods/:periodId',
        builder: (context, state) {
          final periodId = state.pathParameters['periodId'];
          if (periodId == null || periodId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره پرداختنی معتبر نیست',
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          }
          return AccountantPayablePeriodRoutePage(
            periodId: periodId,
          );
        },
      ),
      GoRoute(
        path: '/company-admin/expenses/reports',
        builder: (context, state) => const CompanyAdminExpenseReportsPage(),
      ),


      // ========================================================
      // ACCOUNTANT INCOME
      // ========================================================

      GoRoute(
        path: '/accountant/income',
        builder: (context, state) {
          return const AccountantIncomeDashboardRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/income/periods',
        builder: (context, state) {
          return const AccountantIncomeFiscalPeriodsRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/income/categories',
        builder: (context, state) {
          return const AccountantIncomeCategoriesRoutePage();
        },
      ),

      GoRoute(
        path: '/accountant/income/recognition',
        builder: (context, state) {
          return const AccountantIncomeRecognitionRoutePage();
        },
      ),

      GoRoute(
        path:
        '/accountant/income/recognition/:periodId',
        builder: (context, state) {
          final periodId =
          state.pathParameters['periodId'];

          if (
          periodId == null ||
              periodId.isEmpty
          ) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه دوره درآمد معتبر نیست',
                  textDirection:
                  TextDirection.rtl,
                ),
              ),
            );
          }

          return AccountantIncomeRecognitionPage(
            periodId: periodId,
          );
        },
      ),

      // ========================================================
      // ACCOUNTANT RECEIVABLES
      // ========================================================

      GoRoute(
        path: '/accountant/income/receivables',
        builder: (context, state) {
          return const AccountantReceivablePeriodsRoutePage();
        },
      ),

      GoRoute(
        path:
        '/accountant/income/receivables/:periodId',
        builder: (context, state) {
          final periodId =
          state.pathParameters['periodId'];

          if (
          periodId == null ||
              periodId.isEmpty
          ) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'شناسه ماه مطالبات معتبر نیست',
                  textDirection:
                  TextDirection.rtl,
                ),
              ),
            );
          }

          return AccountantReceivablesMonthRoutePage(
            periodId: periodId,
          );
        },
      ),

      // ========================================================
      // CONSULTANT
      // ========================================================

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

      // ========================================================
      // COMPANY
      // ========================================================

      GoRoute(
        path: '/consultant/companies/:id',
        builder: (context, state) {
          return CompanyOverviewPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // CONSULTANT BANKING
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/banking',
        builder: (context, state) {
          return BankingDashboardPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/fiscal-periods',
        builder: (context, state) {
          return CashFiscalPeriodsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/accounts',
        builder: (context, state) {
          return BankAccountsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/cash-boxes',
        builder: (context, state) {
          return CashBoxesPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/petty-cash',
        builder: (context, state) {
          return PettyCashAccountsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/ceo-review/:periodId',
        builder: (context, state) {
          return CashCeoReviewPage(
            companyId:
            state.pathParameters['companyId']!,
            periodId:
            state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/consultant-review/:periodId',
        builder: (context, state) {
          return CashConsultantReviewPage(
            companyId:
            state.pathParameters['companyId']!,
            periodId:
            state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/reports',
        builder: (context, state) {
          return BankingReportsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/alerts',
        builder: (context, state) {
          return BankingAlertsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/loans',
        builder: (context, state) {
          return BankLoansReportPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/received-checks',
        builder: (context, state) {
          return ReceivedChecksReportPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/banking/paid-checks',
        builder: (context, state) {
          return PaidChecksReportPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      // ========================================================
      // CONSULTANT PAYROLL
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/payroll',
        builder: (context, state) {
          return PayrollDashboardPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/payroll/employees',
        builder: (context, state) {
          return EmployeesPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/payroll/contracts',
        builder: (context, state) {
          return EmploymentContractsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/payroll/periods',
        builder: (context, state) {
          return PayrollPeriodsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/payroll/cost-centers',
        builder: (context, state) {
          return CostCentersPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // CONSULTANT INCOME
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/income',
        builder: (context, state) {
          return IncomeDashboardPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/income/periods',
        builder: (context, state) {
          return IncomeFiscalPeriodsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/income/categories',
        builder: (context, state) {
          return IncomeCategoriesPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/income/recognition/:periodId',
        builder: (context, state) {
          return IncomeRecognitionPage(
            companyId:
            state.pathParameters['companyId']!,
            periodId:
            state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path: '/consultant/companies/:companyId/income/receivables',
        builder: (context, state) => IncomeReceivableYearsPage(
          companyId: state.pathParameters['companyId']!,
        ),
      ),
      GoRoute(
        path: '/consultant/companies/:companyId/income/receivables/:periodId',
        builder: (context, state) => IncomeReceivablesPage(
          companyId: state.pathParameters['companyId']!,
          periodId: state.pathParameters['periodId']!,
        ),
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/income/reports',
        builder: (context, state) {
          return IncomeMonthlyReportPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      // ========================================================
      // CONSULTANT EXPENSES
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/expenses',
        builder: (context, state) {
          return ExpenseDashboardPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/expenses/periods',
        builder: (context, state) {
          return ExpenseFiscalPeriodsPage(
            companyId:
            state.pathParameters['companyId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/expenses/recognition/:periodId',
        builder: (context, state) {
          return ExpenseRecognitionPage(
            companyId:
            state.pathParameters['companyId']!,
            periodId:
            state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:companyId/expenses/reports/:periodId',
        builder: (context, state) {
          return ExpenseMonthlyReportPage(
            companyId:
            state.pathParameters['companyId']!,
            periodId:
            state.pathParameters['periodId']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/expenses/records',
        builder: (context, state) {
          return ExpenseRecordsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path:
        '/consultant/companies/:id/expenses/categories',
        builder: (context, state) {
          return ExpenseCategoriesPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),
      GoRoute(
        path: '/consultant/companies/:id/expenses/payables',
        builder: (context, state) => PayableConsultantYearsPage(
          companyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consultant/companies/:companyId/expenses/payables/years/:yearId',
        builder: (context, state) => PayableConsultantPeriodsPage(
          companyId: state.pathParameters['companyId']!,
          yearId: state.pathParameters['yearId']!,
        ),
      ),
      GoRoute(
        path: '/consultant/companies/:companyId/expenses/payables/periods/:periodId',
        builder: (context, state) => PayableConsultantPeriodDetailPage(
          companyId: state.pathParameters['companyId']!,
          periodId: state.pathParameters['periodId']!,
        ),
      ),

      // ========================================================
      // COMPANY REPORTS
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/reports',
        builder: (context, state) {
          return CompanyReportsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // COMPANY ACTIONS
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/actions',
        builder: (context, state) {
          return CompanyActionsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // COMPANY WORKFLOW
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/workflow',
        builder: (context, state) {
          return CompanyWorkflowPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // COMPANY DOCUMENTS
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/documents',
        builder: (context, state) {
          return CompanyDocumentsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // COMPANY NOTES
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/notes',
        builder: (context, state) {
          return CompanyNotesPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      // ========================================================
      // COMPANY ANALYTICS
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/analytics',
        builder: (context, state) {
          return CompanyAnalyticsPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),

      GoRoute(
        path: '/company-admin/expense',
        name: 'company-admin-expense-dashboard',
        builder: (context, state) => const CompanyAdminExpenseDashboardPage(),
      ),

      GoRoute(
        path: '/company-admin/expense/periods',
        name: 'company-admin-expense-periods',
        builder: (context, state) => const CompanyAdminExpensePeriodsPage(),
        routes: [
          GoRoute(
            path: ':periodId',
            name: 'company-admin-expense-period-details',
            builder: (context, state) {
              final periodId = state.pathParameters['periodId']!;
              return CompanyAdminExpensePeriodDetailsPage(periodId: periodId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/company-admin/expense/categories',
        name: 'company-admin-expense-categories',
        builder: (context, state) => const CompanyAdminExpenseCategoriesPage(),
      ),
      GoRoute(
        path: '/company-admin/expense/recognitions',
        name: 'company-admin-expense-recognitions',
        builder:
            (context, state) => const CompanyAdminExpenseRecognitionsPage(),
      ),
      GoRoute(
        path: '/company-admin/expenses/payables',
        builder: (context, state) =>
        const CompanyAdminPayablesPage(),
      ),


      // ========================================================
      // FINANCIAL ANALYSIS
      // ========================================================

      GoRoute(
        path:
        '/consultant/companies/:id/financial-analysis',
        builder: (context, state) {
          return FinancialAnalysisPage(
            companyId:
            state.pathParameters['id']!,
          );
        },
      ),
      // ========================================================
      // OWNER
      // ========================================================

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
// ACCOUNTANT PAYROLL DASHBOARD
// ============================================================

class AccountantPayrollDashboardRoutePage
    extends ConsumerWidget {
  const AccountantPayrollDashboardRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPayrollDashboardPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT PAYROLL EMPLOYEES
// ============================================================

class AccountantPayrollEmployeesRoutePage
    extends ConsumerWidget {
  const AccountantPayrollEmployeesRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPayrollEmployeesPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT PAYROLL CONTRACTS
// ============================================================

class AccountantPayrollContractsRoutePage
    extends ConsumerWidget {
  const AccountantPayrollContractsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPayrollContractsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT COST CENTERS
// ============================================================

class AccountantCostCentersRoutePage
    extends ConsumerWidget {
  const AccountantCostCentersRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantCostCentersPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT PAYROLL PERIODS
// ============================================================

class AccountantPayrollPeriodsRoutePage
    extends ConsumerWidget {
  const AccountantPayrollPeriodsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPayrollPeriodsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT BANKING DASHBOARD
// ============================================================

class AccountantBankingDashboardRoutePage
    extends ConsumerWidget {
  const AccountantBankingDashboardRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantBankingDashboardPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT BANK ACCOUNTS
// ============================================================

class AccountantBankAccountsRoutePage
    extends ConsumerWidget {
  const AccountantBankAccountsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantBankAccountsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT CASH BOXES
// ============================================================

class AccountantCashBoxesRoutePage
    extends ConsumerWidget {
  const AccountantCashBoxesRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantCashBoxesPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT PETTY CASH
// ============================================================

class AccountantPettyCashRoutePage
    extends ConsumerWidget {
  const AccountantPettyCashRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPettyCashPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT BANK LOANS
// ============================================================

class AccountantBankLoansRoutePage
    extends ConsumerWidget {
  const AccountantBankLoansRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantBankLoansPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT RECEIVED CHECKS
// ============================================================

class AccountantReceivedChecksRoutePage
    extends ConsumerWidget {
  const AccountantReceivedChecksRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantReceivedChecksPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT PAID CHECKS
// ============================================================

class AccountantPaidChecksRoutePage
    extends ConsumerWidget {
  const AccountantPaidChecksRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantPaidChecksPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT FISCAL PERIODS
// ============================================================

class AccountantFiscalPeriodsRoutePage
    extends ConsumerWidget {
  const AccountantFiscalPeriodsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantFiscalPeriodsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT BANKING REPORTS
// ============================================================

class AccountantBankingReportsRoutePage
    extends ConsumerWidget {
  const AccountantBankingReportsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantBankingReportsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}



// ============================================================
// ACCOUNTANT EXPENSE ROUTE PAGES
// ============================================================

class AccountantExpenseDashboardRoutePage extends ConsumerWidget {
  const AccountantExpenseDashboardRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantExpenseDashboardPage(
        companyId: accountant.companyId,
      ),
    );
  }
}

class AccountantExpenseFiscalPeriodsRoutePage extends ConsumerWidget {
  const AccountantExpenseFiscalPeriodsRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantExpenseFiscalPeriodsPage(
        companyId: accountant.companyId,
      ),
    );
  }
}

class AccountantExpenseCategoriesRoutePage extends ConsumerWidget {
  const AccountantExpenseCategoriesRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantExpenseCategoriesPage(
        companyId: accountant.companyId,
      ),
    );
  }
}

class AccountantExpenseRecognitionRoutePage extends ConsumerWidget {
  const AccountantExpenseRecognitionRoutePage({
    super.key,
    required this.periodId,
  });

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantExpenseRecognitionPage(
        companyId: accountant.companyId,
        periodId: periodId,
      ),
    );
  }
}

class AccountantExpenseReportsRoutePage extends ConsumerWidget {
  const AccountantExpenseReportsRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantExpenseReportsPage(
        companyId: accountant.companyId,
      ),
    );
  }
}

class AccountantPayableFiscalPeriodsRoutePage extends ConsumerWidget {
  const AccountantPayableFiscalPeriodsRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantPayableFiscalPeriodsPage(
        companyId: accountant.companyId,
      ),
    );
  }
}

class AccountantPayablePeriodRoutePage extends ConsumerWidget {
  const AccountantPayablePeriodRoutePage({
    super.key,
    required this.periodId,
  });

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantDashboardProvider);
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _AccountantRouteError(error: error),
      data: (accountant) => AccountantPayablePeriodPage(
        companyId: accountant.companyId,
        periodId: periodId,
      ),
    );
  }
}


// ============================================================
// ACCOUNTANT INCOME DASHBOARD
// ============================================================

class AccountantIncomeDashboardRoutePage
    extends ConsumerWidget {
  const AccountantIncomeDashboardRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantIncomeDashboardPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT INCOME FISCAL PERIODS
// ============================================================

class AccountantIncomeFiscalPeriodsRoutePage
    extends ConsumerWidget {
  const AccountantIncomeFiscalPeriodsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantIncomeFiscalPeriodsPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT INCOME CATEGORIES
// ============================================================

class AccountantIncomeCategoriesRoutePage
    extends ConsumerWidget {
  const AccountantIncomeCategoriesRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantIncomeCategoriesPage(
          companyId: accountant.companyId,
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT INCOME RECOGNITION
// ============================================================

class AccountantIncomeRecognitionRoutePage
    extends ConsumerWidget {
  const AccountantIncomeRecognitionRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final accountantState = ref.watch(
      accountantDashboardProvider,
    );

    return accountantState.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        final periodsState = ref.watch(
          accountantIncomeFiscalPeriodsProvider(
            accountant.companyId,
          ),
        );

        return periodsState.when(
          loading: () {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          error: (error, stackTrace) {
            return _AccountantRouteError(
              error: error,
            );
          },
          data: (data) {
            final year = data.selectedYear;

            if (
            year == null ||
                year.periods.isEmpty
            ) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'هیچ دوره درآمدی برای ثبت درآمد وجود ندارد.',
                    textDirection:
                    TextDirection.rtl,
                  ),
                ),
              );
            }

            final openPeriods = year.periods
                .where(
                  (period) =>
              period.status == 'open',
            )
                .toList();

            final period = openPeriods.isNotEmpty
                ? openPeriods.first
                : year.periods.first;

            return AccountantIncomeRecognitionPage(
              periodId: period.id,
            );
          },
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT RECEIVABLE PERIODS
// ============================================================

class AccountantReceivablePeriodsRoutePage
    extends ConsumerWidget {
  const AccountantReceivablePeriodsRoutePage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantScaffold(
          currentRoute:
          '/accountant/income/receivables',
          title: 'مطالبات',
          body: _AccountantReceivablePeriodsPage(
            companyId: accountant.companyId,
          ),
        );
      },
    );
  }
}

// ============================================================
// ACCOUNTANT RECEIVABLE MONTH
// ============================================================

class AccountantReceivablesMonthRoutePage
    extends ConsumerWidget {
  final String periodId;

  const AccountantReceivablesMonthRoutePage({
    super.key,
    required this.periodId,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final state = ref.watch(
      accountantDashboardProvider,
    );

    return state.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return _AccountantRouteError(
          error: error,
        );
      },
      data: (accountant) {
        return AccountantScaffold(
          currentRoute:
          '/accountant/income/receivables/$periodId',
          title: 'مطالبات',
          body: AccountantIncomeReceivablesPage(
            periodId: periodId,
          ),
        );
      },
    );
  }
}

// ============================================================
// INDEPENDENT RECEIVABLE PERIODS PAGE
// ============================================================

class _AccountantReceivablePeriodsPage
    extends StatefulWidget {
  final String companyId;

  const _AccountantReceivablePeriodsPage({
    required this.companyId,
  });

  @override
  State<_AccountantReceivablePeriodsPage>
  createState() =>
      _AccountantReceivablePeriodsPageState();
}

class _AccountantReceivablePeriodsPageState
    extends State<
        _AccountantReceivablePeriodsPage> {
  late Future<
      List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();

    _future = _loadPeriods();
  }

  Future<List<Map<String, dynamic>>>
  _loadPeriods() async {
    final response = await Supabase
        .instance
        .client
        .from(
      'income_receivable_fiscal_periods',
    )
        .select(
      'id, fiscal_year_id, company_id, year, month, title, status',
    )
        .eq(
      'company_id',
      widget.companyId,
    )
        .order(
      'year',
      ascending: false,
    )
        .order(
      'month',
      ascending: true,
    );

    return (response as List)
        .map(
          (row) =>
      Map<String, dynamic>.from(row),
    )
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadPeriods();
    });

    await _future;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<
          List<Map<String, dynamic>>>(
        future: _future,
        builder: (
            context,
            snapshot,
            ) {
          if (
          snapshot.connectionState ==
              ConnectionState.waiting
          ) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    'خطا در دریافت ماه‌های مطالبات',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    snapshot.error
                        .toString()
                        .replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    textAlign:
                    TextAlign.center,
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  FilledButton.icon(
                    onPressed:
                    _refresh,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'تلاش مجدد',
                    ),
                  ),
                ],
              ),
            );
          }

          final periods =
              snapshot.data ?? [];

          if (periods.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'هنوز دوره‌ای برای مطالبات ایجاد نشده است.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'این صفحه فقط ماه‌های مستقل مطالبات را نمایش می‌دهد.',
                    textAlign:
                    TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final grouped =
          <int,
              List<
                  Map<String,
                      dynamic>>>{};

          for (
          final period
          in periods
          ) {
            final year =
            _toInt(
              period['year'],
            );

            grouped.putIfAbsent(
              year,
                  () => [],
            ).add(period);
          }

          final years =
          grouped.keys.toList()
            ..sort(
                  (a, b) =>
                  b.compareTo(a),
            );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding:
              const EdgeInsets.all(
                24,
              ),
              itemCount:
              years.length,
              itemBuilder:
                  (context, index) {
                final year =
                years[index];

                final yearPeriods =
                    grouped[year] ?? [];

                return _ReceivableYearSection(
                  year: year,
                  periods:
                  yearPeriods,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// RECEIVABLE YEAR SECTION
// ============================================================

class _ReceivableYearSection
    extends StatelessWidget {
  final int year;

  final List<
      Map<String, dynamic>> periods;

  const _ReceivableYearSection({
    required this.year,
    required this.periods,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final months =
    List<Map<String, dynamic>?>.filled(
      12,
      null,
    );

    for (
    final period
    in periods
    ) {
      final month =
      _toInt(
        period['month'],
      );

      if (
      month >= 1 &&
          month <= 12
      ) {
        months[month - 1] =
            period;
      }
    }

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 24,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              'سال مالی مطالبات $year',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent:
                230,
                mainAxisExtent:
                105,
                crossAxisSpacing:
                12,
                mainAxisSpacing:
                12,
              ),
              itemCount: 12,
              itemBuilder:
                  (context, index) {
                final period =
                months[index];

                if (period ==
                    null) {
                  return _MissingReceivablePeriod(
                    month:
                    index + 1,
                  );
                }

                return _ReceivablePeriodCard(
                  period:
                  period,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECEIVABLE PERIOD CARD
// ============================================================

class _ReceivablePeriodCard
    extends StatelessWidget {
  final Map<String, dynamic> period;

  const _ReceivablePeriodCard({
    required this.period,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final id =
    period['id']?.toString();

    final month =
    _toInt(
      period['month'],
    );

    final status =
        period['status']
            ?.toString() ??
            'open';

    final title =
    period['title']
        ?.toString();

    final monthTitle =
    title != null &&
        title
            .trim()
            .isNotEmpty
        ? title
        : _monthName(month);

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      onTap:
      id == null
          ? null
          : () {
        context.push(
          '/accountant/income/receivables/$id',
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(
          16,
        ),
        decoration:
        BoxDecoration(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border:
          Border.all(
            color: Theme.of(
              context,
            )
                .colorScheme
                .outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .primary,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    monthTitle,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child:
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      9,
                      vertical:
                      5,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      _statusColor(
                        context,
                        status,
                      ).withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        8,
                      ),
                    ),
                    child:
                    Text(
                      _statusTitle(
                        status,
                      ),
                      maxLines:
                      2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                        _statusColor(
                          context,
                          status,
                        ),
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Icon(
                  Icons
                      .arrow_back_ios_new,
                  size: 14,
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STATUS COLOR
// ============================================================

Color _statusColor(
    BuildContext context,
    String status,
    ) {
  final colorScheme =
      Theme.of(
        context,
      ).colorScheme;

  switch (status) {
    case 'open':
      return colorScheme.primary;

    case 'submitted_to_company_admin':
      return Colors.orange.shade700;

    case 'submitted_to_consultant':
      return Colors.blue.shade700;

    case 'approved':
      return Colors.green.shade700;

    case 'closed':
      return Colors.grey.shade700;

    default:
      return colorScheme
          .onSurfaceVariant;
  }
}

// ============================================================
// MISSING RECEIVABLE PERIOD
// ============================================================

class _MissingReceivablePeriod
    extends StatelessWidget {
  final int month;

  const _MissingReceivablePeriod({
    required this.month,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        color: Theme.of(
          context,
        )
            .colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha: 0.4,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _monthName(month),
            style: Theme.of(
              context,
            )
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const Text(
            'ایجاد نشده',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACCOUNTANT ROUTE ERROR
// ============================================================

class _AccountantRouteError
    extends StatelessWidget {
  final Object error;

  const _AccountantRouteError({
    required this.error,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Text(
            'خطا در دریافت اطلاعات شرکت حسابدار\n\n$error',
            textAlign:
            TextAlign.center,
            textDirection:
            TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

int _toInt(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  ) ??
      0;
}

String _monthName(
    int month,
    ) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (
  month < 1 ||
      month > 12
  ) {
    return 'ماه';
  }

  return months[
  month - 1
  ];
}

String _statusTitle(
    String status,
    ) {
  switch (status) {
    case 'open':
      return 'در انتظار ارسال برای مدیرعامل';

    case 'submitted_to_company_admin':
      return 'ارسال‌شده برای مدیرعامل';

    case 'submitted_to_consultant':
      return 'در انتظار تأیید مشاور';

    case 'approved':
      return 'تأیید نهایی شده';

    case 'closed':
      return 'بسته شده';

    default:
      return 'وضعیت نامشخص';
  }
}

// ============================================================
// GO ROUTER REFRESH
// ============================================================

class GoRouterRefreshStream
    extends ChangeNotifier {
  GoRouterRefreshStream(
      Stream<dynamic> stream,
      ) {
    _subscription =
        stream.asBroadcastStream().listen(
              (_) {
            notifyListeners();
          },
        );
  }

  late final StreamSubscription<dynamic>
  _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}