import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/consultant_scaffold.dart';
class ConsultantHistoryPage extends StatelessWidget {
  const ConsultantHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant/history',

      title: 'تاریخچه فعالیت‌ها',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'فعالیت‌های اخیر',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'سوابق فعالیت‌های انجام شده توسط مشاور',

              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _HistoryItem(
              icon: Icons.business_rounded,

              title: 'ورود به شرکت بازرگانی آریا',

              description: 'مشاور وارد داشبورد شرکت شد',

              time: '۱۰ دقیقه قبل',
            ),

            _HistoryItem(
              icon: Icons.description_rounded,

              title: 'ثبت گزارش مالی',

              description: 'گزارش عملکرد ماهانه ثبت شد',

              time: 'امروز',
            ),

            _HistoryItem(
              icon: Icons.note_alt_rounded,

              title: 'ثبت یادداشت شرکت',

              description: 'یادداشت جدید برای شرکت اضافه شد',

              time: 'دیروز',
            ),

            _HistoryItem(
              icon: Icons.task_alt_rounded,

              title: 'تغییر وضعیت اقدام',

              description: 'یک اقدام به حالت تکمیل شده تغییر کرد',

              time: '۲ روز قبل',
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.icon,

    required this.title,

    required this.description,

    required this.time,
  });

  final IconData icon;

  final String title;

  final String description;

  final String time;

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

              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(icon, color: const Color(0xFF1B4332)),
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
                  description,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          Text(
            time,

            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
