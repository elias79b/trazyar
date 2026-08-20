import 'package:flutter/material.dart';

class CompanyFinancialIndicator extends StatelessWidget {
  const CompanyFinancialIndicator({super.key});

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
          const Text(
            'شاخص‌های کلیدی مالی',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 20),

          _IndicatorRow(title: 'حاشیه سود', value: '۳۲٪', status: 'مطلوب'),

          _IndicatorRow(title: 'رشد فروش', value: '۱۸٪', status: 'مثبت'),

          _IndicatorRow(
            title: 'نسبت هزینه به درآمد',

            value: '۴۵٪',

            status: 'نیازمند بررسی',
          ),

          _IndicatorRow(title: 'وضعیت نقدینگی', value: 'خوب', status: 'تایید'),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.title,

    required this.value,

    required this.status,
  });

  final String title;

  final String value;

  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Expanded(
            child: Text(
              title,

              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.12),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status,

              style: const TextStyle(
                fontSize: 10,

                color: Color(0xFF1B4332),

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
