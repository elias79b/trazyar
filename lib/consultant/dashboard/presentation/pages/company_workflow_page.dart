import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';

class CompanyWorkflowPage extends StatelessWidget {
  const CompanyWorkflowPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/workflow',

      title: 'گردش کار شرکت',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'وضعیت فرآیندها',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'پیگیری مراحل انجام کارهای شرکت',

              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            _StepCard(
              title: 'ثبت اطلاعات',

              description: 'اطلاعات اولیه شرکت ثبت شده است',

              status: 'تکمیل شده',

              state: StepStateType.done,
            ),

            _StepCard(
              title: 'بررسی توسط مشاور',

              description: 'مشاور در حال بررسی اطلاعات است',

              status: 'در حال انجام',

              state: StepStateType.active,
            ),

            _StepCard(
              title: 'تایید مدیریت',

              description: 'منتظر تایید نهایی',

              status: 'در انتظار',

              state: StepStateType.waiting,
            ),

            _StepCard(
              title: 'اصلاحات',

              description: 'در صورت نیاز به اصلاح اطلاعات',

              status: 'فعال نیست',

              state: StepStateType.disabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,

    required this.description,

    required this.status,

    required this.state,
  });

  final String title;

  final String description;

  final String status;

  final StepStateType state;

  @override
  Widget build(BuildContext context) {
    final color = _color(state);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 48,

            height: 48,

            decoration: BoxDecoration(
              color: color.withOpacity(.12),

              borderRadius: BorderRadius.circular(15),
            ),

            child: Icon(_icon(state), color: color),
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
                  description,

                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Text(
            status,

            style: TextStyle(
              color: color,

              fontWeight: FontWeight.bold,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _color(StepStateType state) {
    switch (state) {
      case StepStateType.done:
        return const Color(0xFF2D6A4F);

      case StepStateType.active:
        return Colors.blue;

      case StepStateType.waiting:
        return Colors.orange;

      case StepStateType.disabled:
        return Colors.grey;
    }
  }

  IconData _icon(StepStateType state) {
    switch (state) {
      case StepStateType.done:
        return Icons.check_circle_outline;

      case StepStateType.active:
        return Icons.sync_rounded;

      case StepStateType.waiting:
        return Icons.hourglass_empty_rounded;

      case StepStateType.disabled:
        return Icons.block_outlined;
    }
  }
}

enum StepStateType { done, active, waiting, disabled }
