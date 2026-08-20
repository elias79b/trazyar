import 'package:flutter/material.dart';

import '../../data/models/activity_log_model.dart';

class CompanyActivityCard extends StatelessWidget {
  const CompanyActivityCard({super.key, required this.activities});

  final List<ActivityLogModel> activities;

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
          const Text(
            'آخرین فعالیت‌ها',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 16),

          ...activities.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,

              leading: const CircleAvatar(child: Icon(Icons.history)),

              title: Text(item.title),

              subtitle: Text(item.description ?? ''),
            );
          }),
        ],
      ),
    );
  }
}
