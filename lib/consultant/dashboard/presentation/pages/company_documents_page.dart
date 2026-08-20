import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';
import '../widgets/company_document_card.dart';

class CompanyDocumentsPage extends StatelessWidget {
  const CompanyDocumentsPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/documents',

      title: 'اسناد شرکت',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'اسناد و مدارک',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'بررسی و مدیریت مدارک مالی شرکت',

              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            const CompanyDocumentCard(
              title: 'صورت مالی اردیبهشت',

              type: 'گزارش مالی',

              date: '1405/02/15',

              status: 'تایید شده',
            ),

            const CompanyDocumentCard(
              title: 'فاکتورهای خرید',

              type: 'اسناد حسابداری',

              date: '1405/02/10',

              status: 'در انتظار',
            ),

            const CompanyDocumentCard(
              title: 'گزارش فروش',

              type: 'عملکرد',

              date: '1405/02/01',

              status: 'نیازمند اصلاح',
            ),
          ],
        ),
      ),
    );
  }
}
