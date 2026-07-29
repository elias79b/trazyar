import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_business),
              label: const Text('شرکت جدید'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add),
              label: const Text('کاربر جدید'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.workspace_premium),
              label: const Text('اشتراک'),
            ),
          ],
        ),
      ),
    );
  }
}