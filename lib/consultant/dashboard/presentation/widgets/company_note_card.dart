import 'package:flutter/material.dart';

class CompanyNoteCard extends StatelessWidget {
  const CompanyNoteCard({
    super.key,

    required this.title,

    required this.description,

    required this.date,
  });

  final String title;

  final String description;

  final String date;

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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,

                height: 42,

                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(.1),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.note_alt_rounded,

                  color: Color(0xFF1B4332),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    fontSize: 14,

                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Text(
                date,

                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            description,

            style: TextStyle(
              fontSize: 13,

              color: Colors.grey.shade700,

              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
