import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/accountant/banking/application/accountant_banking_accounts_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantBankAccountsPage extends ConsumerWidget {
  final String companyId;

  const AccountantBankAccountsPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountantBankingAccountsProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/accounts',
      title: 'حساب‌های بانکی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: accounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(accountantBankingAccountsProvider(companyId));
                },
              ),
          data: (items) {
            return _AccountsContent(
              companyId: companyId,
              accounts: items,
              onRefresh: () {
                ref.invalidate(accountantBankingAccountsProvider(companyId));
              },
            );
          },
        ),
      ),
    );
  }
}

class _AccountsContent extends StatelessWidget {
  final String companyId;
  final List<AccountantBankAccount> accounts;
  final VoidCallback onRefresh;

  const _AccountsContent({
    required this.companyId,
    required this.accounts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: accounts.length,
            onAdd: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => _AccountDialog(companyId: companyId),
              );

              if (result == true) {
                onRefresh();
              }
            },
          ),
          const SizedBox(height: 24),
          if (accounts.isEmpty)
            _EmptyState(
              onAdd: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => _AccountDialog(companyId: companyId),
                );

                if (result == true) {
                  onRefresh();
                }
              },
            )
          else
            _AccountsGrid(
              accounts: accounts,
              companyId: companyId,
              onChanged: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const _Header({required this.count, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F3ED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Color(0xFF167A56),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حساب‌های بانکی',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                '$count حساب بانکی ثبت شده',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('افزودن حساب'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF167A56),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _AccountsGrid extends StatelessWidget {
  final List<AccountantBankAccount> accounts;
  final String companyId;
  final VoidCallback onChanged;

  const _AccountsGrid({
    required this.accounts,
    required this.companyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final columns =
        width >= 1200
            ? 3
            : width >= 800
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.55,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];

        return _AccountCard(
          account: account,
          companyId: companyId,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountantBankAccount account;
  final String companyId;
  final VoidCallback onChanged;

  const _AccountCard({
    required this.account,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF167A56),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.bankName.isEmpty ? 'بانک نامشخص' : account.bankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => _AccountDialog(
                            companyId: companyId,
                            account: account,
                          ),
                    );

                    if (result == true) {
                      onChanged();
                    }
                  }

                  if (value == 'delete') {
                    final confirmed = await _confirmDelete(context);

                    if (!confirmed) return;

                    try {
                      await AccountantBankingAccountsRepository.delete(
                        account.id,
                      );

                      onChanged();
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حذف حساب انجام نشد: $e')),
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
          const SizedBox(height: 24),
          Text(
            'شماره حساب',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 7),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              account.accountNumber.isEmpty ? '—' : account.accountNumber,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
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
          title: const Text('حذف حساب بانکی', textDirection: TextDirection.rtl),
          content: const Text(
            'آیا از حذف این حساب بانکی مطمئن هستید؟',
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
}

class _AccountDialog extends StatefulWidget {
  final String companyId;
  final AccountantBankAccount? account;

  const _AccountDialog({required this.companyId, this.account});

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankController;
  late final TextEditingController _accountController;

  bool _loading = false;

  bool get isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();

    _bankController = TextEditingController(
      text: widget.account?.bankName ?? '',
    );

    _accountController = TextEditingController(
      text: widget.account?.accountNumber ?? '',
    );
  }

  @override
  void dispose() {
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (isEdit) {
        await AccountantBankingAccountsRepository.update(
          id: widget.account!.id,
          bankName: _bankController.text,
          accountNumber: _accountController.text,
        );
      } else {
        await AccountantBankingAccountsRepository.create(
          companyId: widget.companyId,
          bankName: _bankController.text,
          accountNumber: _accountController.text,
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
            isEdit ? 'ویرایش حساب انجام نشد: $e' : 'ثبت حساب انجام نشد: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isEdit ? 'ویرایش حساب بانکی' : 'افزودن حساب بانکی'),
        content: SizedBox(
          width: 430,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _bankController,
                  decoration: const InputDecoration(
                    labelText: 'نام بانک',
                    hintText: 'مثلاً بانک ملت',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام بانک را وارد کنید';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'شماره حساب',
                    hintText: 'شماره حساب بانکی',
                    prefixIcon: Icon(Icons.numbers_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'شماره حساب را وارد کنید';
                    }

                    return null;
                  },
                ),
              ],
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
              backgroundColor: const Color(0xFF167A56),
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
                    : Text(isEdit ? 'ذخیره تغییرات' : 'ثبت حساب'),
          ),
        ],
      ),
    );
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
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 38,
              color: Color(0xFF167A56),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'هنوز حساب بانکی ثبت نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، اولین حساب بانکی شرکت را ثبت کنید.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن حساب بانکی'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF167A56),
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
              'دریافت حساب‌های بانکی انجام نشد',
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
