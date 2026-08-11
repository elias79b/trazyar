import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings_provider.dart';

class SystemInfoCard extends ConsumerWidget {
  const SystemInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemInfo = ref.watch(systemInfoProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: systemInfo.when(
          loading: () => const SizedBox(
            height: 280,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'خطا در دریافت اطلاعات سیستم',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _buildContent(context, data),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اطلاعات سیستم',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        _InfoRow(
          icon: Icons.apps,
          title: 'نام نرم افزار',
          value: data['app_name']?.toString() ?? 'ترازیار',
        ),

        _InfoRow(
          icon: Icons.verified,
          title: 'نسخه',
          value: data['version']?.toString() ?? '-',
        ),

        _InfoRow(
          icon: Icons.storage,
          title: 'پایگاه داده',
          value: data['database']?.toString() ?? '-',
        ),

        _InfoRow(
          icon: Icons.flutter_dash,
          title: 'Flutter',
          value: data['flutter']?.toString() ?? '-',
        ),

        _InfoRow(
          icon: Icons.code,
          title: 'Dart',
          value: data['dart']?.toString() ?? '-',
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'سیستم در وضعیت پایدار قرار دارد.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.system_update),
            label: const Text('بررسی بروزرسانی'),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}