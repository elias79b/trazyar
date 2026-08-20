import 'package:flutter/material.dart';

class CompanyFinancialSummaryCard extends StatelessWidget {
  const CompanyFinancialSummaryCard({
    super.key,

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
          Container(
            width: 45,

            height: 45,

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: const Color(0xFF1B4332)),
          ),

          const Spacer(),

          Text(
            value,

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 5),

          Text(
            title,

            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
