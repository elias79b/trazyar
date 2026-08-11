import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings_provider.dart';

class SubscriptionSettingsCard extends ConsumerWidget {
  const SubscriptionSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return subscription.when(

      loading: () => const Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      error: (e, _) => Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: Text(e.toString()),
          ),
        ),
      ),

      data: (data) {

        final plan = data["plans"] ?? {};

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "اشتراک نرم افزار",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _item(
                  Icons.workspace_premium,
                  "پلن",
                  plan["title"] ?? "-",
                ),

                _item(
                  Icons.business,
                  "شرکت مجاز",
                  "${plan["max_companies"] ?? 0}",
                ),

                _item(
                  Icons.people,
                  "کاربر مجاز",
                  "${plan["max_users"] ?? 0}",
                ),

                _item(
                  Icons.storage,
                  "فضای ذخیره سازی",
                  "${plan["storage"] ?? 0} GB",
                ),

                _item(
                  Icons.calendar_month,
                  "تاریخ شروع",
                  data["start_date"] ?? "-",
                ),

                _item(
                  Icons.event,
                  "تاریخ پایان",
                  data["end_date"] ?? "-",
                ),

                _item(
                  Icons.check_circle,
                  "وضعیت",
                  data["status"] ?? "-",
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upgrade),
                    label: const Text("ارتقاء اشتراک"),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _item(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [

          Icon(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Text(title),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}