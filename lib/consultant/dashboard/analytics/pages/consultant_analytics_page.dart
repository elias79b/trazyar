import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/consultant_scaffold.dart';


class ConsultantAnalyticsPage extends StatelessWidget {
  const ConsultantAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant/analytics',

      title: 'تحلیل عملکرد',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'تحلیل عملکرد مشاور',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'نمای کلی عملکرد شرکت‌های تحت مدیریت شما',

              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _SummarySection(),

            const SizedBox(height: 24),

            _PerformanceChart(),

            const SizedBox(height: 24),

            _CompanyRanking(),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,

        crossAxisSpacing: 16,

        mainAxisSpacing: 16,

        childAspectRatio: 1.8,
      ),

      children: const [
        _SummaryCard(
          title: 'شرکت‌های فعال',

          value: '۱۲',

          icon: Icons.business_rounded,
        ),

        _SummaryCard(
          title: 'گزارش‌های ثبت شده',

          value: '۴۵',

          icon: Icons.description_rounded,
        ),

        _SummaryCard(
          title: 'اقدامات باز',

          value: '۸',

          icon: Icons.task_alt_rounded,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,

    required this.value,

    required this.icon,
  });

  final String title;

  final String value;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: const Color(0xFF1B4332)),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),

          Text(
            title,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = [.4, .6, .5, .75, .8, .9];

    return Container(
      height: 280,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'روند عملکرد شرکت‌ها',

            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),

          const Spacer(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children:
                values.map((e) {
                  return Container(
                    width: 28,

                    height: 160 * e,

                    decoration: BoxDecoration(
                      color: const Color(0xFF40916C),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CompanyRanking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'رتبه‌بندی شرکت‌ها',

            style: TextStyle(fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 16),

          _Row('شرکت آریا', '۹۲٪'),

          _Row('شرکت پارس', '۸۵٪'),

          _Row('شرکت نوین', '۷۲٪'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.name, this.value);

  final String name;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        children: [
          Expanded(child: Text(name)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
