import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/banking/application/banking_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../data/models/banking_models.dart';

class BankAccountsPage extends ConsumerStatefulWidget {
  final String companyId;

  const BankAccountsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<BankAccountsPage> createState() =>
      _BankAccountsPageState();
}

class _BankAccountsPageState
    extends ConsumerState<BankAccountsPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  List<BankAccount> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadAccounts() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      /*
       * ساختار واقعی bank_accounts:
       *
       * id
       * company_id
       * bank_name
       * account_number
       * created_by
       * created_at
       *
       * هیچ ستون مالی در این جدول وجود ندارد.
       */

      final accountsResponse =
      await _supabase
          .from('bank_accounts')
          .select(
        'id,'
            'company_id,'
            'bank_name,'
            'account_number,'
            'created_by,'
            'created_at',
      )
          .eq(
        'company_id',
        widget.companyId,
      )
          .order('bank_name');

      /*
       * اطلاعات مالی حساب‌ها از جدول دوره‌ای می‌آید.
       *
       * notes عمداً حذف شده چون در ساختار واقعی
       * bank_account_periods وجود ندارد.
       */
      final periodsResponse =
      await _supabase
          .from('bank_account_periods')
          .select(
        'id,'
            'company_id,'
            'period_id,'
            'bank_account_id,'
            'opening_balance,'
            'debit_turnover,'
            'credit_turnover,'
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

      final accountsRaw =
      List<Map<String, dynamic>>.from(
        accountsResponse as List,
      );

      final periodsRaw =
      List<Map<String, dynamic>>.from(
        periodsResponse as List,
      );

      /*
       * چون دوره‌ها نزولی هستند،
       * اولین رکورد هر حساب، آخرین رکورد ثبت‌شده است.
       */
      final Map<String, Map<String, dynamic>>
      latestPeriodByAccount = {};

      for (final period in periodsRaw) {
        final accountId =
        period['bank_account_id']?.toString();

        if (accountId == null ||
            accountId.isEmpty) {
          continue;
        }

        latestPeriodByAccount.putIfAbsent(
          accountId,
              () => period,
        );
      }

      final accounts =
      accountsRaw.map((account) {
        final accountId =
            account['id']?.toString() ?? '';

        final latestPeriod =
        latestPeriodByAccount[accountId];

        /*
         * مدل BankAccount فعلی پروژه برای مقادیر
         * مالی این کلیدها را انتظار دارد.
         *
         * اما این کلیدها از bank_accounts نمی‌آیند؛
         * از آخرین bank_account_periods می‌آیند.
         */
        final merged =
        <String, dynamic>{
          ...account,

          'opening_balance':
          latestPeriod?[
          'opening_balance'
          ] ??
              0,

          'debit_turnover':
          latestPeriod?[
          'debit_turnover'
          ] ??
              0,

          'credit_turnover':
          latestPeriod?[
          'credit_turnover'
          ] ??
              0,

          'closing_balance':
          latestPeriod?[
          'closing_balance'
          ] ??
              0,

          'ledger_balance':
          latestPeriod?[
          'ledger_balance'
          ] ??
              0,

          'discrepancy':
          latestPeriod?[
          'discrepancy'
          ] ??
              0,
        };

        return BankAccount.fromMap(
          merged,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _message(
        'خطا در دریافت حساب‌های بانکی\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // ADD / EDIT DIALOG
  // ============================================================

  Future<void> _showAccountDialog({
    BankAccount? account,
  }) async {
    final bankController =
    TextEditingController(
      text: account?.bankName ?? '',
    );

    final numberController =
    TextEditingController(
      text: account?.accountNumber ?? '',
    );

    final formKey =
    GlobalKey<FormState>();

    final result =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              account == null
                  ? 'افزودن حساب بانکی'
                  : 'ویرایش حساب بانکی',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller:
                        bankController,
                        textInputAction:
                        TextInputAction
                            .next,
                        decoration:
                        _inputDecoration(
                          'نام بانک',
                          Icons
                              .account_balance_rounded,
                        ),
                        validator:
                            (value) {
                          if (value ==
                              null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'نام بانک را وارد کنید';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      TextFormField(
                        controller:
                        numberController,
                        keyboardType:
                        TextInputType
                            .number,
                        textInputAction:
                        TextInputAction
                            .done,
                        decoration:
                        _inputDecoration(
                          'شماره حساب',
                          Icons
                              .numbers_rounded,
                        ),
                        validator:
                            (value) {
                          if (value ==
                              null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'شماره حساب را وارد کنید';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Container(
                        padding:
                        const EdgeInsets
                            .all(12),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFF5F7F6,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              size: 18,
                              color:
                              Color(
                                0xFF6D7973,
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                'موجودی افتتاحیه، گردش بدهکار و بستانکار، مانده دفاتر و مغایرت در دوره‌های ماهانه ثبت می‌شوند.',
                                style:
                                TextStyle(
                                  fontSize:
                                  11,
                                  height:
                                  1.6,
                                  color:
                                  Color(
                                    0xFF6D7973,
                                  ),
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
                child:
                const Text(
                  'انصراف',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey
                      .currentState!
                      .validate()) {
                    return;
                  }

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
                    0xFF163A2B,
                  ),
                  foregroundColor:
                  Colors.white,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  account == null
                      ? 'ثبت حساب'
                      : 'ذخیره تغییرات',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) {
      bankController.dispose();
      numberController.dispose();
      return;
    }

    final bankName =
    bankController.text.trim();

    final accountNumber =
    numberController.text.trim();

    bankController.dispose();
    numberController.dispose();

    await _saveAccount(
      account: account,
      bankName: bankName,
      accountNumber:
      accountNumber,
    );
  }

  // ============================================================
  // SAVE ACCOUNT
  // ============================================================

  Future<void> _saveAccount({
    BankAccount? account,
    required String bankName,
    required String accountNumber,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (account == null) {
        /*
         * ثبت حساب جدید:
         * فقط ستون‌های واقعی bank_accounts
         */
        await _supabase
            .from('bank_accounts')
            .insert({
          'company_id':
          widget.companyId,
          'bank_name':
          bankName,
          'account_number':
          accountNumber,
          'created_by':
          userId,
        });
      } else {
        /*
         * ویرایش حساب:
         * فقط اطلاعات اصلی حساب
         */
        await _supabase
            .from('bank_accounts')
            .update({
          'bank_name':
          bankName,
          'account_number':
          accountNumber,
        })
            .eq(
          'id',
          account.id,
        )
            .eq(
          'company_id',
          widget.companyId,
        );
      }

      if (!mounted) return;

      _message(
        account == null
            ? 'حساب بانکی با موفقیت ثبت شد.'
            : 'حساب بانکی با موفقیت ویرایش شد.',
      );

      ref.invalidate(
        bankingDashboardDataProvider(
          widget.companyId,
        ),
      );

      await _loadAccounts();
    } catch (e) {
      if (!mounted) return;

      _message(
        'ثبت اطلاعات انجام نشد.\n$e',
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

  Future<void> _deleteAccount(
      BankAccount account,
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
              'حذف حساب بانکی',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w800,
              ),
            ),
            content: Text(
              'آیا از حذف حساب «${account.bankName}» با شماره ${account.accountNumber} مطمئن هستید؟',
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
          .from('bank_accounts')
          .delete()
          .eq(
        'id',
        account.id,
      )
          .eq(
        'company_id',
        widget.companyId,
      );

      if (!mounted) return;

      _message(
        'حساب بانکی حذف شد.',
      );

      ref.invalidate(
        bankingDashboardDataProvider(
          widget.companyId,
        ),
      );

      await _loadAccounts();
    } catch (e) {
      if (!mounted) return;

      _message(
        'حذف حساب انجام نشد.\n$e',
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
      '/consultant/companies/${widget.companyId}/banking/accounts',
      title:
      'حساب‌های بانکی',
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
              if (_accounts.isEmpty)
                _buildEmpty()
              else
                _buildAccountsTable(
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
      const EdgeInsets.all(23),
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
                            'حساب‌های بانکی',
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
                            'ثبت و مدیریت حساب‌های بانکی شرکت',
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
                ElevatedButton.icon(
                  onPressed:
                  _saving
                      ? null
                      : () =>
                      _showAccountDialog(),
                  icon: const Icon(
                    Icons
                        .add_rounded,
                  ),
                  label:
                  const Text(
                    'حساب جدید',
                  ),
                  style:
                  ElevatedButton
                      .styleFrom(
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
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                  ),
                ),
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
                      'حساب‌های بانکی',
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
                      'ثبت و مدیریت حساب‌های بانکی شرکت',
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
              ElevatedButton.icon(
                onPressed:
                _saving
                    ? null
                    : () =>
                    _showAccountDialog(),
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text(
                  'حساب جدید',
                ),
                style:
                ElevatedButton
                    .styleFrom(
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
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
              ),
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
            .account_balance_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final total =
    _accounts.fold<double>(
      0,
          (
          sum,
          account,
          ) =>
      sum +
          account.closingBalance,
    );

    final discrepancy =
    _accounts.fold<double>(
      0,
          (
          sum,
          account,
          ) =>
      sum +
          account.discrepancy.abs(),
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
            'تعداد حساب‌ها',
            value:
            '${_accounts.length}',
            icon: Icons
                .account_balance_rounded,
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
  // TABLE / CARDS
  // ============================================================

  Widget _buildAccountsTable(
      bool wide,
      ) {
    if (!wide) {
      return Column(
        children:
        _accounts
            .map(
              (account) =>
              Padding(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 12,
                ),
                child:
                _accountCard(
                  account,
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
          ..._accounts
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
              'بانک',
              style:
              _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'شماره حساب',
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
      BankAccount account,
      int index,
      ) {
    final hasDiscrepancy =
        account.discrepancy
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
              account.bankName,
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
            flex: 2,
            child: Text(
              account
                  .accountNumber,
              style:
              const TextStyle(
                color:
                Color(
                  0xFF66736C,
                ),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _money(
                account
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
                account
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
                account
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
                      _showAccountDialog(
                        account:
                        account,
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
                      _deleteAccount(
                        account,
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
  // MOBILE CARD
  // ============================================================

  Widget _accountCard(
      BankAccount account,
      ) {
    final hasDiscrepancy =
        account.discrepancy
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
                  BorderRadius
                      .circular(
                    13,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .account_balance_rounded,
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
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      account
                          .bankName,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      account
                          .accountNumber,
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF7A8580,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                    _showAccountDialog(
                      account:
                      account,
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
                    _deleteAccount(
                      account,
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
                  'افتتاحیه',
                  _money(
                    account
                        .openingBalance,
                  ),
                ),
              ),
              Expanded(
                child:
                _mobileValue(
                  'مانده',
                  _money(
                    account
                        .closingBalance,
                  ),
                ),
              ),
              Expanded(
                child:
                _mobileValue(
                  'دفاتر',
                  _money(
                    account
                        .ledgerBalance,
                  ),
                ),
              ),
              Expanded(
                child:
                _mobileValue(
                  'مغایرت',
                  _money(
                    account
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
                .account_balance_outlined,
            size: 62,
            color:
            Color(0xFF9BA59F),
          ),
          const SizedBox(
            height: 17,
          ),
          const Text(
            'حساب بانکی ثبت نشده است',
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
            'برای شروع، اولین حساب بانکی شرکت را ثبت کنید.',
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
                _showAccountDialog(),
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'ثبت حساب بانکی',
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
          content: Text(
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
// SUMMARY MODEL
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
// STYLES
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