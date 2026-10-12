import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

import '../../application/company_admin_bank_accounts_provider.dart';

class CompanyAdminBankAccountsPage extends ConsumerWidget {
  const CompanyAdminBankAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(
      companyAdminBankAccountsProvider,
    );

    return CompanyAdminScaffold(
      child: accountsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          return _ErrorView(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(
                companyAdminBankAccountsProvider,
              );
            },
          );
        },
        data: (accounts) {
          return _BankAccountsContent(
            accounts: accounts,
          );
        },
      ),
    );
  }
}

class _BankAccountsContent extends ConsumerWidget {
  final List<CompanyAdminBankAccount> accounts;

  const _BankAccountsContent({
    required this.accounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = accounts.fold<double>(
      0,
          (sum, account) => sum + account.closingBalance,
    );

    final totalDebit = accounts.fold<double>(
      0,
          (sum, account) => sum + account.debitTurnover,
    );

    final totalCredit = accounts.fold<double>(
      0,
          (sum, account) => sum + account.creditTurnover,
    );

    final totalDiscrepancy = accounts.fold<double>(
      0,
          (sum, account) => sum + account.discrepancy,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(
                accountCount: accounts.length,
                onAdd: () {
                  _showAccountDialog(
                    context,
                    ref,
                  );
                },
                onRefresh: () {
                  ref.invalidate(
                    companyAdminBankAccountsProvider,
                  );
                },
              ),

              const SizedBox(height: 24),

              _SummaryCards(
                accountCount: accounts.length,
                totalBalance: totalBalance,
                totalDebit: totalDebit,
                totalCredit: totalCredit,
                totalDiscrepancy: totalDiscrepancy,
              ),

              const SizedBox(height: 24),

              if (accounts.isEmpty)
                _EmptyAccounts(
                  onAdd: () {
                    _showAccountDialog(
                      context,
                      ref,
                    );
                  },
                )
              else
                _AccountsTable(
                  accounts: accounts,
                  onEdit: (account) {
                    _showAccountDialog(
                      context,
                      ref,
                      account: account,
                    );
                  },
                  onDelete: (account) {
                    _showDeleteDialog(
                      context,
                      ref,
                      account,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int accountCount;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  const _PageHeader({
    required this.accountCount,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حساب‌های بانکی',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$accountCount حساب بانکی ثبت شده',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('بروزرسانی'),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('افزودن حساب بانکی'),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int accountCount;
  final double totalBalance;
  final double totalDebit;
  final double totalCredit;
  final double totalDiscrepancy;

  const _SummaryCards({
    required this.accountCount,
    required this.totalBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.totalDiscrepancy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width >= 1200
            ? (width - 48) / 4
            : width >= 800
            ? (width - 16) / 2
            : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'تعداد حساب‌ها',
                value: accountCount.toString(),
                icon: Icons.account_balance,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'مجموع مانده',
                value: _money(totalBalance),
                icon: Icons.account_balance_wallet,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'گردش بدهکار',
                value: _money(totalDebit),
                icon: Icons.arrow_downward,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'مغایرت',
                value: _money(totalDiscrepancy),
                icon: Icons.warning_amber_rounded,
                warning: totalDiscrepancy.abs() > 0.01,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool warning;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: warning
                    ? Colors.orange.withOpacity(.12)
                    : Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: warning
                    ? Colors.orange.shade700
                    : Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}

class _AccountsTable extends StatelessWidget {
  final List<CompanyAdminBankAccount> accounts;
  final ValueChanged<CompanyAdminBankAccount> onEdit;
  final ValueChanged<CompanyAdminBankAccount> onDelete;

  const _AccountsTable({
    required this.accounts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 56,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(
              label: Text('بانک'),
            ),
            DataColumn(
              label: Text('شماره حساب'),
            ),
            DataColumn(
              label: Text('مانده افتتاحیه'),
            ),
            DataColumn(
              label: Text('گردش بدهکار'),
            ),
            DataColumn(
              label: Text('گردش بستانکار'),
            ),
            DataColumn(
              label: Text('مانده پایان'),
            ),
            DataColumn(
              label: Text('مانده دفاتر'),
            ),
            DataColumn(
              label: Text('مغایرت'),
            ),
            DataColumn(
              label: Text('وضعیت'),
            ),
            DataColumn(
              label: Text('عملیات'),
            ),
          ],
          rows: accounts.map((account) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    account.bankName.isEmpty
                        ? 'بدون نام'
                        : account.bankName,
                  ),
                ),

                DataCell(
                  Text(
                    account.accountNumber.isEmpty
                        ? '-'
                        : account.accountNumber,
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.openingBalance),
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.debitTurnover),
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.creditTurnover),
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.closingBalance),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.ledgerBalance),
                  ),
                ),

                DataCell(
                  Text(
                    _money(account.discrepancy),
                    style: TextStyle(
                      color: account.hasDiscrepancy
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),

                DataCell(
                  _StatusBadge(
                    account: account,
                  ),
                ),

                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'ویرایش',
                        onPressed: () => onEdit(account),
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                      ),

                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () => onDelete(account),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CompanyAdminBankAccount account;

  const _StatusBadge({
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    if (!account.hasPeriodData) {
      return _Badge(
        text: 'بدون دوره',
        background: Colors.grey.shade200,
        foreground: Colors.grey.shade700,
      );
    }

    if (account.hasDiscrepancy) {
      return _Badge(
        text: 'دارای مغایرت',
        background: Colors.orange.withOpacity(.12),
        foreground: Colors.orange.shade800,
      );
    }

    return _Badge(
      text: 'تأیید شده',
      background: Colors.green.withOpacity(.12),
      foreground: Colors.green.shade700,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAccounts({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 70,
          horizontal: 24,
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'هنوز حساب بانکی ثبت نشده است.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'برای شروع، اولین حساب بانکی شرکت را ثبت کنید.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text(
                'افزودن حساب بانکی',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'خطا در دریافت حساب‌های بانکی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAccountDialog(
    BuildContext context,
    WidgetRef ref, {
      CompanyAdminBankAccount? account,
    }) async {
  final bool isEdit = account != null;

  final bankNameController = TextEditingController(
    text: account?.bankName ?? '',
  );

  final accountNumberController = TextEditingController(
    text: account?.accountNumber ?? '',
  );

  final formKey = GlobalKey<FormState>();

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              isEdit
                  ? 'ویرایش حساب بانکی'
                  : 'افزودن حساب بانکی',
            ),
            content: SizedBox(
              width: 450,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: bankNameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'نام بانک',
                        hintText: 'مثلاً بانک ملت',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.account_balance_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'نام بانک را وارد کنید.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'شماره حساب',
                        hintText: 'شماره حساب بانکی',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.numbers,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'شماره حساب را وارد کنید.';
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'انصراف',
                ),
              ),

              Consumer(
                builder: (context, ref, child) {
                  final mutation = ref.watch(
                    companyAdminBankAccountsControllerProvider,
                  );

                  final bool loading = mutation.isLoading;

                  return FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                      if (!formKey.currentState!
                          .validate()) {
                        return;
                      }

                      final controller = ref.read(
                        companyAdminBankAccountsControllerProvider
                            .notifier,
                      );

                      if (isEdit) {
                        await controller.updateAccount(
                          accountId: account!.id,
                          bankName:
                          bankNameController.text,
                          accountNumber:
                          accountNumberController.text,
                        );
                      } else {
                        await controller.addAccount(
                          bankName:
                          bankNameController.text,
                          accountNumber:
                          accountNumberController.text,
                        );
                      }

                      final result = ref.read(
                        companyAdminBankAccountsControllerProvider,
                      );

                      if (result.hasError) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                _cleanError(
                                  result.error.toString(),
                                ),
                              ),
                              backgroundColor:
                              Colors.red.shade700,
                            ),
                          );
                        }

                        return;
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(
                          dialogContext,
                        ).pop();

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'حساب بانکی با موفقیت ویرایش شد.'
                                  : 'حساب بانکی با موفقیت اضافه شد.',
                            ),
                            backgroundColor:
                            Colors.green.shade700,
                          ),
                        );
                      }
                    },
                    child: loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isEdit
                          ? 'ذخیره تغییرات'
                          : 'افزودن',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  } finally {
    bankNameController.dispose();
    accountNumberController.dispose();
  }
}

Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CompanyAdminBankAccount account,
    ) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف حساب بانکی',
          ),
          content: Text(
            'آیا از حذف حساب «${account.bankName}» '
                'با شماره «${account.accountNumber}» '
                'مطمئن هستید؟\n\n'
                'این عملیات قابل بازگشت نیست.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'انصراف',
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'حذف',
              ),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final controller = ref.read(
    companyAdminBankAccountsControllerProvider.notifier,
  );

  await controller.deleteAccount(
    accountId: account.id,
  );

  if (!context.mounted) {
    return;
  }

  final result = ref.read(
    companyAdminBankAccountsControllerProvider,
  );

  if (result.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _cleanError(
            result.error.toString(),
          ),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'حساب بانکی با موفقیت حذف شد.',
      ),
      backgroundColor: Colors.green.shade700,
    ),
  );
}

String _money(double value) {
  final String rounded = value.round().toString();

  final chars = rounded.split('');
  final buffer = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    final reverseIndex = chars.length - i;

    buffer.write(chars[i]);

    if (reverseIndex > 1 &&
        reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${buffer.toString()} ریال';
}

String _cleanError(String error) {
  if (error.contains('foreign key')) {
    return 'این حساب دارای اطلاعات وابسته است و امکان حذف آن وجود ندارد.';
  }

  if (error.contains('duplicate')) {
    return 'اطلاعات واردشده تکراری است.';
  }

  if (error.contains('violates row-level security')) {
    return 'دسترسی لازم برای این عملیات وجود ندارد.';
  }

  return error
      .replaceFirst('Exception: ', '')
      .replaceFirst(
    'PostgrestException(message: ',
    '',
  )
      .trim();
}