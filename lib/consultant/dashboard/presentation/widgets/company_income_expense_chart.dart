import 'package:flutter/material.dart';

class CompanyIncomeExpenseChart extends StatelessWidget {
  const CompanyIncomeExpenseChart({super.key});

  @override
  Widget build(BuildContext context) {
    final months = ['فر', 'ار', 'خر', 'تیر', 'مر', 'شه'];

    final income = [120, 180, 240, 210, 300, 360];

    final expense = [80, 110, 150, 140, 170, 200];

    return Container(
      padding: const EdgeInsets.all(22),

      height: 360,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'درآمد و هزینه ماهانه',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _Legend(color: const Color(0xFF2D6A4F), title: 'درآمد'),

              const SizedBox(width: 18),

              _Legend(color: Colors.orange, title: 'هزینه'),
            ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,

                      children: [
                        Container(
                          width: 14,

                          height: income[index] / 2,

                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F),

                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(width: 5),

                        Container(
                          width: 14,

                          height: expense[index] / 2,

                          decoration: BoxDecoration(
                            color: Colors.orange,

                            borderRadius: BorderRadius.circular(6),
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
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.title});

  final Color color;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,

          height: 10,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text(
          title,

          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
