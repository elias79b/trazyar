import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// گزارش درآمد مدیرعامل؛ داده‌ها از جداول فعلی Supabase خوانده می‌شوند.
class CompanyAdminIncomeReportsPage extends StatefulWidget {
  const CompanyAdminIncomeReportsPage({super.key});

  @override
  State<CompanyAdminIncomeReportsPage> createState() =>
      _CompanyAdminIncomeReportsPageState();
}

class _CompanyAdminIncomeReportsPageState
    extends State<CompanyAdminIncomeReportsPage> {
  final SupabaseClient _db = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  String? _companyId;
  int? _selectedYear;
  List<int> _years = [];
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _recognitions = [];
  Map<String, String> _categoryNames = {};

  static const Map<int, String> _months = {
    1: 'فروردین',
    2: 'اردیبهشت',
    3: 'خرداد',
    4: 'تیر',
    5: 'مرداد',
    6: 'شهریور',
    7: 'مهر',
    8: 'آبان',
    9: 'آذر',
    10: 'دی',
    11: 'بهمن',
    12: 'اسفند',
  };

  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport({int? year}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = _db.auth.currentUser;
      if (user == null) throw Exception('ابتدا وارد حساب کاربری شوید.');

      final membership = await _db
          .from('company_users')
          .select('company_id')
          .eq('user_id', user.id)
          .eq('role', 'company_admin')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null || membership['company_id'] == null) {
        throw Exception('شرکت فعال برای این حساب مدیرعامل پیدا نشد.');
      }
      final companyId = membership['company_id'].toString();

      final yearRows = await _db
          .from('income_fiscal_years')
          .select('year, title')
          .eq('company_id', companyId)
          .order('year', ascending: false);

      final years = yearRows
          .map<int>((row) => (row['year'] as num).toInt())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final selectedYear = year ?? _selectedYear ??
          (years.isNotEmpty ? years.first : null);

      if (selectedYear == null) {
        if (!mounted) return;
        setState(() {
          _companyId = companyId;
          _years = years;
          _selectedYear = null;
          _periods = [];
          _recognitions = [];
          _categoryNames = {};
          _loading = false;
        });
        return;
      }

      final periodRows = await _db
          .from('income_fiscal_periods')
          .select('id, fiscal_year_id, company_id, year, month, title, status')
          .eq('company_id', companyId)
          .eq('year', selectedYear)
          .order('month');

      final periods = List<Map<String, dynamic>>.from(periodRows);
      final periodIds = periods.map((e) => e['id'].toString()).toList();

      List<Map<String, dynamic>> recognitions = [];
      Map<String, String> categoryNames = {};

      if (periodIds.isNotEmpty) {
        final recognitionRows = await _db
            .from('income_recognitions')
            .select('id, fiscal_period_id, category_id, amount, description, created_at')
            .eq('company_id', companyId)
            .inFilter('fiscal_period_id', periodIds)
            .order('created_at', ascending: false);
        recognitions = List<Map<String, dynamic>>.from(recognitionRows);

        final categoryIds = recognitions
            .map((e) => e['category_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

        if (categoryIds.isNotEmpty) {
          final categoryRows = await _db
              .from('income_categories')
              .select('id, name, category_type')
              .eq('company_id', companyId)
              .inFilter('id', categoryIds);
          categoryNames = {
            for (final row in categoryRows)
              row['id'].toString(): row['name']?.toString() ?? 'بدون عنوان'
          };
          for (final row in categoryRows) {
            final id = row['id'].toString();
            final type = row['category_type']?.toString();
            categoryNames[id] = '${row['name'] ?? 'بدون عنوان'}';
            if (type == 'non_operational') {
              categoryNames[id] = '${row['name'] ?? 'بدون عنوان'} (غیرعملیاتی)';
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _years = years;
        _selectedYear = selectedYear;
        _periods = periods;
        _recognitions = recognitions;
        _categoryNames = categoryNames;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString();
    if (value.contains('permission denied') ||
        value.contains('row-level security') ||
        value.contains('RLS')) {
      return 'دسترسی خواندن اطلاعات گزارش درآمد در Supabase مجاز نیست. سیاست‌های RLS را بررسی کنید.';
    }
    return value.replaceFirst('Exception: ', '');
  }

  double _amountOf(Map<String, dynamic> row) =>
      (row['amount'] as num?)?.toDouble() ?? 0;

  double get _totalRecognized =>
      _recognitions.fold<double>(0, (sum, row) => sum + _amountOf(row));

  double get _operationalTotal {
    double total = 0;
    for (final row in _recognitions) {
      final name = _categoryNames[row['category_id']?.toString()] ?? '';
      if (!name.contains('(غیرعملیاتی)')) total += _amountOf(row);
    }
    return total;
  }

  double get _nonOperationalTotal =>
      _totalRecognized - _operationalTotal;

  int get _approvedPeriods =>
      _periods.where((p) => p['status'] == 'approved').length;

  int get _submittedPeriods => _periods
      .where((p) =>
          p['status'] == 'submitted_to_company_admin' ||
          p['status'] == 'submitted_to_consultant')
      .length;

  Map<String, double> get _categoryTotals {
    final result = <String, double>{};
    for (final row in _recognitions) {
      final id = row['category_id']?.toString() ?? '';
      final name = _categoryNames[id] ?? 'دسته‌بندی حذف‌شده';
      result[name] = (result[name] ?? 0) + _amountOf(row);
    }
    return result;
  }

  Map<int, double> get _monthTotals {
    final periodById = {
      for (final period in _periods)
        period['id'].toString(): (period['month'] as num).toInt()
    };
    final result = <int, double>{};
    for (final row in _recognitions) {
      final month = periodById[row['fiscal_period_id']?.toString()];
      if (month != null) {
        result[month] = (result[month] ?? 0) + _amountOf(row);
      }
    }
    return result;
  }

  String _formatMoney(num value) => '${_money.format(value.round())} ریال';

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته‌شده';
      default:
        return status ?? 'نامشخص';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF207653);
      case 'submitted_to_consultant':
      case 'submitted_to_company_admin':
        return const Color(0xFF2879B9);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFB7791F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F6),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _errorView()
                  : _reportBody(),
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loadReport,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _reportBody() {
    final categoryTotals = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final monthTotals = _monthTotals;
    final maxMonthAmount = monthTotals.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('گزارش درآمد',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('گزارش بر اساس درآمدهای شناسایی‌شده در دوره‌های مالی',
                        style: TextStyle(color: Color(0xFF718078))),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'بازخوانی گزارش',
                onPressed: _loadReport,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _yearSelector(),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 720
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.3 : 2.2,
                children: [
                  _metric('کل درآمد شناسایی‌شده', _formatMoney(_totalRecognized),
                      Icons.account_balance_wallet_outlined, const Color(0xFF207653)),
                  _metric('درآمد عملیاتی', _formatMoney(_operationalTotal),
                      Icons.trending_up, const Color(0xFF168A83)),
                  _metric('درآمد غیرعملیاتی', _formatMoney(_nonOperationalTotal),
                      Icons.swap_horiz, const Color(0xFF8B5CF6)),
                  _metric('دوره‌های تأییدشده',
                      '$_approvedPeriods از ${_periods.length}',
                      Icons.verified_outlined, const Color(0xFF2879B9)),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          _panel(
            title: 'روند ماهانه درآمد شناسایی‌شده',
            subtitle: 'مبالغ هر ماه از روی دوره مالی همان سال محاسبه شده‌اند.',
            child: monthTotals.isEmpty
                ? _empty('برای این سال مالی هنوز درآمدی شناسایی نشده است.')
                : Column(
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      final value = monthTotals[month] ?? 0;
                      final ratio = maxMonthAmount == 0 ? 0.0 : value / maxMonthAmount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 88,
                              child: Text(_months[month]!,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 13,
                                  value: ratio,
                                  backgroundColor: const Color(0xFFE6EEE9),
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF3B9A75)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: Text(_formatMoney(value),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 18),
          _panel(
            title: 'تفکیک درآمد بر اساس دسته‌بندی',
            subtitle: 'مبنای محاسبه، رکوردهای جدول income_recognitions است.',
            child: categoryTotals.isEmpty
                ? _empty('برای این سال مالی داده‌ای جهت تفکیک وجود ندارد.')
                : Column(
                    children: categoryTotals
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                children: [
                                  Expanded(child: Text(entry.key)),
                                  Text(_formatMoney(entry.value),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 120,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 9,
                                        value: _totalRecognized == 0
                                            ? 0
                                            : entry.value / _totalRecognized,
                                        backgroundColor:
                                            const Color(0xFFE6EEE9),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Color(0xFF207653)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _panel(
            title: 'وضعیت دوره‌های مالی',
            subtitle: 'درآمدهای تأییدنشده از درآمد نهایی تفکیک می‌شوند؛ جمع بالا مجموع شناسایی‌هاست.',
            child: _periods.isEmpty
                ? _empty('برای این سال مالی دوره‌ای ثبت نشده است.')
                : Column(
                    children: _periods.map((period) {
                      final status = period['status']?.toString();
                      final month = (period['month'] as num?)?.toInt();
                      final periodId = period['id'].toString();
                      final total = _recognitions
                          .where((r) => r['fiscal_period_id'].toString() == periodId)
                          .fold<double>(0, (sum, r) => sum + _amountOf(r));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDCE6DF)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF207653)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${month != null ? _months[month] ?? period['title'] : period['title']} — ${period['year']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_statusLabel(status),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _statusColor(status))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_formatMoney(total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _panel(
            title: 'آخرین ردیف‌های شناسایی درآمد',
            subtitle: 'برای جلوگیری از اشتباه، این بخش فقط داده‌های شناسایی‌شده را نشان می‌دهد.',
            child: _recognitions.isEmpty
                ? _empty('رکورد شناسایی درآمدی وجود ندارد.')
                : Column(
                    children: _recognitions.take(12).map((row) {
                      final categoryId = row['category_id']?.toString() ?? '';
                      final name = _categoryNames[categoryId] ?? 'دسته‌بندی حذف‌شده';
                      final period = _periods.cast<Map<String, dynamic>?>().firstWhere(
                        (p) => p?['id'].toString() == row['fiscal_period_id']?.toString(),
                        orElse: () => null,
                      );
                      final month = (period?['month'] as num?)?.toInt();
                      final description = row['description']?.toString().trim();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFDDF3E8),
                          child: Icon(Icons.trending_up, color: Color(0xFF207653)),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          '${month != null ? _months[month] : 'دوره نامشخص'}'
                          '${description != null && description.isNotEmpty ? ' • $description' : ''}',
                        ),
                        trailing: Text(_formatMoney(_amountOf(row)),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _yearSelector() {
    if (_years.isEmpty) {
      return _panel(
        title: 'سال مالی',
        child: _empty('ابتدا از بخش دوره‌های درآمد، سال مالی ایجاد کنید.'),
      );
    }
    return _panel(
      title: 'سال مالی گزارش',
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined,
              color: Color(0xFF207653)),
          const SizedBox(width: 12),
          const Text('انتخاب سال:'),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _selectedYear,
            items: _years
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ))
                .toList(),
            onChanged: (year) {
              if (year != null) _loadReport(year: year);
            },
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE6DF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF718078))),
                const SizedBox(height: 7),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE6DF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF718078))),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718078))),
        ),
      );
}
