import 'package:flutter/material.dart';

class ConsultantKpiCard extends StatelessWidget {
  const ConsultantKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332)
                  .withOpacity(.10),
              borderRadius:
              BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: const Color(0xFF1B4332),
              size: 28,
            ),
          ),


          const SizedBox(width: 14),


          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17211D),
                  ),
                ),


                const SizedBox(height: 4),


                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),


                if (subtitle != null) ...[

                  const SizedBox(height: 4),

                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),

                ],

              ],
            ),
          ),

        ],
      ),
    );
  }
}