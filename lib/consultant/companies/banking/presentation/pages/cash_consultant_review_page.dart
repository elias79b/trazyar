import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class CashConsultantReviewPage extends StatefulWidget {
  final String companyId;
  final String periodId;

  const CashConsultantReviewPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  State<CashConsultantReviewPage> createState() =>
      _CashConsultantReviewPageState();
}

class _CashConsultantReviewPageState
    extends State<CashConsultantReviewPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _loading = true;
  bool _processing = false;

  Map<String, dynamic>? _period;

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _cashBoxes = [];
  List<Map<String, dynamic>> _pettyCash = [];

  String get companyId => widget.companyId;
  String get periodId => widget.periodId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _monthName(int month) {
    const names = [
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

    if (month < 1 || month > 12) {
      return '-';
    }

    return names[month - 1];
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '').trim(),
    ) ??
        0;
  }

  String _money(dynamic value) {
    return _number(value)
        .round()
        .toString()
        .replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final results = await Future.wait([
        _supabase
            .from('cash_fiscal_periods')
            .select()
            .eq('id', periodId)
            .eq('company_id', companyId)
            .single(),
        _supabase
            .from('bank_account_periods')
            .select(
          '*, bank_accounts(bank_name, account_number)',
        )
            .eq('period_id', periodId)
            .eq('company_id', companyId)
            .order('created_at'),
        _supabase
            .from('cash_box_periods')
            .select(
          '*, cash_boxes(box_name)',
        )
            .eq('period_id', periodId)
            .eq('company_id', companyId)
            .order('created_at'),
        _supabase
            .from('petty_cash_periods')
            .select(
          '*, petty_cash_accounts(name)',
        )
            .eq('period_id', periodId)
            .eq('company_id', companyId)
            .order('created_at'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _period =
        Map<String, dynamic>.from(results[0] as Map);

        _banks =
        List<Map<String, dynamic>>.from(
          results[1] as List,
        );

        _cashBoxes =
        List<Map<String, dynamic>>.from(
          results[2] as List,
        );

        _pettyCash =
        List<Map<String, dynamic>>.from(
          results[3] as List,
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _message(
        'خطا در دریافت اطلاعات دوره: $e',
        error: true,
      );
    }
  }

  String _statusText() {
    switch (_period?['status']?.toString()) {
      case 'pending_consultant':
        return 'در انتظار تأیید مشاور';

      case 'consultant_approved':
        return 'تأیید نهایی';

      case 'rejected':
        return 'برگشت داده شده';

      case 'pending_ceo':
        return 'در انتظار مدیرعامل';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'draft':
        return 'پیش‌نویس';

      default:
        return _period?['status']?.toString() ?? '-';
    }
  }

  Color _statusColor() {
    switch (_period?['status']?.toString()) {
      case 'pending_consultant':
        return Colors.orange;

      case 'consultant_approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'pending_ceo':
        return Colors.amber;

      case 'ceo_approved':
        return Colors.indigo;

      default:
        return Colors.grey;
    }
  }

  double _totalLiquidity() {
    double total = 0;

    for (final row in _banks) {
      total += _number(row['closing_balance']);
    }

    for (final row in _cashBoxes) {
      total += _number(row['closing_balance']);
    }

    for (final row in _pettyCash) {
      total += _number(row['closing_balance']);
    }

    return total;
  }

  double _totalDiscrepancy() {
    double total = 0;

    final rows = [
      ..._banks,
      ..._cashBoxes,
      ..._pettyCash,
    ];

    for (final row in rows) {
      total += _number(row['discrepancy']).abs();
    }

    return total;
  }

  double _bankLiquidity() {
    double total = 0;

    for (final row in _banks) {
      total += _number(row['closing_balance']);
    }

    return total;
  }

  double _cashLiquidity() {
    double total = 0;

    for (final row in _cashBoxes) {
      total += _number(row['closing_balance']);
    }

    return total;
  }

  double _pettyLiquidity() {
    double total = 0;

    for (final row in _pettyCash) {
      total += _number(row['closing_balance']);
    }

    return total;
  }

  Future<void> _approveFinal() async {
    if (_period?['status'] != 'pending_consultant') {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await _supabase
          .from('cash_fiscal_periods')
          .update({
        'status': 'consultant_approved',
        'consultant_reviewed_by':
        _supabase.auth.currentUser?.id,
        'consultant_reviewed_at':
        DateTime.now().toIso8601String(),
        'rejection_reason': null,
      })
          .eq('id', periodId)
          .eq('company_id', companyId);

      if (!mounted) {
        return;
      }

      setState(() {
        if (_period != null) {
          _period = {
            ..._period!,
            'status': 'consultant_approved',
            'rejection_reason': null,
          };
        }
      });

      _message(
        'دوره با موفقیت تأیید نهایی شد و قفل گردید',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _message(
        'خطا در تأیید نهایی دوره: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    if (_period?['status'] != 'pending_consultant') {
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'برگشت برای اصلاح',
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'علت برگشت',
                hintText:
                'علت اصلاح اطلاعات را وارد کنید',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  final value =
                  controller.text.trim();

                  if (value.isEmpty) {
                    return;
                  }

                  Navigator.pop(context, value);
                },
                child: const Text(
                  'برگشت دوره',
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await _supabase
          .from('cash_fiscal_periods')
          .update({
        'status': 'rejected',
        'rejection_reason': reason.trim(),
        'consultant_reviewed_by':
        _supabase.auth.currentUser?.id,
        'consultant_reviewed_at':
        DateTime.now().toIso8601String(),
      })
          .eq('id', periodId)
          .eq('company_id', companyId);

      if (!mounted) {
        return;
      }

      setState(() {
        if (_period != null) {
          _period = {
            ..._period!,
            'status': 'rejected',
            'rejection_reason': reason.trim(),
          };
        }
      });

      _message(
        'دوره برای اصلاح برگشت داده شد',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _message(
        'خطا در برگشت دوره: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _message(
      String text, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor:
          error ? Colors.red.shade700 : null,
        ),
      );
  }

  Widget _statusChip() {
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        _statusText(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(.10),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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

  Widget _section({
    required String title,
    required IconData icon,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 28,
                headingRowHeight: 52,
                dataRowMinHeight: 58,
                columns: headers
                    .map(
                      (header) => DataColumn(
                    label: Text(header),
                  ),
                )
                    .toList(),
                rows: rows.map((values) {
                  return DataRow(
                    cells: values
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final value = entry.value;

                      final isLast =
                          index ==
                              values.length - 1;

                      final numeric =
                      isLast
                          ? _number(value)
                          : 0;

                      return DataCell(
                        Text(
                          value,
                          style: TextStyle(
                            fontWeight: isLast
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isLast &&
                                numeric != 0
                                ? Colors.red
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankSection() {
    return _section(
      title: 'حساب‌های بانکی',
      icon: Icons.account_balance_outlined,
      headers: const [
        'بانک',
        'شماره حساب',
        'ابتدای دوره',
        'بدهکار',
        'بستانکار',
        'پایان دوره',
        'دفاتر',
        'مغایرت',
      ],
      rows: _banks.map((row) {
        final raw =
        row['bank_accounts'];

        final bank = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        return [
          bank['bank_name']?.toString() ?? '-',
          bank['account_number']?.toString() ?? '-',
          _money(row['opening_balance']),
          _money(row['debit_turnover']),
          _money(row['credit_turnover']),
          _money(row['closing_balance']),
          _money(row['ledger_balance']),
          _money(row['discrepancy']),
        ];
      }).toList(),
    );
  }

  Widget _cashSection() {
    return _section(
      title: 'صندوق‌ها',
      icon:
      Icons.account_balance_wallet_outlined,
      headers: const [
        'صندوق',
        'ابتدای دوره',
        'دریافت',
        'پرداخت',
        'پایان دوره',
        'دفاتر',
        'مغایرت',
      ],
      rows: _cashBoxes.map((row) {
        final raw = row['cash_boxes'];

        final cash = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        return [
          cash['box_name']?.toString() ?? '-',
          _money(row['opening_balance']),
          _money(row['total_receipts']),
          _money(row['total_payments']),
          _money(row['closing_balance']),
          _money(row['ledger_balance']),
          _money(row['discrepancy']),
        ];
      }).toList(),
    );
  }

  Widget _pettySection() {
    return _section(
      title: 'تنخواه‌گردان‌ها',
      icon: Icons.payments_outlined,
      headers: const [
        'تنخواه',
        'ابتدای دوره',
        'دریافت',
        'پرداخت',
        'پایان دوره',
        'دفاتر',
        'مغایرت',
      ],
      rows: _pettyCash.map((row) {
        final raw =
        row['petty_cash_accounts'];

        final petty = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        return [
          petty['name']?.toString() ?? '-',
          _money(row['opening_balance']),
          _money(row['total_receipts']),
          _money(row['total_payments']),
          _money(row['closing_balance']),
          _money(row['ledger_balance']),
          _money(row['discrepancy']),
        ];
      }).toList(),
    );
  }

  Widget _actions() {
    if (_period?['status'] !=
        'pending_consultant') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اقدام مشاور مالی',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'پس از تأیید نهایی، دوره قفل شده و اطلاعات آن دیگر قابل ویرایش نخواهد بود.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed:
                  _processing ? null : _reject,
                  icon: const Icon(
                    Icons.undo_outlined,
                  ),
                  label: const Text(
                    'برگشت برای اصلاح',
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                  _processing
                      ? null
                      : _approveFinal,
                  icon: _processing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.verified_outlined,
                  ),
                  label: const Text(
                    'تأیید نهایی و قفل دوره',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month =
        int.tryParse('${_period?['month']}') ?? 1;

    final year =
        int.tryParse('${_period?['year']}') ?? 0;

    return CompanyScaffold(
      companyId: companyId,
      currentRoute:
      '/consultant/companies/$companyId/banking/fiscal-periods',
      title: 'بررسی مشاور مالی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_monthName(month)} $year',
                          style:
                          const TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'بررسی نهایی اطلاعات بانک، صندوق و تنخواه',
                          style: TextStyle(
                            color:
                            Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder:
                    (context, constraints) {
                  final compact =
                      constraints.maxWidth < 850;

                  final cards = [
                    _summaryCard(
                      title:
                      'کل نقدینگی',
                      value:
                      _money(
                        _totalLiquidity(),
                      ),
                      icon: Icons
                          .account_balance_wallet_outlined,
                    ),
                    _summaryCard(
                      title:
                      'نقدینگی بانکی',
                      value:
                      _money(
                        _bankLiquidity(),
                      ),
                      icon: Icons
                          .account_balance_outlined,
                    ),
                    _summaryCard(
                      title:
                      'صندوق',
                      value:
                      _money(
                        _cashLiquidity(),
                      ),
                      icon: Icons
                          .account_balance_wallet_outlined,
                    ),
                    _summaryCard(
                      title:
                      'تنخواه',
                      value:
                      _money(
                        _pettyLiquidity(),
                      ),
                      icon: Icons.payments_outlined,
                    ),
                    _summaryCard(
                      title:
                      'مغایرت',
                      value:
                      _money(
                        _totalDiscrepancy(),
                      ),
                      icon: Icons
                          .compare_arrows_outlined,
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: cards
                          .map(
                            (card) =>
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                bottom: 10,
                              ),
                              child: card,
                            ),
                      )
                          .toList(),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    child: Row(
                      children: cards
                          .map(
                            (card) =>
                            SizedBox(
                              width: 230,
                              child: Padding(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 5,
                                ),
                                child: card,
                              ),
                            ),
                      )
                          .toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (_period?['rejection_reason'] !=
                  null &&
                  _period!['rejection_reason']
                      .toString()
                      .trim()
                      .isNotEmpty)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .warning_amber_outlined,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'علت برگشت: ${_period!['rejection_reason']}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _bankSection(),
                    if (_banks.isNotEmpty)
                      const SizedBox(height: 16),
                    _cashSection(),
                    if (_cashBoxes.isNotEmpty)
                      const SizedBox(height: 16),
                    _pettySection(),
                    const SizedBox(height: 20),
                    _actions(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}