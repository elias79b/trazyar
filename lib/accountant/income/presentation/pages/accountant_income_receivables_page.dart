import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/income/application/accountant_income_receivables_provider.dart';

class AccountantIncomeReceivablesPage extends ConsumerStatefulWidget {
  final String periodId;

  const AccountantIncomeReceivablesPage({
    super.key,
    required this.periodId,
  });

  @override
  ConsumerState<AccountantIncomeReceivablesPage> createState() =>
      _AccountantIncomeReceivablesPageState();
}

class _AccountantIncomeReceivablesPageState
    extends ConsumerState<AccountantIncomeReceivablesPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantIncomeReceivablesProvider(widget.periodId),
    );

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) {
        return _ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(
              accountantIncomeReceivablesProvider(widget.periodId),
            );
          },
        );
      },
      data: (data) {
        return _PageContent(
          data: data,
          onRefresh: () async {
            ref.invalidate(
              accountantIncomeReceivablesProvider(widget.periodId),
            );

            await ref.read(
              accountantIncomeReceivablesProvider(widget.periodId).future,
            );
          },
          onAdd: data.period.isOpen
              ? () => _openReceivableDialog()
              : null,
          onEdit: data.period.isOpen
              ? (item) => _openReceivableDialog(item: item)
              : null,
          onDelete: data.period.isOpen
              ? (item) => _deleteReceivable(item)
              : null,
          onWorkflow: (action) =>
              _processPeriodWorkflow(data.period, action),
        );
      },
    );
  }

  // ============================================================
  // PERIOD WORKFLOW
  // ============================================================

  Future<void> _processPeriodWorkflow(
      AccountantIncomeReceivablePeriod period,
      String action,
      ) async {
    final note = await _askWorkflowNote(
      action: action,
      period: period,
    );

    if (note == null) {
      return;
    }

    try {
      await AccountantIncomeReceivablesRepository.processPeriodWorkflow(
        periodId: period.id,
        action: action,
        note: note,
      );

      ref.invalidate(
        accountantIncomeReceivablesProvider(widget.periodId),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _workflowSuccessMessage(action),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  Future<String?> _askWorkflowNote({
    required String action,
    required AccountantIncomeReceivablePeriod period,
  }) async {
    final controller = TextEditingController();

    final requiresNote =
        action == 'return_to_accountant' ||
            action == 'return_by_consultant';

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _workflowDialogTitle(action),
            textDirection: TextDirection.rtl,
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${period.displayTitle} • ${period.year}',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'این عملیات روی کل مطالبات این ماه اعمال می‌شود.',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText:
                      requiresNote ? 'دلیل برگشت' : 'توضیحات',
                      hintText: requiresNote
                          ? 'دلیل برگشت را وارد کنید.'
                          : 'در صورت نیاز توضیح وارد کنید.',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                final note = controller.text.trim();

                if (requiresNote && note.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'دلیل برگشت را وارد کنید.',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(note);
              },
              child: Text(
                _workflowActionTitle(action),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  String _workflowDialogTitle(String action) {
    switch (action) {
      case 'submit_to_company_admin':
        return 'ارسال ماه مطالبات برای مدیرعامل';

      case 'approve_and_send_to_consultant':
        return 'تأیید ماه مطالبات و ارسال برای مشاور';

      case 'return_to_accountant':
        return 'برگشت ماه مطالبات برای اصلاح';

      case 'approve_by_consultant':
        return 'تأیید نهایی ماه مطالبات';

      case 'return_by_consultant':
        return 'برگشت ماه مطالبات برای اصلاح';

      case 'close':
        return 'بستن ماه مطالبات';

      case 'reopen':
        return 'بازگشایی ماه مطالبات';

      default:
        return 'عملیات ماه مطالبات';
    }
  }

  String _workflowActionTitle(String action) {
    switch (action) {
      case 'submit_to_company_admin':
        return 'ارسال';

      case 'approve_and_send_to_consultant':
        return 'تأیید و ارسال';

      case 'return_to_accountant':
      case 'return_by_consultant':
        return 'برگشت';

      case 'approve_by_consultant':
        return 'تأیید نهایی';

      case 'close':
        return 'بستن';

      case 'reopen':
        return 'بازگشایی';

      default:
        return 'تأیید';
    }
  }

  String _workflowSuccessMessage(String action) {
    switch (action) {
      case 'submit_to_company_admin':
        return 'کل ماه مطالبات برای مدیرعامل ارسال شد.';

      case 'approve_and_send_to_consultant':
        return 'ماه مطالبات تأیید و برای مشاور ارسال شد.';

      case 'return_to_accountant':
        return 'ماه مطالبات برای اصلاح به حسابدار برگشت داده شد.';

      case 'approve_by_consultant':
        return 'ماه مطالبات با موفقیت تأیید نهایی شد.';

      case 'return_by_consultant':
        return 'ماه مطالبات برای اصلاح به حسابدار برگشت داده شد.';

      case 'close':
        return 'ماه مطالبات بسته شد.';

      case 'reopen':
        return 'ماه مطالبات بازگشایی شد.';

      default:
        return 'عملیات با موفقیت انجام شد.';
    }
  }

  // ============================================================
  // RECEIVABLE CRUD
  // ============================================================

  Future<void> _openReceivableDialog({
    AccountantIncomeReceivable? item,
  }) async {
    final result = await showDialog<_ReceivableFormResult>(
      context: context,
      builder: (context) {
        return _ReceivableDialog(item: item);
      },
    );

    if (result == null) {
      return;
    }

    try {
      if (item == null) {
        await AccountantIncomeReceivablesRepository.create(
          periodId: widget.periodId,
          title: result.title,
          amount: result.amount,
          receivedDocumentsAmount:
          result.receivedDocumentsAmount,
          description: result.description,
        );
      } else {
        await AccountantIncomeReceivablesRepository.update(
          id: item.id,
          periodId: widget.periodId,
          title: result.title,
          amount: result.amount,
          receivedDocumentsAmount:
          result.receivedDocumentsAmount,
          description: result.description,
        );
      }

      ref.invalidate(
        accountantIncomeReceivablesProvider(widget.periodId),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        item == null
            ? 'مطالبه با موفقیت ثبت شد.'
            : 'مطالبه با موفقیت ویرایش شد.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  Future<void> _deleteReceivable(
      AccountantIncomeReceivable item,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف مطالبه',
            textDirection: TextDirection.rtl,
          ),
          content: Text(
            'آیا از حذف «${item.title}» مطمئن هستید؟',
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AccountantIncomeReceivablesRepository.delete(
        id: item.id,
        periodId: widget.periodId,
      );

      ref.invalidate(
        accountantIncomeReceivablesProvider(widget.periodId),
      );

      if (!mounted) {
        return;
      }

      _showMessage('مطالبه حذف شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
  }
}

// ============================================================
// PAGE CONTENT
// ============================================================

class _PageContent extends StatelessWidget {
  final AccountantIncomeReceivablesData data;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAdd;
  final void Function(AccountantIncomeReceivable item)? onEdit;
  final void Function(AccountantIncomeReceivable item)? onDelete;
  final void Function(String action) onWorkflow;

  const _PageContent({
    required this.data,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onWorkflow,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                isMobile ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    period: data.period,
                    onAdd: onAdd,
                    onWorkflow: onWorkflow,
                  ),
                  const SizedBox(height: 20),
                  _SummaryGrid(
                    data: data,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 24),
                  if (data.receivables.isEmpty)
                    _EmptyState(
                      canAdd: onAdd != null,
                      onAdd: onAdd,
                    )
                  else if (isMobile)
                    _MobileList(
                      items: data.receivables,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    )
                  else
                    _DesktopTable(
                      items: data.receivables,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  final AccountantIncomeReceivablePeriod period;
  final VoidCallback? onAdd;
  final void Function(String action) onWorkflow;

  const _Header({
    required this.period,
    required this.onAdd,
    required this.onWorkflow,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForStatus(period.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment:
            WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'مطالبات',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${period.displayTitle} • سال ${period.year}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _StatusChip(
                    title: period.statusTitle,
                    status: period.status,
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('ثبت مطالبه'),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            Text(
              'گردش تأیید ماه',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions.map((action) {
                return _PeriodWorkflowButton(
                  action: action,
                  onPressed: () =>
                      onWorkflow(action),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _actionsForStatus(String status) {
    switch (status) {
      case 'open':
        return ['submit_to_company_admin'];

      case 'submitted_to_company_admin':
        return [
          'approve_and_send_to_consultant',
          'return_to_accountant',
        ];

      case 'submitted_to_consultant':
        return [
          'approve_by_consultant',
          'return_by_consultant',
        ];

      case 'approved':
        return ['close'];

      case 'closed':
        return ['reopen'];

      default:
        return [];
    }
  }
}

class _PeriodWorkflowButton extends StatelessWidget {
  final String action;
  final VoidCallback onPressed;

  const _PeriodWorkflowButton({
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary =
        action == 'submit_to_company_admin' ||
            action == 'approve_and_send_to_consultant' ||
            action == 'approve_by_consultant';

    final label = _workflowActionTitle(action);
    final icon = _workflowIcon(action);

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

// ============================================================
// SUMMARY
// ============================================================

class _SummaryGrid extends StatelessWidget {
  final AccountantIncomeReceivablesData data;
  final bool isMobile;

  const _SummaryGrid({
    required this.data,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        title: 'تعداد مطالبات',
        value: _formatInteger(data.totalCount),
        icon: Icons.receipt_long_outlined,
      ),
      _SummaryCard(
        title: 'کل مطالبات',
        value: _formatMoney(data.totalAmount),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryCard(
        title: 'اسناد دریافتی',
        value: _formatMoney(
          data.totalReceivedDocuments,
        ),
        icon: Icons.description_outlined,
      ),
      _SummaryCard(
        title: 'مانده مطالبات',
        value: _formatMoney(data.totalRemaining),
        icon: Icons.pending_actions_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
            padding:
            const EdgeInsets.only(bottom: 12),
            child: card,
          ),
        )
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.8,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
            ),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
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

// ============================================================
// DESKTOP TABLE
// ============================================================

class _DesktopTable extends StatelessWidget {
  final List<AccountantIncomeReceivable> items;
  final void Function(
      AccountantIncomeReceivable item,
      )? onEdit;
  final void Function(
      AccountantIncomeReceivable item,
      )? onDelete;

  const _DesktopTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
          Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 56,
          columns: const [
            DataColumn(
              label: Text('عنوان مطالبه'),
            ),
            DataColumn(
              label: Text('مبلغ مطالبه'),
            ),
            DataColumn(
              label: Text('اسناد دریافتی'),
            ),
            DataColumn(
              label: Text('مانده'),
            ),
            DataColumn(
              label: Text('وضعیت وصول'),
            ),
            DataColumn(
              label: Text('عملیات'),
            ),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 240,
                    child: Text(
                      item.title,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(_formatMoney(item.amount)),
                ),
                DataCell(
                  Text(
                    _formatMoney(
                      item.receivedDocumentsAmount,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatMoney(
                      item.remainingAmount,
                    ),
                  ),
                ),
                DataCell(
                  _ReceivableCollectionChip(
                    item: item,
                  ),
                ),
                DataCell(
                  _ReceivableActions(
                    item: item,
                    onEdit: onEdit,
                    onDelete: onDelete,
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

// ============================================================
// MOBILE LIST
// ============================================================

class _MobileList extends StatelessWidget {
  final List<AccountantIncomeReceivable> items;
  final void Function(
      AccountantIncomeReceivable item,
      )? onEdit;
  final void Function(
      AccountantIncomeReceivable item,
      )? onDelete;

  const _MobileList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding:
          const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                    _ReceivableCollectionChip(
                      item: item,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MobileValue(
                  title: 'مبلغ مطالبه',
                  value:
                  _formatMoney(item.amount),
                ),
                _MobileValue(
                  title: 'اسناد دریافتی',
                  value: _formatMoney(
                    item.receivedDocumentsAmount,
                  ),
                ),
                _MobileValue(
                  title: 'مانده',
                  value: _formatMoney(
                    item.remainingAmount,
                  ),
                ),
                if (item.description != null &&
                    item.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.description!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
                const SizedBox(height: 14),
                _ReceivableActions(
                  item: item,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  expanded: true,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MobileValue extends StatelessWidget {
  final String title;
  final String value;

  const _MobileValue({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECEIVABLE ACTIONS
// ============================================================

class _ReceivableActions extends StatelessWidget {
  final AccountantIncomeReceivable item;
  final void Function(
      AccountantIncomeReceivable item,
      )? onEdit;
  final void Function(
      AccountantIncomeReceivable item,
      )? onDelete;
  final bool expanded;

  const _ReceivableActions({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit == null
                  ? null
                  : () => onEdit!(item),
              icon:
              const Icon(Icons.edit_outlined),
              label: const Text('ویرایش'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete == null
                  ? null
                  : () => onDelete!(item),
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text('حذف'),
            ),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'عملیات',
      onSelected: (action) {
        if (action == 'edit') {
          onEdit?.call(item);
        } else if (action == 'delete') {
          onDelete?.call(item);
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'edit',
            child: Text('ویرایش'),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text('حذف'),
          ),
        ];
      },
      icon: const Icon(Icons.more_vert),
    );
  }
}

// ============================================================
// FORM DIALOG
// ============================================================

class _ReceivableDialog extends StatefulWidget {
  final AccountantIncomeReceivable? item;

  const _ReceivableDialog({
    required this.item,
  });

  @override
  State<_ReceivableDialog> createState() =>
      _ReceivableDialogState();
}

class _ReceivableDialogState
    extends State<_ReceivableDialog> {
  late final TextEditingController
  _titleController;
  late final TextEditingController
  _amountController;
  late final TextEditingController
  _receivedController;
  late final TextEditingController
  _descriptionController;

  final _formKey =
  GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
          text: widget.item?.title ?? '',
        );

    _amountController =
        TextEditingController(
          text: widget.item == null
              ? ''
              : _numberText(widget.item!.amount),
        );

    _receivedController =
        TextEditingController(
          text: widget.item == null
              ? '0'
              : _numberText(
            widget.item!.receivedDocumentsAmount,
          ),
        );

    _descriptionController =
        TextEditingController(
          text: widget.item?.description ?? '',
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _receivedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? 'ویرایش مطالبه'
            : 'ثبت مطالبه جدید',
        textDirection: TextDirection.rtl,
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller:
                    _titleController,
                    decoration:
                    const InputDecoration(
                      labelText: 'عنوان مطالبه',
                      hintText:
                      'مثلاً مطالبات فروش فروردین',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'عنوان مطالبه را وارد کنید.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller:
                    _amountController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                      labelText: 'مبلغ مطالبه',
                      suffixText: 'ریال',
                    ),
                    validator: (value) {
                      final amount =
                      _parseNumber(value);

                      if (amount <= 0) {
                        return 'مبلغ باید بیشتر از صفر باشد.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller:
                    _receivedController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                      labelText: 'اسناد دریافتی',
                      suffixText: 'ریال',
                    ),
                    validator: (value) {
                      final received =
                      _parseNumber(value);

                      if (received < 0) {
                        return 'مبلغ نمی‌تواند منفی باشد.';
                      }

                      final total =
                      _parseNumber(
                        _amountController.text,
                      );

                      if (received > total) {
                        return 'اسناد دریافتی بیشتر از مطالبه است.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller:
                    _descriptionController,
                    maxLines: 3,
                    decoration:
                    const InputDecoration(
                      labelText: 'توضیحات',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            isEdit
                ? 'ذخیره تغییرات'
                : 'ثبت مطالبه',
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
    _parseNumber(_amountController.text);

    final received =
    _parseNumber(_receivedController.text);

    Navigator.of(context).pop(
      _ReceivableFormResult(
        title: _titleController.text.trim(),
        amount: amount,
        receivedDocumentsAmount: received,
        description:
        _descriptionController.text
            .trim(),
      ),
    );
  }
}

class _ReceivableFormResult {
  final String title;
  final double amount;
  final double receivedDocumentsAmount;
  final String? description;

  const _ReceivableFormResult({
    required this.title,
    required this.amount,
    required this.receivedDocumentsAmount,
    required this.description,
  });
}

// ============================================================
// STATUS
// ============================================================

class _StatusChip extends StatelessWidget {
  final String title;
  final String status;

  const _StatusChip({
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    _statusColor(context, status);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius:
        BorderRadius.circular(999),
        border: Border.all(
          color:
          color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReceivableCollectionChip
    extends StatelessWidget {
  final AccountantIncomeReceivable item;

  const _ReceivableCollectionChip({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.isFullyReceived
        ? 'تسویه‌شده'
        : item.hasReceivedDocuments
        ? 'بخشی وصول شده'
        : 'وصول نشده';

    final color = item.isFullyReceived
        ? Colors.green
        : item.hasReceivedDocuments
        ? Colors.orange
        : Colors.red;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        color.withValues(alpha: 0.10),
        borderRadius:
        BorderRadius.circular(999),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyState extends StatelessWidget {
  final bool canAdd;
  final VoidCallback? onAdd;

  const _EmptyState({
    required this.canAdd,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(height: 14),
          Text(
            'هنوز مطالبه‌ای برای این ماه ثبت نشده است.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'مطالبات این ماه را از همین بخش ثبت کنید.',
            textAlign: TextAlign.center,
          ),
          if (canAdd) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label:
              const Text('ثبت اولین مطالبه'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView extends StatelessWidget {
  final Object error;
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
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 52,
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
              const SizedBox(height: 16),
              const Text(
                'خطا در دریافت مطالبات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                error
                    .toString()
                    .replaceFirst(
                  'Exception: ',
                  '',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon:
                const Icon(Icons.refresh),
                label:
                const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Color _statusColor(
    BuildContext context,
    String status,
    ) {
  switch (status) {
    case 'open':
      return Colors.blue;

    case 'submitted_to_company_admin':
      return Colors.orange;

    case 'submitted_to_consultant':
      return Colors.deepPurple;

    case 'approved':
      return Colors.green;

    case 'closed':
      return Colors.grey;

    default:
      return Theme.of(context)
          .colorScheme
          .primary;
  }
}

String _workflowActionTitle(String action) {
  switch (action) {
    case 'submit_to_company_admin':
      return 'ارسال برای مدیرعامل';

    case 'approve_and_send_to_consultant':
      return 'تأیید و ارسال برای مشاور';

    case 'return_to_accountant':
      return 'برگشت به حسابدار';

    case 'approve_by_consultant':
      return 'تأیید نهایی';

    case 'return_by_consultant':
      return 'برگشت برای اصلاح';

    case 'close':
      return 'بستن ماه';

    case 'reopen':
      return 'بازگشایی ماه';

    default:
      return 'عملیات';
  }
}

IconData _workflowIcon(String action) {
  switch (action) {
    case 'submit_to_company_admin':
      return Icons.send_outlined;

    case 'approve_and_send_to_consultant':
      return Icons.forward_to_inbox_outlined;

    case 'return_to_accountant':
    case 'return_by_consultant':
      return Icons.undo_outlined;

    case 'approve_by_consultant':
      return Icons.verified_outlined;

    case 'close':
      return Icons.lock_outline;

    case 'reopen':
      return Icons.lock_open_outlined;

    default:
      return Icons.more_horiz;
  }
}

String _formatMoney(double value) {
  final rounded = value.round();

  final text = rounded.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
  );

  return '$text ریال';
}

String _formatInteger(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
  );
}

String _numberText(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toString();
}

double _parseNumber(String? value) {
  if (value == null) {
    return 0;
  }

  var normalized = value
      .trim()
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll(' ', '');

  const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

  for (var i = 0; i < 10; i++) {
    normalized = normalized.replaceAll(
      persianDigits[i],
      i.toString(),
    );

    normalized = normalized.replaceAll(
      arabicDigits[i],
      i.toString(),
    );
  }

  return double.tryParse(normalized) ?? 0;
}