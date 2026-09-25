import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class CashCeoReviewPage extends StatefulWidget {
  final String companyId;
  final String periodId;

  const CashCeoReviewPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  State<CashCeoReviewPage> createState() =>
      _CashCeoReviewPageState();
}

class _CashCeoReviewPageState
    extends State<CashCeoReviewPage> {
  final _supabase = Supabase.instance.client;

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
      final periodFuture = _supabase
          .from('cash_fiscal_periods')
          .select()
          .eq('id', periodId)
          .eq('company_id', companyId)
          .single();

      final banksFuture = _supabase
          .from('bank_account_periods')
          .select(
        '*, bank_accounts(bank_name, account_number)',
      )
          .eq('period_id', periodId)
          .eq('company_id', companyId)
          .order('created_at');

      final cashFuture = _supabase
          .from('cash_box_periods')
          .select(
        '*, cash_boxes(box_name)',
      )
          .eq('period_id', periodId)
          .eq('company_id', companyId)
          .order('created_at');

      final pettyFuture = _supabase
          .from('petty_cash_periods')
          .select(
        '*, petty_cash_accounts(name)',
      )
          .eq('period_id', periodId)
          .eq('company_id', companyId)
          .order('created_at');

      final results = await Future.wait([
        periodFuture,
        banksFuture,
        cashFuture,
        pettyFuture,
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
    final status = _period?['status']?.toString();

    switch (status) {
      case 'pending_ceo':
        return 'در انتظار تأیید مدیرعامل';

      case 'ceo_approved':
        return 'تأیید شده توسط مدیرعامل';

      case 'pending_consultant':
        return 'ارسال شده برای مشاور مالی';

      case 'consultant_approved':
        return 'تأیید نهایی شده';

      case 'rejected':
        return 'برگشت داده شده';

      case 'draft':
        return 'پیش‌نویس';

      default:
        return status ?? '-';
    }
  }

  Color _statusColor() {
    final status = _period?['status']?.toString();

    switch (status) {
      case 'pending_ceo':
        return Colors.orange;

      case 'ceo_approved':
      case 'pending_consultant':
        return Colors.indigo;

      case 'consultant_approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  double _totalClosing() {
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

    for (final row in [
      ..._banks,
      ..._cashBoxes,
      ..._pettyCash,
    ]) {
      total += _number(row['discrepancy']).abs();
    }

    return total;
  }

  Future<void> _approve() async {
    final status = _period?['status']?.toString();

    if (status != 'pending_ceo') {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await _supabase
          .from('cash_fiscal_periods')
          .update({
        'status': 'pending_consultant',
        'ceo_reviewed_by':
        _supabase.auth.currentUser?.id,
        'ceo_reviewed_at':
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
            'status': 'pending_consultant',
            'rejection_reason': null,
          };
        }
      });

      _message(
        'دوره تأیید شد و برای مشاور مالی ارسال شد',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _message(
        'خطا در تأیید دوره: $e',
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
    final status = _period?['status']?.toString();

    if (status != 'pending_ceo') {
      return;
    }

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('برگشت دوره'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              textDirection: TextDirection.rtl,
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
                child: const Text('برگشت دوره'),
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
        'ceo_reviewed_by':
        _supabase.auth.currentUser?.id,
        'ceo_reviewed_at':
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

      _message('دوره برای اصلاح برگشت داده شد');
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
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(22),
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
            Icon(icon, size: 28),
            const SizedBox(width: 14),
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
                      fontSize: 18,
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

  Widget _bankSection() {
    if (_banks.isEmpty) {
      return const SizedBox.shrink();
    }

    return _section(
      title: 'حساب‌های بانکی',
      icon: Icons.account_balance_outlined,
      headers: const [
        'بانک',
        'حساب',
        'ابتدای دوره',
        'بدهکار',
        'بستانکار',
        'پایان دوره',
        'دفاتر',
        'مغایرت',
      ],
      rows: _banks.map((row) {
        final rawBank = row['bank_accounts'];

        final bank = rawBank is Map
            ? Map<String, dynamic>.from(rawBank)
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
    if (_cashBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    return _section(
      title: 'صندوق‌ها',
      icon: Icons.account_balance_wallet_outlined,
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
        final rawCash = row['cash_boxes'];

        final cash = rawCash is Map
            ? Map<String, dynamic>.from(rawCash)
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
    if (_pettyCash.isEmpty) {
      return const SizedBox.shrink();
    }

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
        final rawPetty =
        row['petty_cash_accounts'];

        final petty = rawPetty is Map
            ? Map<String, dynamic>.from(rawPetty)
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

  Widget _section({
    required String title,
    required IconData icon,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
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
                columnSpacing: 30,
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
                        .map(
                          (entry) {
                        final index = entry.key;
                        final value = entry.value;

                        final isDiscrepancy =
                            index ==
                                values.length - 1;

                        final discrepancyValue =
                        isDiscrepancy
                            ? _number(
                          value,
                        )
                            : 0;

                        return DataCell(
                          Text(
                            value,
                            style: TextStyle(
                              fontWeight:
                              isDiscrepancy
                                  ? FontWeight
                                  .w800
                                  : FontWeight
                                  .w500,
                              color:
                              isDiscrepancy &&
                                  discrepancyValue !=
                                      0
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                        );
                      },
                    )
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final pending =
        _period?['status'] == 'pending_ceo';

    if (!pending) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
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
              _processing ? null : _approve,
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
                Icons.check_circle_outline,
              ),
              label: const Text(
                'تأیید و ارسال برای مشاور',
              ),
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
      title: 'بررسی مدیرعامل',
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
                          'بررسی اطلاعات بانک، صندوق و تنخواه',
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
                      constraints.maxWidth <
                          800;

                  final cards = [
                    _summaryCard(
                      title:
                      'مجموع نقدینگی پایان دوره',
                      value:
                      _money(_totalClosing()),
                      icon: Icons
                          .account_balance_wallet_outlined,
                    ),
                    _summaryCard(
                      title: 'مجموع مغایرت',
                      value: _money(
                        _totalDiscrepancy(),
                      ),
                      icon: Icons
                          .compare_arrows_outlined,
                    ),
                    _summaryCard(
                      title: 'تعداد حساب بانکی',
                      value:
                      '${_banks.length}',
                      icon: Icons
                          .account_balance_outlined,
                    ),
                    _summaryCard(
                      title:
                      'تعداد صندوق و تنخواه',
                      value:
                      '${_cashBoxes.length + _pettyCash.length}',
                      icon: Icons.payments_outlined,
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

                  return Row(
                    children: cards
                        .map(
                          (card) => Expanded(
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