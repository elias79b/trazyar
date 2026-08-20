import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/consultant_scaffold.dart';

class ConsultantReportsPage extends StatelessWidget {
  const ConsultantReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant/reports',

      title: 'گزارش‌ها',

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
              'مدیریت و بررسی گزارش‌های شرکت‌های تحت نظارت',

              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _FilterBox(),

            const SizedBox(height: 20),

            _ReportCard(
              company: 'شرکت بازرگانی آریا',

              title: 'گزارش عملکرد ماهانه',

              date: 'امروز',

              status: 'تکمیل شده',
            ),

            _ReportCard(
              company: 'شرکت تولیدی پارس',

              title: 'تحلیل سود و زیان',

              date: 'دیروز',

              status: 'در انتظار بررسی',
            ),

            _ReportCard(
              company: 'شرکت فناوری آینده',

              title: 'گزارش مالی فصل اول',

              date: '1405/02/01',

              status: 'نیازمند اصلاح',
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded),

          const SizedBox(width: 12),

          const Text(
            'فیلتر گزارش‌ها',

            style: TextStyle(fontWeight: FontWeight.w800),
          ),

          const Spacer(),

          FilledButton(onPressed: () {}, child: const Text('انتخاب')),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.company,

    required this.title,

    required this.date,

    required this.status,
  });

  final String company;

  final String title;

  final String date;

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
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.description_outlined,

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

                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 5),

                Text(
                  company,

                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                date,

                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 5),

              Text(
                status,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,

                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
