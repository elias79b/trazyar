
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';
import 'package:tarazyar/company_admin/payroll/application/company_admin_cost_centers_provider.dart';

class CompanyAdminCostCentersPage extends ConsumerStatefulWidget {
  const CompanyAdminCostCentersPage({super.key});

  @override
  ConsumerState<CompanyAdminCostCentersPage> createState() =>
      _CompanyAdminCostCentersPageState();
}

class _CompanyAdminCostCentersPageState
    extends ConsumerState<CompanyAdminCostCentersPage> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showForm({
    CompanyAdminCostCenter? center,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: center?.name ?? '',
    );
    final codeController = TextEditingController(
      text: center?.code ?? '',
    );
    final descriptionController = TextEditingController(
      text: center?.description ?? '',
    );

    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  center == null
                      ? 'افزودن مرکز هزینه'
                      : 'ویرایش مرکز هزینه',
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'نام مرکز هزینه *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'نام مرکز هزینه را وارد کنید.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'کد مرکز هزینه',
                              hintText: 'اختیاری',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'توضیحات',
                              hintText: 'اختیاری',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('انصراف'),
                  ),
                  FilledButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() => saving = true);

                      try {
                        final repository =
                        CompanyAdminCostCentersRepository(
                          Supabase.instance.client,
                        );

                        if (center == null) {
                          await repository.create(
                            name: nameController.text,
                            code: codeController.text,
                            description:
                            descriptionController.text,
                          );
                        } else {
                          await repository.update(
                            id: center.id,
                            name: nameController.text,
                            code: codeController.text,
                            description:
                            descriptionController.text,
                          );
                        }

                        ref.invalidate(
                          companyAdminCostCentersProvider,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              center == null
                                  ? 'مرکز هزینه ثبت شد.'
                                  : 'تغییرات ذخیره شد.',
                            ),
                          ),
                        );
                      } catch (error) {
                        setDialogState(() => saving = false);

                        if (!dialogContext.mounted) return;

                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'ذخیره اطلاعات ناموفق بود: $error',
                            ),
                          ),
                        );
                      }
                    },
                    icon: saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      saving ? 'در حال ذخیره...' : 'ذخیره',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      codeController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _toggleStatus(
      CompanyAdminCostCenter center,
      ) async {
    final newStatus = !center.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            newStatus
                ? 'فعال‌سازی مرکز هزینه'
                : 'غیرفعال‌سازی مرکز هزینه',
          ),
          content: Text(
            newStatus
                ? 'مرکز «${center.name}» فعال شود؟'
                : 'مرکز «${center.name}» غیرفعال شود؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأیید'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repository = CompanyAdminCostCentersRepository(
        Supabase.instance.client,
      );

      await repository.updateActiveStatus(
        id: center.id,
        isActive: newStatus,
      );

      ref.invalidate(companyAdminCostCentersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'مرکز هزینه فعال شد.'
                : 'مرکز هزینه غیرفعال شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تغییر وضعیت ناموفق بود: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(companyAdminCostCentersProvider);

    return CompanyAdminScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراکز هزینه'),
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: () {
                ref.invalidate(companyAdminCostCentersProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: result.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'دریافت مراکز هزینه ناموفق بود.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(companyAdminCostCentersProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _buildContent(context, data),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showForm(),
          icon: const Icon(Icons.add),
          label: const Text('مرکز هزینه جدید'),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      CompanyAdminCostCentersData data,
      ) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = data.centers.where((center) {
      final matchesQuery = query.isEmpty ||
          center.name.toLowerCase().contains(query) ||
          (center.code ?? '').toLowerCase().contains(query) ||
          (center.description ?? '').toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && center.isActive) ||
          (_statusFilter == 'inactive' && !center.isActive);

      return matchesQuery && matchesStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(companyAdminCostCentersProvider);
        await ref.read(companyAdminCostCentersProvider.future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isWide ? 24 : 16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'کل مراکز',
                    count: data.totalCount,
                    icon: Icons.account_tree_outlined,
                  ),
                  _SummaryCard(
                    title: 'فعال',
                    count: data.activeCount,
                    icon: Icons.check_circle_outline,
                  ),
                  _SummaryCard(
                    title: 'غیرفعال',
                    count: data.inactiveCount,
                    icon: Icons.pause_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'جست‌وجو در مراکز هزینه',
                  hintText: 'نام، کد یا توضیحات',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'فیلتر وضعیت',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('همه مراکز'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('فقط فعال‌ها'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('فقط غیرفعال‌ها'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _statusFilter = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'فهرست مراکز هزینه (${filtered.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('افزودن'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text('مرکزی مطابق جست‌وجو پیدا نشد.'),
                    ],
                  ),
                )
              else
                ...filtered.map(
                      (center) => _CostCenterCard(
                    center: center,
                    onEdit: () => _showForm(center: center),
                    onToggleStatus: () => _toggleStatus(center),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CostCenterCard extends StatelessWidget {
  final CompanyAdminCostCenter center;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _CostCenterCard({
    required this.center,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                center.isActive
                    ? Icons.account_tree_outlined
                    : Icons.pause_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'کد: ${center.code?.isNotEmpty == true ? center.code : 'تعریف نشده'}',
                  ),
                  if (center.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(center.description!),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Chip(
                      avatar: Icon(
                        center.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        center.isActive ? 'فعال' : 'غیرفعال',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'عملیات',
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'toggle') {
                  onToggleStatus();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('ویرایش'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      center.isActive
                          ? Icons.pause_circle_outline
                          : Icons.check_circle_outline,
                    ),
                    title: Text(
                      center.isActive ? 'غیرفعال‌سازی' : 'فعال‌سازی',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 12),
              Text(title),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
