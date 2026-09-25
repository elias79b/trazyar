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

  Widget _kpi({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 5),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'جستجوی شماره، ذینفع، بانک...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('همه وضعیت‌ها')),
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
                if (value == null) return;

                setState(() {
                  _status = value;
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('بروزرسانی'),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    final rows = _filteredRows;

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'چک پرداختی ثبت نشده است',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 58,
          dataRowMaxHeight: 68,
          columns: const [
            DataColumn(label: Text('شماره چک')),
            DataColumn(label: Text('ذینفع')),
            DataColumn(label: Text('بانک')),
            DataColumn(label: Text('تاریخ سررسید')),
            DataColumn(label: Text('مبلغ')),
            DataColumn(label: Text('وضعیت')),
          ],
          rows:
              rows.map((row) {
                final status = _statusText(row);
                final statusColor = _statusColor(status);

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
                        '${_money(_rowAmount(row))} ریال',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
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

          final crossAxisCount =
              width >= 1400
                  ? 4
                  : width >= 900
                  ? 2
                  : 1;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'گزارش چک‌های پرداختی',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'وضعیت تعهدات و چک‌های پرداختی شرکت',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'خطا در دریافت اطلاعات:\n$_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: width >= 900 ? 2.5 : 2.8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _kpi(
                        title: 'مجموع تعهدات',
                        value: '${_money(_totalAmount)} ریال',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      _kpi(
                        title: 'در انتظار پرداخت',
                        value: '${_money(_pendingAmount)} ریال',
                        icon: Icons.schedule,
                        color: Colors.orange,
                      ),
                      _kpi(
                        title: 'پرداخت شده',
                        value: '${_money(_paidAmount)} ریال',
                        icon: Icons.check_circle_outline,
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
                  const SizedBox(height: 18),
                  _filters(),
                  const SizedBox(height: 18),
                  _table(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
