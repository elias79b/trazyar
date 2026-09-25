import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/banking/application/banking_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../data/models/banking_models.dart';

class CashBoxesPage extends ConsumerStatefulWidget {
  final String companyId;

  const CashBoxesPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CashBoxesPage> createState() => _CashBoxesPageState();
}

class _CashBoxesPageState extends ConsumerState<CashBoxesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  List<CashBox> _cashBoxes = [];

  @override
  void initState() {
    super.initState();
    _loadCashBoxes();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadCashBoxes() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      // جدول اصلی cash_boxes فقط اطلاعات شناسنامه‌ای صندوق را دارد.
      final response = await _supabase
          .from('cash_boxes')
          .select(
        'id,'
            'company_id,'
            'box_name,'
            'created_by,'
            'created_at',
      )
          .eq(
        'company_id',
        widget.companyId,
      )
          .order('box_name');

      final rows = List<Map<String, dynamic>>.from(
        response as List,
      );

      /*
       * اطلاعات مالی از cash_box_periods خوانده می‌شود.
       *
       * اینجا عمداً هیچ notes و هیچ ستون مالی از cash_boxes
       * درخواست نمی‌شود.
       */
      final periodResponse = await _supabase
          .from('cash_box_periods')
          .select(
        'id,'
            'company_id,'
            'period_id,'
            'cash_box_id,'
            'opening_balance,'
            'total_receipts,'
            'total_payments,'
            'closing_balance,'
            'ledger_balance,'
            'discrepancy,'
            'created_at,'
            'updated_at',
      )
          .eq(
        'company_id',
        widget.companyId,
      )
          .order(
        'created_at',
        ascending: false,
      );

      final periodRows =
      List<Map<String, dynamic>>.from(
        periodResponse as List,
      );

      /*
       * آخرین رکورد مالی هر صندوق.
       */
      final Map<String, Map<String, dynamic>>
      latestPeriodByCashBox = {};

      for (final period in periodRows) {
        final cashBoxId =
        period['cash_box_id']?.toString();

        if (cashBoxId == null ||
            cashBoxId.isEmpty) {
          continue;
        }

        latestPeriodByCashBox.putIfAbsent(
          cashBoxId,
              () => period,
        );
      }

      final cashBoxes = rows.map((row) {
        final id =
            row['id']?.toString() ?? '';

        final latest =
        latestPeriodByCashBox[id];

        /*
         * مدل CashBox مقادیر مالی را هم دارد،
         * ولی این مقادیر از cash_box_periods می‌آیند.
         */
        final merged =
        <String, dynamic>{
          ...row,

          'opening_balance':
          latest?['opening_balance'] ??
              0,

          'total_receipts':
          latest?['total_receipts'] ??
              0,

          'total_payments':
          latest?['total_payments'] ??
              0,

          'closing_balance':
          latest?['closing_balance'] ??
              0,

          'ledger_balance':
          latest?['ledger_balance'] ??
              0,

          'discrepancy':
          latest?['discrepancy'] ??
              0,
        };

        return CashBox.fromMap(merged);
      }).toList();

      if (!mounted) return;

      setState(() {
        _cashBoxes = cashBoxes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _message(
        'خطا در دریافت صندوق‌ها\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // ADD / EDIT DIALOG
  // ============================================================

  Future<void> _showCashBoxDialog({
    CashBox? cashBox,
  }) async {
    final nameController = TextEditingController(
      text: cashBox?.boxName ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              cashBox == null
                  ? 'افزودن صندوق'
                  : 'ویرایش صندوق',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textInputAction:
                        TextInputAction.done,
                        decoration: _inputDecoration(
                          'نام صندوق',
                          Icons.point_of_sale_rounded,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'نام صندوق را وارد کنید';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding:
                        const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFF5F7F6),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color:
                              Color(0xFF6D7973),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'موجودی افتتاحیه، دریافت، پرداخت، مانده دفاتر و مغایرت در دوره مالی ثبت می‌شوند.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.6,
                                  color:
                                  Color(0xFF6D7973),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!
                      .validate()) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF163A2B),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  cashBox == null
                      ? 'ثبت صندوق'
                      : 'ذخیره تغییرات',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      return;
    }

    final name =
    nameController.text.trim();

    nameController.dispose();

    await _saveCashBox(
      cashBox: cashBox,
      name: name,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveCashBox({
    CashBox? cashBox,
    required String name,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (cashBox == null) {
        /*
         * فقط ستون‌های واقعی cash_boxes.
         *
         * opening_balance اینجا وجود ندارد.
         */
        await _supabase
            .from('cash_boxes')
            .insert({
          'company_id':
          widget.companyId,
          'box_name':
          name,
          'created_by':
          userId,
        });
      } else {
        await _supabase
            .from('cash_boxes')
            .update({
          'box_name':
          name,
        })
            .eq(
          'id',
          cashBox.id,
        )
            .eq(
          'company_id',
          widget.companyId,
        );
      }

      if (!mounted) return;

      _message(
        cashBox == null
            ? 'صندوق با موفقیت ثبت شد.'
            : 'صندوق با موفقیت ویرایش شد.',
      );

      ref.invalidate(
        bankingDashboardDataProvider(
          widget.companyId,
        ),
      );

      await _loadCashBoxes();
    } catch (e) {
      if (!mounted) return;

      _message(
        'ثبت صندوق انجام نشد.\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteCashBox(
      CashBox cashBox,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف صندوق',
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
            content: Text(
              'آیا از حذف صندوق «${cashBox.boxName}» مطمئن هستید؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                const Text(
                  'انصراف',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  const Color(
                    0xFF9D3939,
                  ),
                  foregroundColor:
                  Colors.white,
                ),
                child:
                const Text(
                  'حذف',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true ||
        _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _supabase
          .from('cash_boxes')
          .delete()
          .eq(
        'id',
        cashBox.id,
      )
          .eq(
        'company_id',
        widget.companyId,
      );

      if (!mounted) return;

      _message(
        'صندوق حذف شد.',
      );

      ref.invalidate(
        bankingDashboardDataProvider(
          widget.companyId,
        ),
      );

      await _loadCashBoxes();
    } catch (e) {
      if (!mounted) return;

      _message(
        'حذف صندوق انجام نشد.\n$e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return CompanyScaffold(
      companyId:
      widget.companyId,
      currentRoute:
      '/consultant/companies/${widget.companyId}/banking/cash-boxes',
      title:
      'صندوق‌ها',
      body: Directionality(
        textDirection:
        TextDirection.rtl,
        child:
        _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final wide =
            constraints.maxWidth >=
                900;

        return SingleChildScrollView(
          padding:
          EdgeInsets.all(
            wide ? 26 : 18,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
            children: [
              _buildHeader(),
              const SizedBox(
                height: 20,
              ),
              _buildSummary(),
              const SizedBox(
                height: 20,
              ),
              if (_cashBoxes.isEmpty)
                _buildEmpty()
              else
                _buildCashBoxes(
                  wide,
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding:
      const EdgeInsets.all(
        23,
      ),
      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.topRight,
          end:
          Alignment.bottomLeft,
          colors: [
            Color(0xFF163A2B),
            Color(0xFF245842),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          21,
        ),
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final compact =
              constraints.maxWidth <
                  600;

          if (compact) {
            return Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [
                Row(
                  children: [
                    _headerIcon(),
                    const SizedBox(
                      width: 15,
                    ),
                    const Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'صندوق‌ها',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize:
                              21,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          SizedBox(
                            height: 7,
                          ),
                          Text(
                            'مدیریت صندوق‌های نقدی شرکت',
                            style:
                            TextStyle(
                              color:
                              Colors.white70,
                              fontSize:
                              11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                _newButton(),
              ],
            );
          }

          return Row(
            children: [
              _headerIcon(),
              const SizedBox(
                width: 15,
              ),
              const Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'صندوق‌ها',
                      style:
                      TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        23,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                    SizedBox(
                      height: 7,
                    ),
                    Text(
                      'مدیریت صندوق‌های نقدی شرکت',
                      style:
                      TextStyle(
                        color:
                        Colors.white70,
                        fontSize:
                        12,
                      ),
                    ),
                  ],
                ),
              ),
              _newButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _headerIcon() {
    return Container(
      width: 58,
      height: 58,
      decoration:
      BoxDecoration(
        color: Colors.white
            .withOpacity(.12),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: const Icon(
        Icons
            .point_of_sale_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _newButton() {
    return ElevatedButton.icon(
      onPressed:
      _saving
          ? null
          : () =>
          _showCashBoxDialog(),
      icon: const Icon(
        Icons.add_rounded,
      ),
      label:
      const Text(
        'افزودن صندوق',
      ),
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        Colors.white,
        foregroundColor:
        const Color(
          0xFF163A2B,
        ),
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final total =
    _cashBoxes.fold<double>(
      0,
          (sum, box) =>
      sum +
          box.closingBalance,
    );

    final discrepancy =
    _cashBoxes.fold<double>(
      0,
          (sum, box) =>
      sum +
          box.discrepancy.abs(),
    );

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final columns =
        constraints.maxWidth >=
            900
            ? 3
            : constraints.maxWidth >=
            560
            ? 2
            : 1;

        final items = [
          _SummaryData(
            title:
            'تعداد صندوق‌ها',
            value:
            '${_cashBoxes.length}',
            icon: Icons
                .point_of_sale_rounded,
          ),
          _SummaryData(
            title:
            'مجموع آخرین مانده',
            value:
            '${_money(total)} ریال',
            icon: Icons
                .payments_rounded,
          ),
          _SummaryData(
            title:
            'مجموع مغایرت',
            value:
            '${_money(discrepancy)} ریال',
            icon: Icons
                .compare_arrows_rounded,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          itemCount:
          items.length,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
            columns,
            crossAxisSpacing:
            14,
            mainAxisSpacing:
            14,
            mainAxisExtent:
            115,
          ),
          itemBuilder:
              (context, index) {
            return _summaryCard(
              items[index],
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(
      _SummaryData data,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFEAF3EE,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              data.icon,
              color:
              const Color(
                0xFF163A2B,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  data.title,
                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF748078,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Color(
                      0xFF17221D,
                    ),
                    fontSize: 14,
                    fontWeight:
                    FontWeight
                        .w800,
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
  // TABLE
  // ============================================================

  Widget _buildCashBoxes(
      bool wide,
      ) {
    if (!wide) {
      return Column(
        children:
        _cashBoxes
            .map(
              (cashBox) =>
              Padding(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 12,
                ),
                child:
                _cashBoxCard(
                  cashBox,
                ),
              ),
        )
            .toList(),
      );
    }

    return Container(
      decoration:
      _cardDecoration(),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(
            height: 1,
            color:
            Color(0xFFE8EDE9),
          ),
          ..._cashBoxes
              .asMap()
              .entries
              .map(
                (entry) {
              return _tableRow(
                entry.value,
                entry.key,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return const Padding(
      padding:
      EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              '#',
              style:
              _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'صندوق',
              style:
              _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'آخرین مانده',
              style:
              _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'مانده دفاتر',
              style:
              _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'مغایرت',
              style:
              _headerStyle,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'عملیات',
              style:
              _headerStyle,
              textAlign:
              TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(
      CashBox cashBox,
      int index,
      ) {
    final hasDiscrepancy =
        cashBox.discrepancy
            .abs() >
            0;

    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration:
      BoxDecoration(
        color: index.isEven
            ? Colors.white
            : const Color(
          0xFFFAFBFA,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              '${index + 1}',
              style:
              const TextStyle(
                color:
                Color(
                  0xFF89958F,
                ),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              cashBox.boxName,
              style:
              const TextStyle(
                color:
                Color(
                  0xFF26332C,
                ),
                fontSize: 12,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _money(
                cashBox
                    .closingBalance,
              ),
              style:
              const TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _money(
                cashBox
                    .ledgerBalance,
              ),
              style:
              const TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _money(
                cashBox
                    .discrepancy
                    .abs(),
              ),
              style: TextStyle(
                color: hasDiscrepancy
                    ? const Color(
                  0xFF9A6A00,
                )
                    : const Color(
                  0xFF397254,
                ),
                fontSize: 11,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                _iconButton(
                  icon: Icons
                      .edit_rounded,
                  tooltip:
                  'ویرایش',
                  onPressed:
                  _saving
                      ? null
                      : () =>
                      _showCashBoxDialog(
                        cashBox:
                        cashBox,
                      ),
                ),
                _iconButton(
                  icon: Icons
                      .delete_outline_rounded,
                  tooltip:
                  'حذف',
                  danger: true,
                  onPressed:
                  _saving
                      ? null
                      : () =>
                      _deleteCashBox(
                        cashBox,
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
  // MOBILE
  // ============================================================

  Widget _cashBoxCard(
      CashBox cashBox,
      ) {
    final hasDiscrepancy =
        cashBox.discrepancy
            .abs() >
            0;

    return Container(
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEAF3EE,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .point_of_sale_rounded,
                  color:
                  Color(
                    0xFF163A2B,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                Text(
                  cashBox.boxName,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight
                        .w800,
                    fontSize: 14,
                  ),
                ),
              ),
              _iconButton(
                icon:
                Icons.edit_rounded,
                tooltip:
                'ویرایش',
                onPressed:
                _saving
                    ? null
                    : () =>
                    _showCashBoxDialog(
                      cashBox:
                      cashBox,
                    ),
              ),
              _iconButton(
                icon: Icons
                    .delete_outline_rounded,
                tooltip:
                'حذف',
                danger: true,
                onPressed:
                _saving
                    ? null
                    : () =>
                    _deleteCashBox(
                      cashBox,
                    ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          const Divider(
            height: 1,
            color:
            Color(0xFFE8EDE9),
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child:
                _mobileValue(
                  'آخرین مانده',
                  _money(
                    cashBox
                        .closingBalance,
                  ),
                ),
              ),
              Expanded(
                child:
                _mobileValue(
                  'دفاتر',
                  _money(
                    cashBox
                        .ledgerBalance,
                  ),
                ),
              ),
              Expanded(
                child:
                _mobileValue(
                  'مغایرت',
                  _money(
                    cashBox
                        .discrepancy
                        .abs(),
                  ),
                  color:
                  hasDiscrepancy
                      ? const Color(
                    0xFF9A6A00,
                  )
                      : const Color(
                    0xFF397254,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileValue(
      String title,
      String value, {
        Color color =
        const Color(
          0xFF26332C,
        ),
      }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            color:
            Color(
              0xFF89958F,
            ),
            fontSize: 10,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow
              .ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ICON BUTTON
  // ============================================================

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool danger = false,
  }) {
    return IconButton(
      onPressed:
      onPressed,
      tooltip:
      tooltip,
      splashRadius: 20,
      icon: Icon(
        icon,
        size: 19,
        color: danger
            ? const Color(
          0xFF9D3939,
        )
            : const Color(
          0xFF53615A,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 60,
        horizontal: 25,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons
                .point_of_sale_outlined,
            size: 62,
            color:
            Color(0xFF9BA59F),
          ),
          const SizedBox(
            height: 17,
          ),
          const Text(
            'صندوقی ثبت نشده است',
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'برای شروع، اولین صندوق شرکت را ثبت کنید.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Color(0xFF7A8580),
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton.icon(
            onPressed:
            _saving
                ? null
                : () =>
                _showCashBoxDialog(),
            icon: const Icon(
              Icons.add_rounded,
            ),
            label:
            const Text(
              'ثبت صندوق',
            ),
            style:
            ElevatedButton
                .styleFrom(
              backgroundColor:
              const Color(
                0xFF163A2B,
              ),
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 20,
                vertical: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(
            message,
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          error
              ? const Color(
            0xFF9D3939,
          )
              : const Color(
            0xFF397254,
          ),
        ),
      );
  }
}

// ============================================================
// SUMMARY
// ============================================================

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

// ============================================================
// STYLE
// ============================================================

const _headerStyle =
TextStyle(
  color:
  Color(0xFF69756F),
  fontSize: 10,
  fontWeight:
  FontWeight.w800,
);

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius:
    BorderRadius.circular(
      18,
    ),
    border: Border.all(
      color:
      const Color(
        0xFFE7ECE9,
      ),
    ),
    boxShadow: const [
      BoxShadow(
        color:
        Color(0x09000000),
        blurRadius: 18,
        offset:
        Offset(0, 7),
      ),
    ],
  );
}

InputDecoration _inputDecoration(
    String label,
    IconData icon, {
      String? suffix,
    }) {
  return InputDecoration(
    labelText:
    label,
    suffixText:
    suffix,
    prefixIcon:
    Icon(
      icon,
      size: 20,
    ),
    filled: true,
    fillColor:
    const Color(
      0xFFF8FAF9,
    ),
    border:
    OutlineInputBorder(
      borderRadius:
      BorderRadius
          .circular(
        12,
      ),
      borderSide:
      const BorderSide(
        color:
        Color(0xFFE0E6E2),
      ),
    ),
    enabledBorder:
    OutlineInputBorder(
      borderRadius:
      BorderRadius
          .circular(
        12,
      ),
      borderSide:
      const BorderSide(
        color:
        Color(0xFFE0E6E2),
      ),
    ),
    focusedBorder:
    OutlineInputBorder(
      borderRadius:
      BorderRadius
          .circular(
        12,
      ),
      borderSide:
      const BorderSide(
        color:
        Color(0xFF397254),
        width: 1.5,
      ),
    ),
  );
}

// ============================================================
// MONEY
// ============================================================

String _money(
    double value,
    ) {
  final negative =
      value < 0;

  final text =
  value.abs()
      .round()
      .toString();

  var result = '';

  for (
  var i = 0;
  i < text.length;
  i++
  ) {
    if (i > 0 &&
        (text.length - i) %
            3 ==
            0) {
      result += '٬';
    }

    result += text[i];
  }

  return '${negative ? '-' : ''}$result';
}