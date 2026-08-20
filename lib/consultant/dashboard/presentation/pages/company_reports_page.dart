import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';

class CompanyReportsPage extends StatelessWidget {
  const CompanyReportsPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/reports',

      title: 'گزارش‌های شرکت',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'گزارش‌های مدیریتی',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'بررسی گزارش‌های مالی و عملکرد شرکت',

              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 24),

            _ReportCard(
              title: 'گزارش عملکرد ماهانه',

              date: '1405/02/10',

              type: 'عملکرد',

              status: 'تکمیل شده',
            ),

            _ReportCard(
              title: 'گزارش تحلیل هزینه‌ها',

              date: '1405/02/05',

              type: 'مالی',

              status: 'در انتظار بررسی',
            ),

            _ReportCard(
              title: 'گزارش سود و زیان',

              date: '1405/01/30',

              type: 'حسابداری',

              status: 'نیازمند اصلاح',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,

    required this.date,

    required this.type,

    required this.status,
  });

  final String title;

  final String date;

  final String type;

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 52,

            height: 52,

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.1),

              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.description_rounded,

              color: Color(0xFF1B4332),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.w900,

                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$type - $date',

                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(.12),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status,

              style: const TextStyle(
                fontSize: 11,

                fontWeight: FontWeight.bold,

                color: Color(0xFF2D6A4F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
