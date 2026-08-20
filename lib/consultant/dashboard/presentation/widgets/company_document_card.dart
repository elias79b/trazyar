import 'package:flutter/material.dart';

class CompanyDocumentCard extends StatelessWidget {
  const CompanyDocumentCard({
    super.key,

    required this.title,

    required this.type,

    required this.date,

    required this.status,
  });

  final String title;

  final String type;

  final String date;

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 50,

            height: 50,

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332).withOpacity(.10),

              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.folder_open_rounded,

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
              color: _statusColor().withOpacity(.12),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status,

              style: TextStyle(
                fontSize: 11,

                fontWeight: FontWeight.bold,

                color: _statusColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor() {
    if (status == 'تایید شده') {
      return const Color(0xFF2D6A4F);
    }

    if (status == 'در انتظار') {
      return Colors.orange;
    }

    return Colors.red;
  }
}
