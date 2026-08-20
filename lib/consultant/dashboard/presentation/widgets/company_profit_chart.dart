import 'package:flutter/material.dart';

class CompanyProfitChart extends StatelessWidget {
  const CompanyProfitChart({super.key});

  @override
  Widget build(BuildContext context) {
    final months = ['فر', 'ار', 'خر', 'تیر', 'مر', 'شه'];

    final profit = [90, 130, 170, 155, 230, 280];

    return Container(
      height: 340,

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
            'روند سود خالص',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 8),

          Text(
            'مقایسه رشد سود در ماه‌های اخیر',

            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 25),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,

              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: List.generate(months.length, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,

                      children: [
                        Container(
                          width: 30,

                          height: 180,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,

                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        Container(
                          width: 30,

                          height: profit[index] / 2,

                          decoration: BoxDecoration(
                            color: const Color(0xFF40916C),

                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      months[index],

                      style: TextStyle(
                        fontSize: 11,

                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 10,

                height: 10,

                decoration: const BoxDecoration(
                  color: Color(0xFF40916C),

                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'رشد سود مثبت',

                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
