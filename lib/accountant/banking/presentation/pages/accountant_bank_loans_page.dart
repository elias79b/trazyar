import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/banking/application/accountant_bank_loans_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantBankLoansPage extends ConsumerWidget {
  final String companyId;

  const AccountantBankLoansPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantBankLoansProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/loans',
      title: 'تسهیلات بانکی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(accountantBankLoansProvider(companyId));
              },
            );
          },
          data: (items) {
            return _LoansContent(
              companyId: companyId,
              items: items,
              onRefresh: () {
                ref.invalidate(accountantBankLoansProvider(companyId));
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoansContent extends StatelessWidget {
  final String companyId;
  final List<AccountantBankLoan> items;
  final VoidCallback onRefresh;

  const _LoansContent({
    required this.companyId,
    required this.items,
    required this.onRefresh,
  });

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _LoanDialog(companyId: companyId),
    );

    if (result == true) {
      onRefresh();
    }
  }

  double get totalPrincipal {
    return items.fold(0, (sum, item) => sum + item.principalAmount);
  }

  double get totalRemaining {
    return items.fold(0, (sum, item) => sum + item.remainingAmount);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF7C3AED),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تسهیلات بانکی',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${items.length} تسهیلات ثبت شده',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openCreateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('افزودن تسهیلات'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SummaryRow(
            count: items.length,
            totalPrincipal: totalPrincipal,
            totalRemaining: totalRemaining,
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            _EmptyState(onAdd: () => _openCreateDialog(context))
          else
            _LoansGrid(
              items: items,
              companyId: companyId,
              onChanged: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int count;
  final double totalPrincipal;
  final double totalRemaining;

  const _SummaryRow({
    required this.count,
    required this.totalPrincipal,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 700 ? 1 : 3;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: width < 700 ? 3.4 : 2.6,
      children: [
        _SummaryCard(
          title: 'تعداد تسهیلات',
          value: _formatNumber(count),
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF7C3AED),
        ),
        _SummaryCard(
          title: 'مبلغ کل تسهیلات',
          value: _formatMoney(totalPrincipal),
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF2563EB),
        ),
        _SummaryCard(
          title: 'مانده بدهی',
          value: _formatMoney(totalRemaining),
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} ریال';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
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
}

class _LoansGrid extends StatelessWidget {
  final List<AccountantBankLoan> items;
  final String companyId;
  final VoidCallback onChanged;

  const _LoansGrid({
    required this.items,
    required this.companyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final columns =
        width >= 1300
            ? 3
            : width >= 850
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _LoanCard(
          item: items[index],
          companyId: companyId,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _LoanCard extends StatelessWidget {
  final AccountantBankLoan item;
  final String companyId;
  final VoidCallback onChanged;

  const _LoanCard({
    required this.item,
    required this.companyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.bankName.isEmpty ? 'بانک نامشخص' : item.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.loanType.isEmpty
                          ? 'نوع تسهیلات مشخص نشده'
                          : item.loanType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => _LoanDialog(companyId: companyId, item: item),
                    );

                    if (result == true) {
                      onChanged();
                    }
                  }

                  if (value == 'delete') {
                    final confirmed = await _confirmDelete(context);

                    if (!confirmed) return;

                    try {
                      await AccountantBankLoansRepository.delete(item.id);

                      onChanged();
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حذف تسهیلات انجام نشد: $e')),
                      );
                    }
                  }
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('ویرایش'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            label: 'اصل تسهیلات',
            value: _formatMoney(item.principalAmount),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'مانده',
            value: _formatMoney(item.remainingAmount),
            valueColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'نرخ سود',
            value: '${item.interestRate.toStringAsFixed(2)}٪',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'قسط ماهانه',
            value: _formatMoney(item.monthlyInstallment),
          ),
          const Spacer(),
          if (item.startDate != null || item.endDate != null)
            Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(item.startDate)} تا ${_formatDate(item.endDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف تسهیلات', textDirection: TextDirection.rtl),
          content: const Text(
            'آیا از حذف این تسهیلات مطمئن هستید؟',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} ریال';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoanDialog extends StatefulWidget {
  final String companyId;
  final AccountantBankLoan? item;

  const _LoanDialog({required this.companyId, this.item});

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankController;
  late final TextEditingController _typeController;
  late final TextEditingController _principalController;
  late final TextEditingController _remainingController;
  late final TextEditingController _interestController;
  late final TextEditingController _installmentController;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _bankController = TextEditingController(text: item?.bankName ?? '');

    _typeController = TextEditingController(text: item?.loanType ?? '');

    _principalController = TextEditingController(
      text: item == null ? '' : _numberText(item.principalAmount),
    );

    _remainingController = TextEditingController(
      text: item == null ? '' : _numberText(item.remainingAmount),
    );

    _interestController = TextEditingController(
      text: item == null ? '' : _numberText(item.interestRate),
    );

    _installmentController = TextEditingController(
      text: item == null ? '' : _numberText(item.monthlyInstallment),
    );

    _startDate = item?.startDate;
    _endDate = item?.endDate;
  }

  @override
  void dispose() {
    _bankController.dispose();
    _typeController.dispose();
    _principalController.dispose();
    _remainingController.dispose();
    _interestController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  String _numberText(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  double _parseNumber(String value) {
    return double.tryParse(
          value.trim().replaceAll(',', '').replaceAll('٬', ''),
        ) ??
        0;
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1300),
      lastDate: DateTime(2200),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(1300),
      lastDate: DateTime(2200),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final principal = _parseNumber(_principalController.text);
    final remaining = _parseNumber(_remainingController.text);
    final interest = _parseNumber(_interestController.text);
    final installment = _parseNumber(_installmentController.text);

    setState(() {
      _loading = true;
    });

    try {
      if (isEdit) {
        await AccountantBankLoansRepository.update(
          id: widget.item!.id,
          bankName: _bankController.text,
          loanType: _typeController.text,
          principalAmount: principal,
          remainingAmount: remaining,
          interestRate: interest,
          startDate: _startDate,
          endDate: _endDate,
          monthlyInstallment: installment,
        );
      } else {
        await AccountantBankLoansRepository.create(
          companyId: widget.companyId,
          bankName: _bankController.text,
          loanType: _typeController.text,
          principalAmount: principal,
          remainingAmount: remaining,
          interestRate: interest,
          startDate: _startDate,
          endDate: _endDate,
          monthlyInstallment: installment,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'ویرایش تسهیلات انجام نشد: $e'
                : 'ثبت تسهیلات انجام نشد: $e',
          ),
        ),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isEdit ? 'ویرایش تسهیلات' : 'افزودن تسهیلات'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _bankController,
                    decoration: _decoration(
                      'نام بانک',
                      Icons.account_balance_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام بانک را وارد کنید';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _typeController,
                    decoration: _decoration(
                      'نوع تسهیلات',
                      Icons.category_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نوع تسهیلات را وارد کنید';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _principalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(
                      'مبلغ اصل تسهیلات',
                      Icons.payments_outlined,
                    ),
                    validator: (value) {
                      if (_parseNumber(value ?? '') <= 0) {
                        return 'مبلغ معتبر وارد کنید';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _remainingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(
                      'مانده تسهیلات',
                      Icons.account_balance_wallet_outlined,
                    ),
                    validator: (value) {
                      if (_parseNumber(value ?? '') < 0) {
                        return 'مبلغ معتبر وارد کنید';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _interestController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(
                      'نرخ سود (%)',
                      Icons.percent_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _installmentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration(
                      'قسط ماهانه',
                      Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _pickStartDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _startDate == null
                                ? 'تاریخ شروع'
                                : 'شروع: ${_formatDate(_startDate)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _pickEndDate,
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(
                            _endDate == null
                                ? 'تاریخ پایان'
                                : 'پایان: ${_formatDate(_endDate)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child:
                _loading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(isEdit ? 'ذخیره تغییرات' : 'ثبت تسهیلات'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 38,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'هنوز تسهیلاتی ثبت نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، اولین تسهیلات بانکی شرکت را ثبت کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن تسهیلات'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'دریافت تسهیلات انجام نشد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
