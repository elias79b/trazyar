import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';

class LatestCompaniesWidget extends ConsumerWidget {
  const LatestCompaniesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(latestCompaniesProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: companies.when(
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
                "خطا در دریافت شرکت‌ها\n$e",
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: Text("شرکتی ثبت نشده است."),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "آخرین شرکت‌ها",
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
                    final company = list[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        Colors.green.withOpacity(.12),
                        child: const Icon(
                          Icons.business,
                          color: Colors.green,
                        ),
                      ),

                      title: Text(
                        company['name']?.toString() ??
                            'بدون نام',
                      ),

                      subtitle: Text(
                        company['owner_name']?.toString() ??
                            '',
                      ),

                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [

                          Text(
                            company['subscription_type']
                                ?.toString() ??
                                '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            company['created_at']
                                ?.toString()
                                .substring(0, 10) ??
                                '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
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