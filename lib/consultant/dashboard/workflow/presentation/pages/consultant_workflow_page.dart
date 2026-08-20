import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/consultant_scaffold.dart';

class ConsultantWorkflowPage extends StatelessWidget {
  const ConsultantWorkflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant/workflow',

      title: 'گردش کار',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'گردش فرآیندها',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'مدیریت مراحل انجام کار شرکت‌ها',

              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _WorkflowCard(
              company: 'شرکت بازرگانی آریا',

              process: 'بررسی گزارش مالی',

              step: 'بررسی مشاور',

              status: 'در حال انجام',
            ),

            _WorkflowCard(
              company: 'شرکت تولیدی پارس',

              process: 'تطبیق اسناد',

              step: 'منتظر تایید',

              status: 'متوقف',
            ),

            _WorkflowCard(
              company: 'شرکت فناوری آینده',

              process: 'تحلیل عملکرد',

              step: 'تکمیل شده',

              status: 'پایان',
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.company,

    required this.process,

    required this.step,

    required this.status,
  });

  final String company;
  final String process;
  final String step;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

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
              const Icon(Icons.account_tree_rounded, color: Color(0xFF1B4332)),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  company,

                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),

              Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),

          const SizedBox(height: 14),

          Text(process, style: const TextStyle(fontWeight: FontWeight.w700)),

          const SizedBox(height: 6),

          Text(
            'مرحله فعلی: $step',

            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
