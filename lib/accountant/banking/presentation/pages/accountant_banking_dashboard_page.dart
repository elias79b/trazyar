import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/accountant_banking_dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantBankingDashboardPage extends ConsumerWidget {
  final String companyId;

  const AccountantBankingDashboardPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(accountantBankingDashboardProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking',
      title: 'داشبورد نقد و بانک',
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(accountantBankingDashboardProvider(companyId));
              },
            ),
        data: (data) => _DashboardContent(data: data),
      ),
    );
  }
}

// ================================================================
// CONTENT
// ================================================================

class _DashboardContent extends StatelessWidget {
  final AccountantBankingDashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool compact = width < 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),

            const SizedBox(height: 22),

            if (data.periodId == null) const _EmptyPeriodBanner(),

            if (data.periodId == null) const SizedBox(height: 18),

            _buildTopKpis(context),

            const SizedBox(height: 22),

            if (compact)
              Column(
                children: [
                  _buildBankBalanceCard(),
                  const SizedBox(height: 18),
                  _buildCashCard(),
                  const SizedBox(height: 18),
                  _buildDiscrepancyCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildBankBalanceCard()),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: _buildCashCard()),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: _buildDiscrepancyCard()),
                ],
              ),

            const SizedBox(height: 18),

            if (compact)
              Column(
                children: [
                  _buildChecksCard(),
                  const SizedBox(height: 18),
                  _buildDebtCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChecksCard()),
                  const SizedBox(width: 18),
                  Expanded(child: _buildDebtCard()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(.10),
          ),
          child: Icon(
            Icons.account_balance_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'داشبورد نقد و بانک',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'نمای کلی وضعیت نقدینگی، بانک، چک و بدهی بانکی',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        _PeriodBadge(title: data.periodTitle, status: data.periodStatus),
      ],
    );
  }

  Widget _buildTopKpis(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 2 : 4;

        final items = [
          _KpiItem(
            title: 'مانده کل بانک',
            value: data.totalBankBalance,
            icon: Icons.account_balance_outlined,
          ),
          _KpiItem(
            title: 'موجودی صندوق',
            value: data.totalCashBalance,
            icon: Icons.point_of_sale_outlined,
          ),
          _KpiItem(
            title: 'موجودی تنخواه',
            value: data.totalPettyCashBalance,
            icon: Icons.wallet_outlined,
          ),
          _KpiItem(
            title: 'مانده بدهی بانکی',
            value: data.totalBankDebt,
            icon: Icons.credit_card_outlined,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _KpiCard(item: items[index]),
        );
      },
    );
  }

  Widget _buildBankBalanceCard() {
    return _DashboardCard(
      title: 'مانده بانک‌ها',
      subtitle: 'مانده حساب‌های بانکی در آخرین دوره مالی',
      icon: Icons.account_balance_outlined,
      child:
          data.banks.isEmpty
              ? const _ChartEmptyState(
                text: 'اطلاعات مانده حساب بانکی ثبت نشده است.',
              )
              : _HorizontalBars(
                items:
                    data.banks
                        .map(
                          (item) => _ChartBarItem(
                            label: item.bankName,
                            value: item.balance,
                          ),
                        )
                        .toList(),
              ),
    );
  }

  Widget _buildCashCard() {
    final items = <_ChartBarItem>[
      ...data.cashBoxes.map(
        (item) => _ChartBarItem(label: item.name, value: item.balance),
      ),
      ...data.pettyCash.map(
        (item) => _ChartBarItem(label: item.name, value: item.balance),
      ),
    ];

    return _DashboardCard(
      title: 'صندوق و تنخواه',
      subtitle: 'موجودی صندوق‌ها و تنخواه‌های شرکت',
      icon: Icons.wallet_outlined,
      child:
          items.isEmpty
              ? const _ChartEmptyState(
                text: 'اطلاعات صندوق و تنخواه ثبت نشده است.',
              )
              : _ColumnBars(items: items),
    );
  }

  Widget _buildDiscrepancyCard() {
    return _DashboardCard(
      title: 'مغایرت بانک و دفاتر',
      subtitle: 'مغایرت مانده بانک با مانده دفاتر',
      icon: Icons.compare_arrows_outlined,
      child:
          data.discrepancies.isEmpty
              ? const _ChartEmptyState(text: 'مغایرتی برای نمایش وجود ندارد.')
              : _DiscrepancyChart(items: data.discrepancies),
    );
  }

  Widget _buildChecksCard() {
    return _DashboardCard(
      title: 'چک‌های دریافتی و پرداختی',
      subtitle: 'مقایسه مبلغ چک‌های دریافتی و پرداختی',
      icon: Icons.receipt_long_outlined,
      child:
          data.totalChecks == 0
              ? const _ChartEmptyState(text: 'چکی برای نمایش ثبت نشده است.')
              : _ChecksChart(
                received: data.receivedChecksTotal,
                paid: data.paidChecksTotal,
              ),
    );
  }

  Widget _buildDebtCard() {
    return _DashboardCard(
      title: 'بدهی بانکی',
      subtitle: 'مانده تسهیلات و بدهی بانکی شرکت',
      icon: Icons.credit_score_outlined,
      child:
          data.bankDebts.isEmpty
              ? const _ChartEmptyState(text: 'تسهیلات بانکی ثبت نشده است.')
              : _DebtChart(items: data.bankDebts, total: data.totalBankDebt),
    );
  }
}

// ================================================================
// KPI
// ================================================================

class _KpiItem {
  final String title;
  final double value;
  final IconData icon;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: Theme.of(context).colorScheme.primary.withOpacity(.08),
            ),
            child: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 7),
                Text(
                  _money(item.value),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ریال',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CARD
// ================================================================

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: Theme.of(context).colorScheme.primary.withOpacity(.08),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
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
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

// ================================================================
// HORIZONTAL BARS
// ================================================================

class _ChartBarItem {
  final String label;
  final double value;

  const _ChartBarItem({required this.label, required this.value});
}

class _HorizontalBars extends StatelessWidget {
  final List<_ChartBarItem> items;

  const _HorizontalBars({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );

    return Column(
      children:
          items
              .take(7)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 17,
                            value: maxValue == 0 ? 0 : item.value / maxValue,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 82,
                        child: Text(
                          _compactMoney(item.value),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ================================================================
// COLUMN BARS
// ================================================================

class _ColumnBars extends StatelessWidget {
  final List<_ChartBarItem> items;

  const _ColumnBars({required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items.take(6).toList();

    final maxValue = visible.fold<double>(
      0,
      (max, item) => math.max(max, item.value),
    );

    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            visible.map((item) {
              final ratio = maxValue == 0 ? 0.0 : item.value / maxValue;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _compactMoney(item.value),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: ratio.clamp(.04, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(.72),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ================================================================
// DISCREPANCY
// ================================================================

class _DiscrepancyChart extends StatelessWidget {
  final List<BankingDiscrepancy> items;

  const _DiscrepancyChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
      0,
      (max, item) => math.max(max, item.amount.abs()),
    );

    return Column(
      children:
          items
              .take(7)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 85,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(height: 1, color: Colors.grey.shade300),
                              Align(
                                alignment:
                                    item.amount >= 0
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor:
                                      maxValue == 0
                                          ? 0
                                          : (item.amount.abs() / maxValue)
                                              .clamp(0.03, 1),
                                  child: Container(
                                    height: 17,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color:
                                          item.amount >= 0
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 78,
                        child: Text(
                          _signedMoney(item.amount),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.amount >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ================================================================
// CHECKS
// ================================================================

class _ChecksChart extends StatelessWidget {
  final double received;
  final double paid;

  const _ChecksChart({required this.received, required this.paid});

  @override
  Widget build(BuildContext context) {
    final total = received + paid;

    final receivedRatio = total == 0 ? 0.0 : received / total;

    return Row(
      children: [
        SizedBox(
          width: 145,
          height: 145,
          child: CustomPaint(
            painter: _DonutPainter(receivedRatio: receivedRatio),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'کل چک‌ها',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _compactMoney(total),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            children: [
              _LegendRow(
                label: 'دریافتی',
                value: received,
                percent: receivedRatio,
              ),
              const SizedBox(height: 18),
              _LegendRow(
                label: 'پرداختی',
                value: paid,
                percent: 1 - receivedRatio,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final double value;
  final double percent;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          '${(percent * 100).round()}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Text(_compactMoney(value), style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double receivedRatio;

  const _DonutPainter({required this.receivedRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - 12;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 25
          ..strokeCap = StrokeCap.butt;

    paint.color = Colors.blue;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * receivedRatio,
      false,
      paint,
    );

    paint.color = Colors.orange;
    canvas.drawArc(
      rect,
      -math.pi / 2 + 2 * math.pi * receivedRatio,
      2 * math.pi * (1 - receivedRatio),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.receivedRatio != receivedRatio;
  }
}

// ================================================================
// DEBT
// ================================================================

class _DebtChart extends StatelessWidget {
  final List<BankDebtItem> items;
  final double total;

  const _DebtChart({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final visible = items.take(6).toList();

    final maxValue = visible.fold<double>(
      0,
      (max, item) => math.max(max, item.remainingAmount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.red.withOpacity(.06),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مجموع مانده بدهی بانکی',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _money(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const Text('ریال', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...visible.map((item) {
          final ratio = maxValue == 0 ? 0.0 : item.remainingAmount / maxValue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    item.bankName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 15,
                      value: ratio.clamp(0, 1),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 82,
                  child: Text(
                    _compactMoney(item.remainingAmount),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ================================================================
// PERIOD
// ================================================================

class _PeriodBadge extends StatelessWidget {
  final String title;
  final String? status;

  const _PeriodBadge({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'دوره مالی',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (status != null) ...[
            const SizedBox(height: 3),
            Text(
              status == 'open' ? 'باز' : 'بسته',
              style: TextStyle(
                fontSize: 10,
                color: status == 'open' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// EMPTY
// ================================================================

class _ChartEmptyState extends StatelessWidget {
  final String text;

  const _ChartEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}

class _EmptyPeriodBanner extends StatelessWidget {
  const _EmptyPeriodBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(.20)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'هنوز دوره مالی نقد و بانک برای این شرکت ثبت نشده است. اطلاعات چک و تسهیلات در صورت وجود همچنان نمایش داده می‌شود.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ERROR
// ================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'دریافت اطلاعات داشبورد نقد و بانک انجام نشد.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FORMATTERS
// ================================================================

String _money(double value) {
  return _formatNumber(value.round());
}

String _compactMoney(double value) {
  final absolute = value.abs();

  if (absolute >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)} میلیارد';
  }

  if (absolute >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)} میلیون';
  }

  if (absolute >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)} هزار';
  }

  return _formatNumber(value.round());
}

String _signedMoney(double value) {
  if (value == 0) {
    return '۰';
  }

  final sign = value > 0 ? '+' : '-';

  return '$sign${_compactMoney(value.abs())}';
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    final position = text.length - i;

    buffer.write(text[i]);

    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
