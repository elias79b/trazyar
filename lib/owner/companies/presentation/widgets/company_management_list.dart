import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/companies/application/companies_provider.dart';

import '../../domain/models/company_model.dart';
import '../controllers/company_controller.dart';
import 'company_list_tile.dart';

class CompanyManagementList extends ConsumerWidget {
  const CompanyManagementList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    final loading = ref.watch(companyControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: companiesAsync.when(
        loading: () {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: CircularProgressIndicator(),
            ),
          );
        },
        error: (error, stackTrace) {
          return _ErrorState(
            error: error,
            onRetry: () {
              ref.invalidate(companiesProvider);
            },
          );
        },
        data: (companies) {
          if (companies.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: [
              for (int index = 0; index < companies.length; index++) ...[
                CompanyListTile(
                  company: companies[index],
                  onEdit: () {
                    _showEditDialog(context, ref, companies[index]);
                  },
                  onToggle:
                      loading
                          ? null
                          : () {
                            _toggleCompany(context, ref, companies[index]);
                          },
                  onDelete:
                      loading
                          ? null
                          : () {
                            _deleteCompany(context, ref, companies[index]);
                          },
                ),
                if (index != companies.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CompanyModel company,
  ) async {
    final nameController = TextEditingController(text: company.name);

    final emailController = TextEditingController(text: company.email ?? '');

    final phoneController = TextEditingController(text: company.phone ?? '');

    final websiteController = TextEditingController(
      text: company.website ?? '',
    );

    final addressController = TextEditingController(
      text: company.address ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('ویرایش شرکت'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'نام شرکت',
                            prefixIcon: Icon(Icons.business_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'نام شرکت را وارد کنید';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'ایمیل',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'شماره تماس',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: websiteController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'وب‌سایت',
                            prefixIcon: Icon(Icons.language),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'آدرس',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('انصراف'),
                ),

                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    await ref
                        .read(companyControllerProvider.notifier)
                        .updateCompany(
                          context: context,
                          companyId: company.id,
                          name: nameController.text.trim(),
                          email: _nullable(emailController.text),
                          phone: _nullable(phoneController.text),
                          website: _nullable(websiteController.text),
                          address: _nullable(addressController.text),
                        );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('ذخیره تغییرات'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      websiteController.dispose();
      addressController.dispose();
    }
  }

  Future<void> _toggleCompany(
    BuildContext context,
    WidgetRef ref,
    CompanyModel company,
  ) async {
    final nextStatus = !company.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            icon: Icon(
              nextStatus
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              color: nextStatus ? Colors.green : Colors.orange,
              size: 42,
            ),
            title: Text(nextStatus ? 'فعال کردن شرکت' : 'غیرفعال کردن شرکت'),
            content: Text(
              nextStatus
                  ? 'آیا می‌خواهید شرکت «${company.name}» فعال شود؟'
                  : 'آیا می‌خواهید شرکت «${company.name}» غیرفعال شود؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: nextStatus ? Colors.green : Colors.orange,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(nextStatus ? 'فعال کردن' : 'غیرفعال کردن'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await ref
        .read(companyControllerProvider.notifier)
        .toggleCompanyStatus(
          context: context,
          companyId: company.id,
          isActive: nextStatus,
        );
  }

  Future<void> _deleteCompany(
    BuildContext context,
    WidgetRef ref,
    CompanyModel company,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
              size: 48,
            ),
            title: const Text('حذف شرکت'),
            content: Text(
              'آیا از حذف شرکت «${company.name}» مطمئن هستید؟\n\n'
              'این عملیات قابل بازگشت نیست.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('حذف شرکت'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await ref
        .read(companyControllerProvider.notifier)
        .deleteCompany(context: context, companyId: company.id);
  }

  String? _nullable(String value) {
    final result = value.trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 14),
          Text(
            'هیچ شرکتی ثبت نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'اولین شرکت را از بخش ثبت شرکت ایجاد کنید.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 12),
          const Text(
            'خطا در دریافت شرکت‌ها',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }
}
