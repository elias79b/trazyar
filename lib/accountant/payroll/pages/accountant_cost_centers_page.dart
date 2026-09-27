import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/payroll/application/accountant_cost_centers_provider.dart';

class AccountantCostCentersPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantCostCentersPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<AccountantCostCentersPage> createState() =>
      _AccountantCostCentersPageState();
}

class _AccountantCostCentersPageState
    extends ConsumerState<AccountantCostCentersPage> {
  String _searchQuery = '';
  bool _showInactive = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantCostCentersProvider(widget.companyId),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/payroll/cost-centers',
      title: 'مراکز هزینه',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(
                accountantCostCentersProvider(widget.companyId),
              );
            },
          ),
          data: (centers) {
            final filtered = centers.where((center) {
              if (!_showInactive && !center.isActive) {
                return false;
              }

              final query = _searchQuery.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              return center.name.toLowerCase().contains(query) ||
                  (center.code?.toLowerCase().contains(query) ?? false) ||
                  (center.description?.toLowerCase().contains(query) ??
                      false);
            }).toList();

            final activeCount =
                centers.where((item) => item.isActive).length;

            final inactiveCount =
                centers.where((item) => !item.isActive).length;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  accountantCostCentersProvider(widget.companyId),
                );

                await ref.read(
                  accountantCostCentersProvider(widget.companyId).future,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1100;
                  final isTablet = constraints.maxWidth >= 700;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      isDesktop
                          ? 28
                          : isTablet
                          ? 20
                          : 14,
                    ),
                    children: [
                      _Header(
                        totalCount: centers.length,
                        activeCount: activeCount,
                        inactiveCount: inactiveCount,
                        onAdd: () => _openCenterDialog(),
                      ),
                      const SizedBox(height: 20),
                      _FilterBar(
                        searchQuery: _searchQuery,
                        showInactive: _showInactive,
                        onSearchChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onShowInactiveChanged: (value) {
                          setState(() {
                            _showInactive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        _EmptyView(
                          hasFilter: _searchQuery.trim().isNotEmpty ||
                              !_showInactive,
                          onAdd: () => _openCenterDialog(),
                        )
                      else if (isDesktop)
                        _DesktopTable(
                          centers: filtered,
                          onEdit: _openCenterDialog,
                          onToggle: _toggleActive,
                          onDelete: _deleteCenter,
                        )
                      else
                        _MobileList(
                          centers: filtered,
                          onEdit: _openCenterDialog,
                          onToggle: _toggleActive,
                          onDelete: _deleteCenter,
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCenterDialog([
    AccountantCostCenter? center,
  ]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CostCenterDialog(
          companyId: widget.companyId,
          center: center,
        );
      },
    );

    if (result == true && mounted) {
      ref.invalidate(
        accountantCostCentersProvider(widget.companyId),
      );
    }
  }

  Future<void> _toggleActive(
      AccountantCostCenter center,
      ) async {
    try {
      await AccountantCostCentersRepository.toggleActive(
        id: center.id,
        isActive: !center.isActive,
      );

      ref.invalidate(
        accountantCostCentersProvider(widget.companyId),
      );

      if (!mounted) return;

      _showMessage(
        center.isActive
            ? 'مرکز هزینه غیرفعال شد.'
            : 'مرکز هزینه فعال شد.',
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _deleteCenter(
      AccountantCostCenter center,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف مرکز هزینه',
          ),
          content: Text(
            'آیا از حذف «${center.name}» مطمئن هستید؟\n\n'
                'اگر این مرکز هزینه به قرارداد یا اطلاعات حقوق متصل باشد، '
                'ممکن است حذف توسط پایگاه داده رد شود.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await AccountantCostCentersRepository.delete(
        id: center.id,
      );

      ref.invalidate(
        accountantCostCentersProvider(widget.companyId),
      );

      if (!mounted) return;

      _showMessage('مرکز هزینه حذف شد.');
    } catch (error) {
      if (!mounted) return;
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
          backgroundColor: Colors.red.shade700,
          content: Text(
            'خطا: $error',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final VoidCallback onAdd;

  const _Header({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(.10),
                  ),
                  child: Icon(
                    Icons.account_tree_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مراکز هزینه',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مدیریت مراکز هزینه و اتصال آن‌ها به قراردادهای پرسنلی',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('مرکز هزینه جدید'),
                  ),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('مرکز هزینه جدید'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatCard(
                  title: 'کل مراکز',
                  value: totalCount.toString(),
                  icon: Icons.account_tree_outlined,
                ),
                _StatCard(
                  title: 'فعال',
                  value: activeCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
                _StatCard(
                  title: 'غیرفعال',
                  value: inactiveCount.toString(),
                  icon: Icons.pause_circle_outline,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.7),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  final String searchQuery;
  final bool showInactive;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onShowInactiveChanged;

  const _FilterBar({
    required this.searchQuery,
    required this.showInactive,
    required this.onSearchChanged,
    required this.onShowInactiveChanged,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.searchQuery,
    );
  }

  @override
  void didUpdateWidget(covariant _FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(
          offset: widget.searchQuery.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.7),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          if (compact) {
            return Column(
              children: [
                TextField(
                  controller: _controller,
                  onChanged: widget.onSearchChanged,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جستجو بر اساس نام، کد یا توضیحات...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نمایش مراکز غیرفعال'),
                    value: widget.showInactive,
                    onChanged: widget.onShowInactiveChanged,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onSearchChanged,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'جستجو بر اساس نام، کد یا توضیحات...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Switch.adaptive(
                value: widget.showInactive,
                onChanged: widget.onShowInactiveChanged,
              ),
              const Text('نمایش غیرفعال‌ها'),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<AccountantCostCenter> centers;
  final ValueChanged<AccountantCostCenter> onEdit;
  final ValueChanged<AccountantCostCenter> onToggle;
  final ValueChanged<AccountantCostCenter> onDelete;

  const _DesktopTable({
    required this.centers,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.7),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            headingRowHeight: 54,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 82,
            columns: const [
              DataColumn(label: Text('نام مرکز')),
              DataColumn(label: Text('کد')),
              DataColumn(label: Text('توضیحات')),
              DataColumn(label: Text('وضعیت')),
              DataColumn(label: Text('عملیات')),
            ],
            rows: centers.map((center) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      center.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      center.code?.isNotEmpty == true
                          ? center.code!
                          : '—',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        center.description?.isNotEmpty == true
                            ? center.description!
                            : '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    _StatusChip(isActive: center.isActive),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'ویرایش',
                          onPressed: () => onEdit(center),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: center.isActive
                              ? 'غیرفعال کردن'
                              : 'فعال کردن',
                          onPressed: () => onToggle(center),
                          icon: Icon(
                            center.isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => onDelete(center),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
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
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<AccountantCostCenter> centers;
  final ValueChanged<AccountantCostCenter> onEdit;
  final ValueChanged<AccountantCostCenter> onToggle;
  final ValueChanged<AccountantCostCenter> onDelete;

  const _MobileList({
    required this.centers,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: centers.map((center) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withOpacity(.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(.08),
                      ),
                      child: Icon(
                        Icons.account_tree_outlined,
                        color:
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (center.code?.isNotEmpty == true)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 3),
                              child: Text(
                                'کد: ${center.code}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(
                      isActive: center.isActive,
                    ),
                  ],
                ),
                if (center.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    center.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onEdit(center),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('ویرایش'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onToggle(center),
                        icon: Icon(
                          center.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        label: Text(
                          center.isActive ? 'غیرفعال' : 'فعال',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: () => onDelete(center),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive
            ? Colors.green.withOpacity(.10)
            : Colors.grey.withOpacity(.12),
      ),
      child: Text(
        isActive ? 'فعال' : 'غیرفعال',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive
              ? Colors.green.shade700
              : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _CostCenterDialog extends StatefulWidget {
  final String companyId;
  final AccountantCostCenter? center;

  const _CostCenterDialog({
    required this.companyId,
    this.center,
  });

  @override
  State<_CostCenterDialog> createState() => _CostCenterDialogState();
}

class _CostCenterDialogState extends State<_CostCenterDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.center?.name ?? '',
    );

    _codeController = TextEditingController(
      text: widget.center?.code ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.center?.description ?? '',
    );

    _isActive = widget.center?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.center != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          editing
              ? 'ویرایش مرکز هزینه'
              : 'مرکز هزینه جدید',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'نام مرکز هزینه *',
                    hintText: 'مثلاً واحد فروش',
                    prefixIcon: const Icon(
                      Icons.account_tree_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'کد مرکز هزینه',
                    hintText: 'مثلاً CC-001',
                    prefixIcon: const Icon(
                      Icons.tag_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  textDirection: TextDirection.rtl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'توضیحات',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 55),
                      child: Icon(Icons.notes_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (editing) ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('مرکز هزینه فعال باشد'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.save_outlined),
            label: Text(
              editing
                  ? 'ذخیره تغییرات'
                  : 'ایجاد مرکز هزینه',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('نام مرکز هزینه را وارد کنید.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (widget.center == null) {
        await AccountantCostCentersRepository.create(
          companyId: widget.companyId,
          name: name,
          code: _codeController.text,
          description: _descriptionController.text,
        );
      } else {
        await AccountantCostCentersRepository.update(
          id: widget.center!.id,
          name: name,
          code: _codeController.text,
          description: _descriptionController.text,
          isActive: _isActive,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          'خطا: $error',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAdd;

  const _EmptyView({
    required this.hasFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.7),
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFilter
                ? Icons.search_off_outlined
                : Icons.account_tree_outlined,
            size: 54,
            color: Colors.grey,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilter
                ? 'مرکزی مطابق فیلتر شما پیدا نشد.'
                : 'هنوز مرکز هزینه‌ای ثبت نشده است.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 8),
            const Text(
              'برای شروع اولین مرکز هزینه را ایجاد کنید.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ایجاد مرکز هزینه'),
            ),
          ],
        ],
      ),
    );
  }
}

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت مراکز هزینه',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}