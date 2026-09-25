import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class BankingAlertsPage extends StatefulWidget {
  final String companyId;

  const BankingAlertsPage({super.key, required this.companyId});

  @override
  State<BankingAlertsPage> createState() => _BankingAlertsPageState();
}

class _BankingAlertsPageState extends State<BankingAlertsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<_BankingAlert> _alerts = [];

  double _liquidity = 0;
  double _previousLiquidity = 0;
  double _discrepancy = 0;
  double _bankDiscrepancy = 0;
  double _cashDiscrepancy = 0;
  double _pettyDiscrepancy = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _supabase
            .from('cash_fiscal_periods')
            .select('id, year, month, title, status')
            .eq('company_id', widget.companyId)
            .order('year', ascending: true)
            .order('month', ascending: true)
            .limit(24),
        _supabase
            .from('bank_account_periods')
            .select(
              'id, period_id, closing_balance, '
              'ledger_balance, discrepancy, '
              'bank_accounts(bank_name, account_number)',
            )
            .eq('company_id', widget.companyId),
        _supabase
            .from('cash_box_periods')
            .select(
              'id, period_id, closing_balance, '
              'ledger_balance, discrepancy, '
              'cash_boxes(box_name)',
            )
            .eq('company_id', widget.companyId),
        _supabase
            .from('petty_cash_periods')
            .select(
              'id, period_id, closing_balance, '
              'ledger_balance, discrepancy, '
              'petty_cash_accounts(name)',
            )
            .eq('company_id', widget.companyId),
      ]);

      final periods = List<Map<String, dynamic>>.from(results[0] as List);

      final banks = List<Map<String, dynamic>>.from(results[1] as List);

      final cashBoxes = List<Map<String, dynamic>>.from(results[2] as List);

      final pettyCash = List<Map<String, dynamic>>.from(results[3] as List);

      final data = _calculate(periods, banks, cashBoxes, pettyCash);

      if (!mounted) return;

      setState(() {
        _alerts = data.alerts;

        _liquidity = data.liquidity;
        _previousLiquidity = data.previousLiquidity;

        _discrepancy = data.discrepancy;

        _bankDiscrepancy = data.bankDiscrepancy;

        _cashDiscrepancy = data.cashDiscrepancy;

        _pettyDiscrepancy = data.pettyDiscrepancy;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  _AlertData _calculate(
    List<Map<String, dynamic>> periods,
    List<Map<String, dynamic>> banks,
    List<Map<String, dynamic>> cashBoxes,
    List<Map<String, dynamic>> pettyCash,
  ) {
    final orderedPeriods = [...periods]..sort((a, b) {
      final ay = _int(a['year']);
      final by = _int(b['year']);

      if (ay != by) {
        return ay.compareTo(by);
      }

      return _int(a['month']).compareTo(_int(b['month']));
    });

    final liquidityByPeriod = <String, double>{};

    final discrepancyByPeriod = <String, double>{};

    for (final period in orderedPeriods) {
      final periodId = period['id'].toString();

      double liquidity = 0;
      double discrepancy = 0;

      for (final row in banks.where(
        (row) => row['period_id']?.toString() == periodId,
      )) {
        liquidity += _num(row['closing_balance']);

        discrepancy += _num(row['discrepancy']).abs();
      }

      for (final row in cashBoxes.where(
        (row) => row['period_id']?.toString() == periodId,
      )) {
        liquidity += _num(row['closing_balance']);

        discrepancy += _num(row['discrepancy']).abs();
      }

      for (final row in pettyCash.where(
        (row) => row['period_id']?.toString() == periodId,
      )) {
        liquidity += _num(row['closing_balance']);

        discrepancy += _num(row['discrepancy']).abs();
      }

      liquidityByPeriod[periodId] = liquidity;

      discrepancyByPeriod[periodId] = discrepancy;
    }

    double bankDiscrepancy = 0;
    double cashDiscrepancy = 0;
    double pettyDiscrepancy = 0;

    for (final row in banks) {
      bankDiscrepancy += _num(row['discrepancy']).abs();
    }

    for (final row in cashBoxes) {
      cashDiscrepancy += _num(row['discrepancy']).abs();
    }

    for (final row in pettyCash) {
      pettyDiscrepancy += _num(row['discrepancy']).abs();
    }

    final double latestLiquidity =
        orderedPeriods.isEmpty
            ? 0.0
            : liquidityByPeriod[orderedPeriods.last['id'].toString()] ?? 0.0;

    final double previousLiquidity =
        orderedPeriods.length < 2
            ? 0.0
            : liquidityByPeriod[orderedPeriods[orderedPeriods.length - 2]['id']
                    .toString()] ??
                0.0;

    final double totalDiscrepancy =
        bankDiscrepancy + cashDiscrepancy + pettyDiscrepancy;

    final alerts = <_BankingAlert>[];

    if (previousLiquidity > 0 && latestLiquidity < previousLiquidity) {
      final percent =
          ((previousLiquidity - latestLiquidity) / previousLiquidity * 100.0);

      if (percent >= 10.0) {
        alerts.add(
          _BankingAlert(
            type: _AlertType.critical,
            title: 'کاهش قابل توجه نقدینگی',
            description:
                'نقدینگی نسبت به دوره قبل ${percent.toStringAsFixed(1)}٪ کاهش داشته است.',
            value: _money(latestLiquidity),
            icon: Icons.trending_down_rounded,
          ),
        );
      } else if (percent >= 5.0) {
        alerts.add(
          _BankingAlert(
            type: _AlertType.warning,
            title: 'کاهش نقدینگی',
            description:
                'نقدینگی نسبت به دوره قبل ${percent.toStringAsFixed(1)}٪ کاهش داشته است.',
            value: _money(latestLiquidity),
            icon: Icons.trending_down_rounded,
          ),
        );
      }
    }

    if (totalDiscrepancy > 0) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.warning,
          title: 'وجود مغایرت مالی',
          description: 'در اطلاعات بانک، صندوق یا تنخواه مغایرت ثبت شده است.',
          value: _money(totalDiscrepancy),
          icon: Icons.compare_arrows_outlined,
        ),
      );
    }

    if (bankDiscrepancy > 0) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.warning,
          title: 'مغایرت حساب‌های بانکی',
          description: 'مانده برخی حساب‌های بانکی با دفاتر مطابقت ندارد.',
          value: _money(bankDiscrepancy),
          icon: Icons.account_balance_outlined,
        ),
      );
    }

    if (cashDiscrepancy > 0) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.warning,
          title: 'مغایرت صندوق',
          description: 'مانده ثبت‌شده صندوق‌ها با مانده دفاتر اختلاف دارد.',
          value: _money(cashDiscrepancy),
          icon: Icons.point_of_sale_outlined,
        ),
      );
    }

    if (pettyDiscrepancy > 0) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.warning,
          title: 'مغایرت تنخواه',
          description: 'در مانده تنخواه‌گردان‌ها مغایرت مشاهده شده است.',
          value: _money(pettyDiscrepancy),
          icon: Icons.payments_outlined,
        ),
      );
    }

    final pendingPeriods = orderedPeriods.where(
      (period) => period['status']?.toString() == 'pending_consultant',
    );

    if (pendingPeriods.isNotEmpty) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.info,
          title: 'دوره‌های منتظر تأیید مشاور',
          description:
              '${pendingPeriods.length} دوره برای بررسی و تأیید نهایی منتظر اقدام مشاور مالی است.',
          value: pendingPeriods.length.toString(),
          icon: Icons.rate_review_outlined,
        ),
      );
    }

    final rejectedPeriods = orderedPeriods.where(
      (period) => period['status']?.toString() == 'rejected',
    );

    if (rejectedPeriods.isNotEmpty) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.critical,
          title: 'دوره برگشت‌خورده',
          description:
              '${rejectedPeriods.length} دوره مالی برای اصلاح برگشت داده شده است.',
          value: rejectedPeriods.length.toString(),
          icon: Icons.assignment_return_outlined,
        ),
      );
    }

    if (latestLiquidity == 0 && orderedPeriods.isNotEmpty) {
      alerts.add(
        _BankingAlert(
          type: _AlertType.critical,
          title: 'نقدینگی ثبت نشده',
          description:
              'برای آخرین دوره مالی مانده نقدینگی ثبت نشده یا صفر است.',
          value: '0',
          icon: Icons.warning_amber_rounded,
        ),
      );
    }

    return _AlertData(
      alerts: alerts,
      liquidity: latestLiquidity,
      previousLiquidity: previousLiquidity,
      discrepancy: totalDiscrepancy,
      bankDiscrepancy: bankDiscrepancy,
      cashDiscrepancy: cashDiscrepancy,
      pettyDiscrepancy: pettyDiscrepancy,
    );
  }

  int _int(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _num(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  String _money(dynamic value) {
    final number = _num(value).round();

    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/banking/alerts',
      title: 'هشدارهای مدیریتی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _errorView();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _header(),
          const SizedBox(height: 20),
          _summaryCards(),
          const SizedBox(height: 20),
          _riskBanner(),
          const SizedBox(height: 18),
          _alertsSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هشدارهای مدیریتی',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'کنترل ریسک نقدینگی، مغایرت‌ها و وضعیت دوره‌های مالی',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'به‌روزرسانی',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _summaryCards() {
    final cards = [
      _summaryCard(
        title: 'نقدینگی فعلی',
        value: _money(_liquidity),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _summaryCard(
        title: 'نقدینگی دوره قبل',
        value: _money(_previousLiquidity),
        icon: Icons.history_outlined,
      ),
      _summaryCard(
        title: 'مجموع مغایرت',
        value: _money(_discrepancy),
        icon: Icons.compare_arrows_outlined,
      ),
      _summaryCard(
        title: 'تعداد هشدار',
        value: _alerts.length.toString(),
        icon: Icons.notifications_active_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children:
                cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: card,
                      ),
                    )
                    .toList(),
          );
        }

        return Row(
          children:
              cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: Theme.of(context).colorScheme.primary.withOpacity(.10),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskBanner() {
    if (_alerts.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'وضعیت مالی عادی است',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'در داده‌های ثبت‌شده هشدار مدیریتی فعالی مشاهده نشد.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final critical =
        _alerts.where((alert) => alert.type == _AlertType.critical).length;

    final warning =
        _alerts.where((alert) => alert.type == _AlertType.warning).length;

    final color = critical > 0 ? Colors.red : Colors.orange;

    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Row(
          children: [
            Icon(
              critical > 0
                  ? Icons.gpp_bad_outlined
                  : Icons.warning_amber_outlined,
              color: color,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    critical > 0
                        ? 'نیاز به بررسی فوری'
                        : 'نیاز به بررسی مدیریتی',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$critical هشدار بحرانی و $warning هشدار نیازمند بررسی وجود دارد.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertsSection() {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 10),
                const Text(
                  'هشدارهای فعال',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${_alerts.length} مورد',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_alerts.isEmpty) _emptyAlerts() else ..._alerts.map(_alertTile),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(_BankingAlert alert) {
    final color = _alertColor(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: color.withOpacity(.10),
            ),
            child: Icon(alert.icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _typeChip(alert.type),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                if (alert.value != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'مقدار: ${alert.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(_AlertType type) {
    final color = _alertColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _alertTypeText(type),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _alertColor(_AlertType type) {
    switch (type) {
      case _AlertType.critical:
        return Colors.red;

      case _AlertType.warning:
        return Colors.orange;

      case _AlertType.info:
        return Colors.blue;
    }
  }

  String _alertTypeText(_AlertType type) {
    switch (type) {
      case _AlertType.critical:
        return 'بحرانی';

      case _AlertType.warning:
        return 'هشدار';

      case _AlertType.info:
        return 'اطلاع';
    }
  }

  Widget _emptyAlerts() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'هشداری وجود ندارد',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت هشدارها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AlertType { critical, warning, info }

class _BankingAlert {
  final _AlertType type;
  final String title;
  final String description;
  final String? value;
  final IconData icon;

  const _BankingAlert({
    required this.type,
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
  });
}

class _AlertData {
  final List<_BankingAlert> alerts;

  final double liquidity;
  final double previousLiquidity;
  final double discrepancy;
  final double bankDiscrepancy;
  final double cashDiscrepancy;
  final double pettyDiscrepancy;

  const _AlertData({
    required this.alerts,
    required this.liquidity,
    required this.previousLiquidity,
    required this.discrepancy,
    required this.bankDiscrepancy,
    required this.cashDiscrepancy,
    required this.pettyDiscrepancy,
  });
}
