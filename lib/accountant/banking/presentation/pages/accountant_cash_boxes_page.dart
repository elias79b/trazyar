import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/banking/application/accountant_cash_boxes_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantCashBoxesPage extends ConsumerWidget {
  final String companyId;

  const AccountantCashBoxesPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantCashBoxesProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/cash-boxes',
      title: 'صندوق‌ها',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(accountantCashBoxesProvider(companyId));
              },
            );
          },
          data: (items) {
            return _CashBoxesContent(
              companyId: companyId,
              items: items,
              onRefresh: () {
                ref.invalidate(accountantCashBoxesProvider(companyId));
              },
            );
          },
        ),
      ),
    );
  }
}

class _CashBoxesContent extends StatelessWidget {
  final String companyId;
  final List<AccountantCashBox> items;
  final VoidCallback onRefresh;

  const _CashBoxesContent({
    required this.companyId,
    required this.items,
    required this.onRefresh,
  });

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CashBoxDialog(companyId: companyId),
    );

    if (result == true) {
      onRefresh();
    }
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
                  color: const Color(0xFFFFF4DF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: Color(0xFFC27A00),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'صندوق‌ها',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${items.length} صندوق ثبت شده',
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
                label: const Text('افزودن صندوق'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC27A00),
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
          if (items.isEmpty)
            _EmptyState(onAdd: () => _openCreateDialog(context))
          else
            _CashBoxesGrid(
              items: items,
              companyId: companyId,
              onChanged: onRefresh,
            ),
        ],
      ),
    );
  }
}

class _CashBoxesGrid extends StatelessWidget {
  final List<AccountantCashBox> items;
  final String companyId;
  final VoidCallback onChanged;

  const _CashBoxesGrid({
    required this.items,
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
        childAspectRatio: 1.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _CashBoxCard(
          item: items[index],
          companyId: companyId,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _CashBoxCard extends StatelessWidget {
  final AccountantCashBox item;
  final String companyId;
  final VoidCallback onChanged;

  const _CashBoxCard({
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Color(0xFFC27A00),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.boxName.isEmpty ? 'صندوق بدون نام' : item.boxName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'صندوق نقدی شرکت',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                      (_) => _CashBoxDialog(companyId: companyId, item: item),
                );

                if (result == true) {
                  onChanged();
                }
              }

              if (value == 'delete') {
                final confirmed = await _confirmDelete(context);

                if (!confirmed) return;

                try {
                  await AccountantCashBoxesRepository.delete(item.id);

                  onChanged();
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حذف صندوق انجام نشد: $e')),
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
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف صندوق', textDirection: TextDirection.rtl),
          content: const Text(
            'آیا از حذف این صندوق مطمئن هستید؟',
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

class _CashBoxDialog extends StatefulWidget {
  final String companyId;
  final AccountantCashBox? item;

  const _CashBoxDialog({required this.companyId, this.item});

  @override
  State<_CashBoxDialog> createState() => _CashBoxDialogState();
}

class _CashBoxDialogState extends State<_CashBoxDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  bool _loading = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.item?.boxName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        await AccountantCashBoxesRepository.update(
          id: widget.item!.id,
          boxName: _nameController.text,
        );
      } else {
        await AccountantCashBoxesRepository.create(
          companyId: widget.companyId,
          boxName: _nameController.text,
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
            isEdit ? 'ویرایش صندوق انجام نشد: $e' : 'ثبت صندوق انجام نشد: $e',
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
        title: Text(isEdit ? 'ویرایش صندوق' : 'افزودن صندوق'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'نام صندوق',
                hintText: 'مثلاً صندوق اصلی',
                prefixIcon: Icon(Icons.point_of_sale_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'نام صندوق را وارد کنید';
                }

                return null;
              },
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
              backgroundColor: const Color(0xFFC27A00),
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
                    : Text(isEdit ? 'ذخیره تغییرات' : 'ثبت صندوق'),
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFF4DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_outlined,
              size: 38,
              color: Color(0xFFC27A00),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'هنوز صندوقی ثبت نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، اولین صندوق شرکت را ثبت کنید.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن صندوق'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC27A00),
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
              'دریافت صندوق‌ها انجام نشد',
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
