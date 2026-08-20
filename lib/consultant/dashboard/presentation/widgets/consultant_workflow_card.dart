import 'package:flutter/material.dart';

class ConsultantWorkflowCard extends StatelessWidget {
  const ConsultantWorkflowCard({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _WorkflowStep(
        title: 'ثبت اطلاعات',
        count: '۱۲',
        icon: Icons.edit_note_rounded,
        status: WorkflowStatus.active,
      ),

      const _WorkflowStep(
        title: 'در انتظار بررسی',
        count: '۷',
        icon: Icons.search_rounded,
        status: WorkflowStatus.waiting,
      ),

      const _WorkflowStep(
        title: 'تایید شده',
        count: '۱۸',
        icon: Icons.check_circle_outline_rounded,
        status: WorkflowStatus.done,
      ),

      const _WorkflowStep(
        title: 'نیازمند اصلاح',
        count: '۳',
        icon: Icons.replay_rounded,
        status: WorkflowStatus.warning,
      ),
    ];

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
            'وضعیت گردش کار',

            style: TextStyle(
              fontSize: 17,

              fontWeight: FontWeight.w900,

              color: Color(0xFF17211D),
            ),
          ),

          const SizedBox(height: 18),

          ...steps.map((step) => _WorkflowRow(step: step)),
        ],
      ),
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({required this.step});

  final _WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(step.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),

        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: color.withOpacity(.12),

              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(step.icon, color: color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              step.title,

              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

            decoration: BoxDecoration(
              color: color.withOpacity(.12),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              step.count,

              style: TextStyle(
                color: color,

                fontSize: 12,

                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.active:
        return const Color(0xFF457B9D);

      case WorkflowStatus.waiting:
        return Colors.orange;

      case WorkflowStatus.done:
        return const Color(0xFF2D6A4F);

      case WorkflowStatus.warning:
        return Colors.red;
    }
  }
}

enum WorkflowStatus { active, waiting, done, warning }

class _WorkflowStep {
  const _WorkflowStep({
    required this.title,

    required this.count,

    required this.icon,

    required this.status,
  });

  final String title;

  final String count;

  final IconData icon;

  final WorkflowStatus status;
}
