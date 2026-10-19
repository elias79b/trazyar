import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/company_admin_dashboard_provider.dart';
import '../widgets/company_admin_scaffold.dart';

class CompanyAdminDashboardPage extends ConsumerWidget {
  const CompanyAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(companyAdminDashboardProvider);

    return CompanyAdminScaffold(
      child: dashboard.when(
        loading: () => const _LoadingView(),
        error:
            (error, stack) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(companyAdminDashboardProvider);
              },
            ),
        data: (data) => _DashboardContent(data: data),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 18,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(data: data),
                const SizedBox(height: 24),

                _FinancialCards(data: data),

                const SizedBox(height: 20),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _FinancialOverviewCard(data: data),
                      ),
                      const SizedBox(width: 18),
                      Expanded(flex: 4, child: _PeriodStatusCard(data: data)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _FinancialOverviewCard(data: data),
                      const SizedBox(height: 18),
                      _PeriodStatusCard(data: data),
                    ],
                  ),

                const SizedBox(height: 20),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _PayablesCard(data: data)),
                      const SizedBox(width: 18),
                      Expanded(child: _ReceivablesCard(data: data)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _PayablesCard(data: data),
                      const SizedBox(height: 18),
                      _ReceivablesCard(data: data),
                    ],
                  ),

                const SizedBox(height: 20),

                _CompanyInfoCard(data: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(17),
            ),
            child:
                data.companyLogoUrl != null &&
                        data.companyLogoUrl!.trim().isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.network(
                        data.companyLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business_rounded,
                            color: Color(0xFF167A4A),
                            size: 30,
                          );
                        },
                      ),
                    )
                    : const Icon(
                      Icons.business_rounded,
                      color: Color(0xFF167A4A),
                      size: 30,
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'داشبورد مدیرعامل',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17221D),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data.companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF167A4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'خوش آمدید ${data.userName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718078),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  data.currentMonthTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17221D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.currentYear}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF718078),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCards extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _FinancialCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        title: 'درآمد ماه',
        value: data.monthlyIncome,
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFF167A4A),
        background: const Color(0xFFEAF7F0),
      ),
      _CardData(
        title: 'هزینه ماه',
        value: data.monthlyExpense,
        icon: Icons.trending_down_rounded,
        iconColor: const Color(0xFFD65A4A),
        background: const Color(0xFFFCEDEA),
      ),
      _CardData(
        title: 'سود / زیان ماه',
        value: data.monthlyProfit,
        icon: Icons.account_balance_rounded,
        iconColor:
            data.monthlyProfit >= 0
                ? const Color(0xFF167A4A)
                : const Color(0xFFD65A4A),
        background:
            data.monthlyProfit >= 0
                ? const Color(0xFFEAF7F0)
                : const Color(0xFFFCEDEA),
      ),
      _CardData(
        title: 'نقدینگی',
        value: data.totalLiquidity,
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF3D6EA8),
        background: const Color(0xFFEDF3FA),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1250) {
          columns = 4;
        } else if (constraints.maxWidth >= 760) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double spacing = 14;

        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards
                  .map(
                    (card) => SizedBox(
                      width: columns == 1 ? constraints.maxWidth : width,
                      child: _FinancialCard(data: card),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _CardData {
  final String title;
  final double value;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _CardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.background,
  });
}

class _FinancialCard extends StatelessWidget {
  final _CardData data;

  const _FinancialCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 19),
              ),
              const Spacer(),
              const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF9AA49F),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718078),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatMoney(data.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17221D),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'ریال',
            style: TextStyle(fontSize: 10, color: Color(0xFF9AA49F)),
          ),
        ],
      ),
    );
  }
}

class _FinancialOverviewCard extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _FinancialOverviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final double total = data.monthlyIncome + data.monthlyExpense;

    final double incomePercent = total > 0 ? data.monthlyIncome / total : 0;

    final double expensePercent = total > 0 ? data.monthlyExpense / total : 0;

    return _Panel(
      title: 'نمای کلی عملکرد مالی',
      icon: Icons.analytics_rounded,
      child: Column(
        children: [
          _ProgressRow(
            title: 'درآمد ماه',
            amount: data.monthlyIncome,
            percent: incomePercent,
            color: const Color(0xFF167A4A),
          ),
          const SizedBox(height: 18),
          _ProgressRow(
            title: 'هزینه ماه',
            amount: data.monthlyExpense,
            percent: expensePercent,
            color: const Color(0xFFD65A4A),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE8ECEA)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'نتیجه ماه',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF52605A),
                  ),
                ),
              ),
              Text(
                _formatMoney(data.monthlyProfit),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color:
                      data.monthlyProfit >= 0
                          ? const Color(0xFF167A4A)
                          : const Color(0xFFD65A4A),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'ریال',
                style: TextStyle(fontSize: 11, color: Color(0xFF89948E)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final double amount;
  final double percent;
  final Color color;

  const _ProgressRow({
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF52605A),
                ),
              ),
            ),
            Text(
              _formatMoney(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17221D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFEFF2F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PeriodStatusCard extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _PeriodStatusCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'وضعیت دوره‌های مالی',
      icon: Icons.calendar_month_rounded,
      child: Column(
        children: [
          _StatusRow(
            title: 'دوره درآمد',
            exists: data.hasIncomePeriod,
            status: data.incomePeriodStatus,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            title: 'دوره هزینه',
            exists: data.hasExpensePeriod,
            status: data.expensePeriodStatus,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            title: 'دوره صندوق',
            exists: data.hasCashPeriod,
            status: data.cashPeriodStatus,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final bool exists;
  final String? status;

  const _StatusRow({
    required this.title,
    required this.exists,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String label = !exists ? 'ایجاد نشده' : _statusTitle(status);

    final Color color =
        !exists ? const Color(0xFF8A938E) : _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF52605A),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayablesCard extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _PayablesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'حساب‌های پرداختنی',
      icon: Icons.payments_rounded,
      action: 'مشاهده',
      onAction: () {
        context.go('/company-admin/payables');
      },
      child: Column(
        children: [
          _AmountRow(
            title: 'در انتظار پرداخت',
            value: data.pendingPayables,
            color: const Color(0xFFD68B24),
          ),
          const SizedBox(height: 13),
          _AmountRow(
            title: 'پرداخت‌شده',
            value: data.paidPayables,
            color: const Color(0xFF167A4A),
          ),
          const SizedBox(height: 13),
          _AmountRow(
            title: 'لغوشده',
            value: data.cancelledPayables,
            color: const Color(0xFFD65A4A),
          ),
        ],
      ),
    );
  }
}

class _ReceivablesCard extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _ReceivablesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'حساب‌های دریافتنی',
      icon: Icons.receipt_long_rounded,
      action: 'مشاهده',
      onAction: () {
        context.go('/company-admin/receivables');
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                color: Color(0xFF167A4A),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Text(
                'مانده دریافتنی شرکت',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF52605A),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(data.receivables),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF167A4A),
                  ),
                ),
                const Text(
                  'ریال',
                  style: TextStyle(fontSize: 10, color: Color(0xFF718078)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _AmountRow({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF52605A),
            ),
          ),
        ),
        Text(
          _formatMoney(value),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17221D),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'ریال',
          style: TextStyle(fontSize: 10, color: Color(0xFF89948E)),
        ),
      ],
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  final CompanyAdminDashboardData data;

  const _CompanyInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'اطلاعات شرکت',
      icon: Icons.business_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool twoColumns = constraints.maxWidth >= 700;

          final items = [
            _InfoItem(title: 'نام شرکت', value: data.companyName),
            _InfoItem(title: 'شناسه ملی', value: data.companyNationalId),
            _InfoItem(title: 'تلفن', value: data.companyPhone),
            _InfoItem(title: 'ایمیل', value: data.companyEmail),
            _InfoItem(
              title: 'استان / شهر',
              value: _locationText(data.companyProvince, data.companyCity),
            ),
          ];

          if (!twoColumns) {
            return Column(
              children:
                  items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: item,
                        ),
                      )
                      .toList(),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return items[index];
            },
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String? value;

  const _InfoItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final String displayValue =
        value == null || value!.trim().isEmpty ? 'ثبت نشده' : value!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF89948E)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              displayValue,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17221D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF167A4A)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17221D),
                  ),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF167A4A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF167A4A)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EAE7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEDEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFD65A4A),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'خطا در دریافت اطلاعات داشبورد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF17221D),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: Color(0xFF718078),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('تلاش مجدد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF167A4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final bool negative = value < 0;
  final String digits = value.abs().round().toString();

  final StringBuffer result = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      result.write(',');
    }

    result.write(digits[i]);
  }

  return '${negative ? '-' : ''}$result';
}

String _statusTitle(String? status) {
  switch (status) {
    case 'open':
      return 'باز';

    case 'submitted_to_company_admin':
      return 'ارسال به مدیرعامل';

    case 'submitted_to_consultant':
      return 'ارسال به مشاور';

    case 'approved':
      return 'تأیید شده';

    case 'closed':
      return 'بسته';

    default:
      return 'نامشخص';
  }
}

Color _statusColor(String? status) {
  switch (status) {
    case 'open':
      return const Color(0xFF3D6EA8);

    case 'submitted_to_company_admin':
      return const Color(0xFFD68B24);

    case 'submitted_to_consultant':
      return const Color(0xFF8B63B6);

    case 'approved':
      return const Color(0xFF167A4A);

    case 'closed':
      return const Color(0xFF718078);

    default:
      return const Color(0xFF8A938E);
  }
}

String _locationText(String? province, String? city) {
  final List<String> parts = [];

  if (province != null && province.trim().isNotEmpty) {
    parts.add(province.trim());
  }

  if (city != null && city.trim().isNotEmpty) {
    parts.add(city.trim());
  }

  if (parts.isEmpty) {
    return 'ثبت نشده';
  }

  return parts.join(' / ');
}
