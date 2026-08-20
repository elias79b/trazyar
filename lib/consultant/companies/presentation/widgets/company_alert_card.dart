import 'package:flutter/material.dart';

class CompanyAlertCard extends StatelessWidget {
  const CompanyAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),

              SizedBox(width: 10),

              Text(
                'هشدارهای شرکت',

                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _AlertItem(
            title: 'تایید حقوق تیر ماه متوقف شده',

            subtitle: '۵ روز در انتظار تایید مدیر',

            type: AlertType.danger,
          ),

          const SizedBox(height: 12),

          _AlertItem(
            title: 'مغایرت بانکی بررسی نشده',

            subtitle: 'نیاز به بررسی حسابدار',

            type: AlertType.warning,
          ),

          const SizedBox(height: 12),

          _AlertItem(
            title: 'گزارش مالی آماده بررسی است',

            subtitle: 'منتظر اقدام مشاور',

            type: AlertType.info,
          ),
        ],
      ),
    );
  }
}

enum AlertType { danger, warning, info }

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.title,

    required this.subtitle,

    required this.type,
  });

  final String title;

  final String subtitle;

  final AlertType type;

  Color get color {
    switch (type) {
      case AlertType.danger:
        return Colors.red;

      case AlertType.warning:
        return Colors.orange;

      case AlertType.info:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 10,

          height: 10,

          margin: const EdgeInsets.only(top: 6),

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
