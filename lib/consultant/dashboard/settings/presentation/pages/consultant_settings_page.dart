import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/consultant_scaffold.dart';
class ConsultantSettingsPage extends StatelessWidget {
  const ConsultantSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant/settings',

      title: 'تنظیمات',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'تنظیمات حساب مشاور',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 24),

            _SectionCard(
              title: 'پروفایل',

              icon: Icons.person_outline_rounded,

              items: ['ویرایش اطلاعات شخصی', 'تغییر تصویر پروفایل'],
            ),

            _SectionCard(
              title: 'امنیت',

              icon: Icons.security_rounded,

              items: ['تغییر رمز عبور', 'مدیریت نشست‌ها'],
            ),

            _SectionCard(
              title: 'اعلان‌ها',

              icon: Icons.notifications_none_rounded,

              items: ['اعلان گزارش‌های جدید', 'یادآوری اقدامات'],
            ),

            _SectionCard(
              title: 'نمایش',

              icon: Icons.display_settings_rounded,

              items: ['تنظیمات ظاهر', 'زبان نرم‌افزار'],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,

                  padding: const EdgeInsets.all(15),
                ),

                onPressed: () {
                  // بعداً به AuthService وصل می‌کنیم
                },

                icon: const Icon(Icons.logout_rounded),

                label: const Text('خروج از حساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,

    required this.icon,

    required this.items,
  });

  final String title;

  final IconData icon;

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1B4332)),

              const SizedBox(width: 10),

              Text(
                title,

                style: const TextStyle(
                  fontSize: 16,

                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),

              child: Row(
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 18),

                  Text(item, style: const TextStyle(fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
