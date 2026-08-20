import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';
import '../widgets/company_note_card.dart';

class CompanyNotesPage extends StatelessWidget {
  const CompanyNotesPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/notes',

      title: 'یادداشت‌های مشاور',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'یادداشت‌ها',

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),

                FilledButton.icon(
                  onPressed: () {},

                  icon: const Icon(Icons.add),

                  label: const Text('یادداشت جدید'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const CompanyNoteCard(
              title: 'بررسی وضعیت فروش',

              description:
                  'فروش شرکت در ماه اخیر کاهش داشته و نیاز به بررسی علت کاهش دارد.',

              date: 'امروز',
            ),

            const CompanyNoteCard(
              title: 'جلسه با مدیر مالی',

              description:
                  'در جلسه مقرر شد گزارش هزینه‌ها تا پایان هفته بررسی شود.',

              date: 'دیروز',
            ),

            const CompanyNoteCard(
              title: 'پیگیری اسناد',

              description: 'برخی اسناد مالی هنوز توسط شرکت ارسال نشده است.',

              date: '1405/02/01',
            ),
          ],
        ),
      ),
    );
  }
}
