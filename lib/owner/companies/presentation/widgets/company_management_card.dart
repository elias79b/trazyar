import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/companies/application/companies_provider.dart';

import '../../domain/models/company_model.dart';
import '../controllers/company_controller.dart';

class CompanyManagementCard extends ConsumerStatefulWidget {
  const CompanyManagementCard({super.key});

  @override
  ConsumerState<CompanyManagementCard> createState() =>
      _CompanyManagementCardState();
}

class _CompanyManagementCardState
    extends ConsumerState<CompanyManagementCard> {
  final TextEditingController _searchController =
  TextEditingController();

  String _filter = 'all';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CompanyModel> _filterCompanies(
      List<CompanyModel> companies,
      ) {
    final search = _searchController.text.trim().toLowerCase();

    return companies.where((company) {
      final matchesSearch =
          search.isEmpty ||
              company.name.toLowerCase().contains(search) ||
              (company.email ?? '').toLowerCase().contains(search) ||
              (company.phone ?? '').contains(search);

      final matchesFilter =
          _filter == 'all' ||
              (_filter == 'active' && company.isActive) ||
              (_filter == 'inactive' && !company.isActive);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _editCompany(CompanyModel company) async {
    final nameController =
    TextEditingController(text: company.name);
    final emailController =
    TextEditingController(text: company.email ?? '');
    final phoneController =
    TextEditingController(text: company.phone ?? '');
    final websiteController =
    TextEditingController(text: company.website ?? '');
    final addressController =
    TextEditingController(text: company.address ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('ویرایش شرکت'),
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
                        decoration: const InputDecoration(
                          labelText: 'نام شرکت',
                          prefixIcon:
                          Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'نام شرکت الزامی است';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ایمیل',
                          prefixIcon:
                          Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType:
                        TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'شماره تماس',
                          prefixIcon:
                          Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: websiteController,
                        keyboardType:
                        TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'وب‌سایت',
                          prefixIcon:
                          Icon(Icons.language),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'آدرس',
                          prefixIcon:
                          Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('انصراف'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.pop(dialogContext);

                  ref
                      .read(
                    companyControllerProvider.notifier,
                  )
                      .updateCompany(
                    context: context,
                    companyId: company.id,
                    name: nameController.text.trim(),
                    email:
                    emailController.text.trim(),
                    phone:
                    phoneController.text.trim(),
                    website:
                    websiteController.text.trim(),
                    address:
                    addressController.text.trim(),
                    logo: company.logo,
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('ذخیره'),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    addressController.dispose();
  }

  Future<void> _toggleStatus(
      CompanyModel company,
      ) async {
    final action =
    company.isActive ? 'غیرفعال' : 'فعال';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('$action کردن شرکت'),
            content: Text(
              'آیا از $action کردن «${company.name}» مطمئن هستید؟',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await ref
        .read(companyControllerProvider.notifier)
        .toggleCompanyStatus(
      context: context,
      companyId: company.id,
      isActive: !company.isActive,
    );
  }

  Future<void> _deleteCompany(
      CompanyModel company,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 42,
            ),
            title: const Text('حذف شرکت'),
            content: Text(
              'آیا از حذف شرکت «${company.name}» مطمئن هستید؟\n\n'
                  'این عملیات قابل بازگشت نیست.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: const Text('حذف شرکت'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await ref
        .read(companyControllerProvider.notifier)
        .deleteCompany(
      context: context,
      companyId: company.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final loading = ref.watch(companyControllerProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.business_center,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'مدیریت شرکت‌ها',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'بروزرسانی',
                  onPressed: loading
                      ? null
                      : () {
                    ref.invalidate(
                      companiesProvider,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      _buildFilter(),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildSearchField(),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 190,
                      child: _buildFilter(),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            companiesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(50),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildError(error),
              data: (companies) {
                final filtered =
                _filterCompanies(companies);

                return Column(
                  children: [
                    _buildStats(companies),
                    const SizedBox(height: 20),
                    if (filtered.isEmpty)
                      _buildEmpty()
                    else
                      _buildCompanyList(filtered),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'جستجوی شرکت...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController.clear();
          },
          icon: const Icon(Icons.clear),
        )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildFilter() {
    return DropdownButtonFormField<String>(
      value: _filter,
      decoration: const InputDecoration(
        labelText: 'وضعیت',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text('همه شرکت‌ها'),
        ),
        DropdownMenuItem(
          value: 'active',
          child: Text('فعال'),
        ),
        DropdownMenuItem(
          value: 'inactive',
          child: Text('غیرفعال'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _filter = value;
        });
      },
    );
  }

  Widget _buildStats(
      List<CompanyModel> companies,
      ) {
    final active =
        companies.where((e) => e.isActive).length;

    final inactive =
        companies.length - active;

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            title: 'کل شرکت‌ها',
            value: companies.length.toString(),
            icon: Icons.business,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            title: 'فعال',
            value: active.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            title: 'غیرفعال',
            value: inactive.toString(),
            icon: Icons.pause_circle,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyList(
      List<CompanyModel> companies,
      ) {
    return ListView.separated(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: companies.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _CompanyTile(
          company: companies[index],
          onEdit: () =>
              _editCompany(companies[index]),
          onToggle: () =>
              _toggleStatus(companies[index]),
          onDelete: () =>
              _deleteCompany(companies[index]),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 14),
          Text(
            'شرکتی پیدا نشد',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'خطا در دریافت شرکت‌ها\n\n$error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(companiesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
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

class _CompanyTile extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CompanyTile({
    required this.company,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    company.isActive ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(14),
              child: company.logo != null &&
                  company.logo!.isNotEmpty
                  ? Image.network(
                company.logo!,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return Icon(
                    Icons.business,
                    color: color,
                  );
                },
              )
                  : Icon(
                Icons.business,
                color: color,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  company.email?.isNotEmpty == true
                      ? company.email!
                      : company.phone ?? 'بدون اطلاعات تماس',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  overflow:
                  TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              company.isActive
                  ? 'فعال'
                  : 'غیرفعال',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 8),

          PopupMenuButton<String>(
            tooltip: 'عملیات',
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'toggle':
                  onToggle();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit),
                  title: Text('ویرایش'),
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    company.isActive
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  title: Text(
                    company.isActive
                        ? 'غیرفعال کردن'
                        : 'فعال کردن',
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: Text(
                    'حذف شرکت',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}