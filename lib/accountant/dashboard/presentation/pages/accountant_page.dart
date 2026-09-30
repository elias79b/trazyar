import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/accountant_dashboard_provider.dart';
import '../widgets/accountant_scaffold.dart';

class AccountantPage extends ConsumerWidget {
  const AccountantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    final dashboard = ref.watch(accountantDashboardProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AccountantScaffold(
        currentRoute: currentRoute,
        title: 'داشبورد حسابدار',
        body: dashboard.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _AccountantErrorView(
              error: error.toString(),
              onRetry: () {
                ref.invalidate(accountantDashboardProvider);
              },
            );
          },
          data: (data) {
            return _AccountantDashboardBody(data: data);
          },
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class _AccountantDashboardBody extends StatelessWidget {
  final AccountantDashboardData data;

  const _AccountantDashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // توسط parent provider مدیریت می‌شود.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(context),

            const SizedBox(height: 24),

            _buildSectionTitle(context, 'خلاصه مالی'),

            const SizedBox(height: 12),

            _buildKpiGrid(context),

            const SizedBox(height: 28),

            _buildSectionTitle(context, 'دسترسی سریع'),

            const SizedBox(height: 12),

            _buildQuickActions(context),

            const SizedBox(height: 28),

            _buildSectionTitle(context, 'وضعیت مالی'),

            const SizedBox(height: 12),

            _buildFinancialOverview(context),

            const SizedBox(height: 28),

            _buildSectionTitle(context, 'شرکت تحت مدیریت'),

            const SizedBox(height: 12),

            _buildCompanyCard(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(.78),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خوش آمدید ${data.fullName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'مدیریت عملیات مالی شرکت ${data.companyName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.90),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'دوره نمایش: ${data.currentYear} / ${data.currentMonthTitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }

  // ============================================================
  // KPI GRID
  // ============================================================

  Widget _buildKpiGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns =
            width >= 1200
                ? 4
                : width >= 700
                ? 2
                : 1;

        final itemWidth = (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'مانده نقد و بانک',
                value: _money(data.totalCashAndBank),
                subtitle:
                    data.hasCashPeriod
                        ? 'بانک، صندوق و تنخواه'
                        : 'دوره نقد و بانک ثبت نشده',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.trending_up_outlined,
                title: 'درآمد ماه جاری',
                value: _money(data.monthlyIncome),
                subtitle:
                    data.hasIncomePeriod
                        ? 'درآمد ثبت‌شده در دوره'
                        : 'دوره درآمدی ثبت نشده',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.trending_down_outlined,
                title: 'هزینه ماه جاری',
                value: _money(data.monthlyExpense),
                subtitle:
                    data.hasExpensePeriod
                        ? 'هزینه ثبت‌شده در دوره'
                        : 'دوره هزینه‌ای ثبت نشده',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.calculate_outlined,
                title: 'سود / زیان',
                value: _money(data.profitLoss),
                subtitle:
                    data.profitLoss >= 0
                        ? 'درآمد منهای هزینه'
                        : 'زیان دوره جاری',
                valueColor:
                    data.profitLoss >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),

          const SizedBox(height: 7),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns =
            width >= 1000
                ? 4
                : width >= 600
                ? 2
                : 1;

        final itemWidth = (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                icon: Icons.account_balance_outlined,
                title: 'نقد و بانک',
                subtitle: 'مدیریت حساب‌ها و صندوق‌ها',
                route: '/accountant/banking',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                icon: Icons.trending_up_outlined,
                title: 'درآمد',
                subtitle: 'ثبت و مدیریت درآمد',
                route: '/accountant/income',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                icon: Icons.trending_down_outlined,
                title: 'هزینه',
                subtitle: 'ثبت و مدیریت هزینه',
                route: '/accountant/expenses',
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: _buildQuickAction(
                context,
                icon: Icons.groups_outlined,
                title: 'حقوق و دستمزد',
                subtitle: 'مدیریت اطلاعات حقوق',
                route: '/accountant/payroll',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.go(route);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_left, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FINANCIAL OVERVIEW
  // ============================================================

  Widget _buildFinancialOverview(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFinancialRow(
            context,
            icon: Icons.account_balance_outlined,
            title: 'موجودی بانک',
            value: _money(data.bankBalance),
            color: theme.colorScheme.primary,
          ),

          const Divider(height: 24),

          _buildFinancialRow(
            context,
            icon: Icons.point_of_sale_outlined,
            title: 'موجودی صندوق',
            value: _money(data.cashBoxBalance),
            color: theme.colorScheme.primary,
          ),

          const Divider(height: 24),

          _buildFinancialRow(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'موجودی تنخواه',
            value: _money(data.pettyCashBalance),
            color: theme.colorScheme.primary,
          ),

          const Divider(height: 24),

          _buildFinancialRow(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'حساب‌های پرداختنی باز',
            value: _money(data.pendingPayables),
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),

        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),

        const SizedBox(width: 5),

        const Text('ریال', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // ============================================================
  // COMPANY CARD
  // ============================================================

  Widget _buildCompanyCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (data.companyLogoUrl != null &&
              data.companyLogoUrl!.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                data.companyLogoUrl!,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _companyIcon(context);
                },
              ),
            )
          else
            _companyIcon(context),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (data.companyLegalName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    data.companyLegalName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                if (data.companyProvince != null ||
                    data.companyCity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [data.companyProvince, data.companyCity]
                        .where((item) => item != null && item.trim().isNotEmpty)
                        .map((item) => item!)
                        .join(' - '),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'فعال',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyIcon(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withOpacity(.08),
      ),
      child: Icon(
        Icons.business_outlined,
        size: 30,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _AccountantErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _AccountantErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 56,
                  color: Colors.red.shade400,
                ),

                const SizedBox(height: 16),

                const Text(
                  'اطلاعات داشبورد حسابدار قابل دریافت نیست',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  error.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORMAT
// ============================================================

String _money(double value) {
  final rounded = value.round().toString();

  return _persianDigits(_formatNumber(rounded));
}

String _formatNumber(String value) {
  final negative = value.startsWith('-');

  final raw = negative ? value.substring(1) : value;

  final chars = raw.split('');

  final result = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && (chars.length - i) % 3 == 0) {
      result.write(',');
    }

    result.write(chars[i]);
  }

  return negative ? '-${result.toString()}' : result.toString();
}

String _persianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}
