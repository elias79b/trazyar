import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/companies/application/companies_provider.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';

import '../controllers/company_controller.dart';
import '../widgets/company_form_dialog.dart';
import '../widgets/company_management_list.dart';

class CompanyManagementPage extends ConsumerWidget {
  const CompanyManagementPage({super.key});

  Future<void> _createCompany(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CreateCompanyInput>(
      context: context,
      builder: (_) => const CompanyFormDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await ref
        .read(companyControllerProvider.notifier)
        .createCompany(
          context: context,
          name: result.name,
          legalName: result.legalName,
          nationalId: result.nationalId,
          economicCode: result.economicCode,
          phone: result.phone,
          email: result.email,
          website: result.website,
          address: result.address,
          city: result.city,
          province: result.province,
          postalCode: result.postalCode,
          isActive: result.isActive,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(companyControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: OwnerScaffold(
        currentRoute: '/owner/companies',
        title: 'مدیریت شرکت‌ها',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompanyManagementHeader(
              loading: loading,
              onCreate: () => _createCompany(context, ref),
              onRefresh: () => ref.invalidate(companiesProvider),
            ),
            const SizedBox(height: 20),
            const Text(
              'لیست شرکت‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const CompanyManagementList(),
          ],
        ),
      ),
    );
  }
}

class _CompanyManagementHeader extends StatelessWidget {
  final bool loading;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _CompanyManagementHeader({
    required this.loading,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final createButton = FilledButton.icon(
      onPressed: loading ? null : onCreate,
      icon:
          loading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.add_business_outlined),
      label: Text(loading ? 'در حال ثبت...' : 'ثبت شرکت جدید'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مدیریت شرکت‌ها',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                'مدیریت و کنترل شرکت‌های مجموعه',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );

          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: createButton),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'به‌روزرسانی',
                      onPressed: loading ? null : onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              IconButton(
                tooltip: 'به‌روزرسانی',
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              createButton,
            ],
          );
        },
      ),
    );
  }
}
