import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class PaidChecksReportPage extends StatefulWidget {
  final String companyId;

  const PaidChecksReportPage({super.key, required this.companyId});

  @override
  State<PaidChecksReportPage> createState() => _PaidChecksReportPageState();
}

class _PaidChecksReportPageState extends State<PaidChecksReportPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rows = [];

  String _search = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('paid_checks')
          .select()
          .eq('company_id', widget.companyId)
          .order('due_date', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      setState(() {
        _rows = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  String _money(dynamic value) {
    return NumberFormat('#,##0').format(_number(value));
  }

  String _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '-';
  }

  DateTime? _date(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];

      if (value == null) continue;

      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) return parsed;
    }

    return null;
  }

  String _dateText(Map<String, dynamic> row) {
    final date = _date(row, [
      'due_date',
      'check_due_date',
      'date',
      'check_date',
    ]);

    if (date == null) return '-';

    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _statusText(Map<String, dynamic> row) {
    final status = _text(row, ['status', 'check_status', 'state']);

    switch (status.toLowerCase()) {
      case 'paid':
      case 'cleared':
      case 'settled':
      case 'پرداخت شده':
      case 'تسویه شده':
        return 'پرداخت شده';

      case 'returned':
      case 'bounced':
      case 'برگشتی':
        return 'برگشتی';

      case 'cancelled':
      case 'canceled':
      case 'باطل':
        return 'باطل';

      case 'pending':
      case 'در انتظار':
        return 'در انتظار پرداخت';

      default:
        return status == '-' ? 'در انتظار پرداخت' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'پرداخت شده':
        return Colors.green;

      case 'برگشتی':
        return Colors.red;

      case 'باطل':
        return Colors.grey;

      default:
        return Colors.orange;
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    final query = _search.trim().toLowerCase();

    return _rows.where((row) {
      final status = _statusText(row);

      if (_status != 'all' && status != _status) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchable =
          [
            _text(row, ['check_number', 'serial_number', 'number', 'serial']),
            _text(row, ['payee_name', 'recipient_name', 'supplier_name']),
            _text(row, ['bank_name', 'bank']),
            status,
          ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  double _rowAmount(Map<String, dynamic> row) {
    return _number(
      row['amount'] ??
          row['check_amount'] ??
          row['value'] ??
          row['nominal_amount'],
    );
  }

  double get _totalAmount {
    return _filteredRows.fold<double>(0, (sum, row) => sum + _rowAmount(row));
  }

  double get _paidAmount {
    return _filteredRows
        .where((row) => _statusText(row) == 'پرداخت شده')
        .fold<double>(0, (sum, row) => sum + _rowAmount(row));
  }

  double get _pendingAmount {
    return _filteredRows
        .where((row) => _statusText(row) == 'در انتظار پرداخت')
        .fold<double>(0, (sum, row) => sum + _rowAmount(row));
  }

  double get _returnedAmount {
    return _filteredRows
        .where((row) => _statusText(row) == 'برگشتی')
        .fold<double>(0, (sum, row) => sum + _rowAmount(row));
  }

  Color get _surface => Theme.of(context).colorScheme.surface;

  Color get _outline => Theme.of(context).colorScheme.outlineVariant;

  Widget _kpi({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline.withOpacity(.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _outline),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline.withOpacity(.7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: wide ? 340 : constraints.maxWidth,
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'جستجوی شماره چک، ذینفع یا بانک...',
                    isDense: true,
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('همه وضعیت‌ها'),
                      ),
                      DropdownMenuItem(
                        value: 'در انتظار پرداخت',
                        child: Text('در انتظار پرداخت'),
                      ),
                      DropdownMenuItem(
                        value: 'پرداخت شده',
                        child: Text('پرداخت شده'),
                      ),
                      DropdownMenuItem(value: 'برگشتی', child: Text('برگشتی')),
                      DropdownMenuItem(value: 'باطل', child: Text('باطل')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('بروزرسانی'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    final rows = _filteredRows;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline.withOpacity(.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'فهرست چک‌های پرداختی شرکت',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${rows.length} مورد',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _outline.withOpacity(.7)),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 44,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(.55),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'چکی برای نمایش وجود ندارد',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'فیلترها را تغییر دهید یا پس از ثبت اطلاعات دوباره بررسی کنید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 52,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 72,
                horizontalMargin: 22,
                columnSpacing: 32,
                headingTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                columns: const [
                  DataColumn(label: Text('شماره چک')),
                  DataColumn(label: Text('ذینفع')),
                  DataColumn(label: Text('بانک')),
                  DataColumn(label: Text('تاریخ سررسید')),
                  DataColumn(label: Text('مبلغ (ریال)')),
                  DataColumn(label: Text('وضعیت')),
                ],
                rows:
                    rows.map((row) {
                      final status = _statusText(row);
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              _text(row, [
                                'check_number',
                                'serial_number',
                                'number',
                                'serial',
                              ]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _text(row, [
                                'payee_name',
                                'recipient_name',
                                'supplier_name',
                              ]),
                            ),
                          ),
                          DataCell(Text(_text(row, ['bank_name', 'bank']))),
                          DataCell(Text(_dateText(row))),
                          DataCell(
                            Text(
                              _money(
                                row['amount'] ??
                                    row['check_amount'] ??
                                    row['value'] ??
                                    row['nominal_amount'],
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          DataCell(_statusBadge(status)),
                        ],
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/banking/paid-checks',
      title: 'گزارش چک‌های پرداختی',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns =
              width >= 1250
                  ? 4
                  : width >= 820
                  ? 2
                  : 1;
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(width < 600 ? 14 : 24),
              children: [
                Container(
                  padding: EdgeInsets.all(width < 600 ? 18 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(.10),
                        Theme.of(context).colorScheme.primary.withOpacity(.025),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: width < 600 ? 46 : 54,
                        height: width < 600 ? 46 : 54,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'گزارش چک‌های پرداختی',
                              style: TextStyle(
                                fontSize: width < 600 ? 19 : 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'وضعیت تعهدات و چک‌های پرداختی شرکت',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'بروزرسانی اطلاعات',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'دریافت اطلاعات با خطا مواجه شد',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تلاش دوباره'),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: width >= 820 ? 2.6 : 2.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _kpi(
                        title: 'مجموع تعهدات',
                        value: '${_money(_totalAmount)} ریال',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.blue,
                      ),
                      _kpi(
                        title: 'در انتظار پرداخت',
                        value: '${_money(_pendingAmount)} ریال',
                        icon: Icons.schedule_rounded,
                        color: Colors.orange,
                      ),
                      _kpi(
                        title: 'پرداخت شده',
                        value: '${_money(_paidAmount)} ریال',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                      _kpi(
                        title: 'برگشتی',
                        value: '${_money(_returnedAmount)} ریال',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _filters(),
                  const SizedBox(height: 18),
                  _table(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'مبالغ بر اساس فیلترهای فعلی محاسبه شده‌اند.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
