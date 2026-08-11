import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(recentActivitiesProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: activities.when(
          loading: () => const SizedBox(
            height: 420,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 420,
            child: Center(
              child: Text(
                "خطا در دریافت اطلاعات\n$e",
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: Text("فعالیتی ثبت نشده است."),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "آخرین فعالیت‌ها",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = list[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        Colors.blue.withOpacity(.1),
                        child: const Icon(
                          Icons.history,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        item['title']?.toString() ??
                            'بدون عنوان',
                      ),
                      subtitle: Text(
                        item['description']?.toString() ?? '',
                      ),
                      trailing: Text(
                        item['created_at']
                            ?.toString()
                            .substring(0, 10) ??
                            '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}