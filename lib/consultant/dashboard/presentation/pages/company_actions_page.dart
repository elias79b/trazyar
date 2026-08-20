import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';

class CompanyActionsPage extends StatelessWidget {
  const CompanyActionsPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/actions',

      title: 'اقدامات شرکت',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'پیگیری اقدامات',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'مدیریت فعالیت‌ها و پیگیری موارد شرکت',

              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _ActionCard(
              title: 'بررسی افزایش هزینه‌ها',

              description: 'تحلیل علت افزایش هزینه در ماه جاری',

              priority: 'بالا',

              status: 'در حال بررسی',
            ),

            _ActionCard(
              title: 'بررسی گزارش فروش',

              description: 'مقایسه فروش فصل جاری با دوره قبل',

              priority: 'متوسط',

              status: 'جدید',
            ),

            _ActionCard(
              title: 'تطبیق اسناد مالی',

              description: 'بررسی اسناد ثبت شده حسابداری',

              priority: 'پایین',

              status: 'تکمیل شده',
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,

    required this.description,

    required this.priority,

    required this.status,
  });

  final String title;

  final String description;

  final String priority;

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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    fontSize: 15,

                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              _Badge(text: priority),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            description,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(Icons.timelapse_rounded, size: 18),

              const SizedBox(width: 6),

              Text(
                status,

                style: const TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFF1B4332).withOpacity(.12),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 11,

          color: Color(0xFF1B4332),

          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
