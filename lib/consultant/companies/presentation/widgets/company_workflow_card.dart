import 'package:flutter/material.dart';

class CompanyWorkflowCard extends StatelessWidget {
  const CompanyWorkflowCard({super.key});

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
              Icon(Icons.account_tree_rounded, color: Color(0xFF1B4332)),

              SizedBox(width: 10),

              Text(
                'گردش کار شرکت',

                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _WorkflowItem(
            title: 'حقوق و دستمزد',

            status: 'در انتظار تایید مدیر',

            progress: 0.65,

            color: Colors.orange,
          ),

          const SizedBox(height: 18),

          _WorkflowItem(
            title: 'گزارش مالی ماهانه',

            status: 'تکمیل شده',

            progress: 1,

            color: Colors.green,
          ),

          const SizedBox(height: 18),

          _WorkflowItem(
            title: 'مغایرت بانکی',

            status: 'در انتظار بررسی',

            progress: 0.35,

            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _WorkflowItem extends StatelessWidget {
  const _WorkflowItem({
    required this.title,

    required this.status,

    required this.progress,

    required this.color,
  });

  final String title;

  final String status;

  final double progress;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),

            Text(
              status,

              style: TextStyle(
                fontSize: 12,

                color: color,

                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),

          child: LinearProgressIndicator(
            value: progress,

            minHeight: 8,

            color: color,

            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}
