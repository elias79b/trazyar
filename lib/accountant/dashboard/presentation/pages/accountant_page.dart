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

    return AccountantScaffold(
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
    return SingleChildScrollView(
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

          _buildSectionTitle(context, 'شرکت تحت مدیریت'),

          const SizedBox(height: 12),

          _buildCompanyCard(context),
        ],
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
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(.78),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
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
              ],
            ),
          ),
          const SizedBox(width: 20),
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
  // KPI
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
                value: '—',
                subtitle: 'در حال اتصال به اطلاعات مالی',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.trending_up_outlined,
                title: 'درآمد ماه جاری',
                value: '—',
                subtitle: 'درآمد ثبت‌شده',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.trending_down_outlined,
                title: 'هزینه ماه جاری',
                value: '—',
                subtitle: 'هزینه ثبت‌شده',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                context,
                icon: Icons.calculate_outlined,
                title: 'سود / زیان',
                value: '—',
                subtitle: 'محاسبه پس از اتصال داده‌ها',
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
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
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
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
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
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withOpacity(.08),
            ),
            child: const Icon(Icons.business_outlined, size: 30),
          ),
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
                const SizedBox(height: 6),
                if (data.companyLegalName != null)
                  Text(
                    data.companyLegalName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (data.companyProvince != null ||
                    data.companyCity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [data.companyProvince, data.companyCity]
                        .where(
                          (item) => item != null && item!.trim().isNotEmpty,
                        )
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
}

// ============================================================
// ERROR VIEW
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
                  'اطلاعات حسابدار قابل دریافت نیست',
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
