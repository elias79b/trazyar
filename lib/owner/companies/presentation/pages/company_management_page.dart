import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/company_controller.dart';
import '../widgets/company_form_dialog.dart';
import '../widgets/company_management_list.dart';

class CompanyManagementPage extends ConsumerWidget {
  const CompanyManagementPage({
    super.key,
  });

  Future<void> _createCompany(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final result = await showDialog<CreateCompanyInput>(
      context: context,
      builder: (_) => const CompanyFormDialog(),
    );

    if (result == null) {
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
      logo: result.logoUrl,
      isActive: result.isActive,
    );
  }

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final loading = ref.watch(
      companyControllerProvider,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مدیریت شرکت‌ها',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'مدیریت، ویرایش، فعال‌سازی و حذف شرکت‌ها',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: loading
                          ? null
                          : () => _createCompany(
                        context,
                        ref,
                      ),
                      icon: loading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.add_business,
                      ),
                      label: Text(
                        loading
                            ? 'در حال ثبت...'
                            : 'ثبت شرکت جدید',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Expanded(
                  child: SingleChildScrollView(
                    child: CompanyManagementList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}