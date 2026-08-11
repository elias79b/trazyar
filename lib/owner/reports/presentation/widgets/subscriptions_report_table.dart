import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';


class SubscriptionsReportTable extends ConsumerWidget {
  const SubscriptionsReportTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsReportProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: subscriptions.when(
          loading: () => const SizedBox(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 400,
            child: Center(
              child: Text(e.toString()),
            ),
          ),
          data: (data) {
            if (data.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: Text("اشتراکی یافت نشد"),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 50,
                dataRowMinHeight: 55,
                dataRowMaxHeight: 60,
                columns: const [
                  DataColumn(label: Text("شرکت")),
                  DataColumn(label: Text("پلن")),
                  DataColumn(label: Text("وضعیت")),
                  DataColumn(label: Text("شروع")),
                  DataColumn(label: Text("پایان")),
                ],
                rows: data.map((subscription) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(subscription["company_name"] ?? "-"),
                      ),
                      DataCell(
                        Text(subscription["plan_name"] ?? "-"),
                      ),
                      DataCell(
                        Chip(
                          backgroundColor:
                          subscription["status"] == "active"
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          label: Text(
                            subscription["status"] == "active"
                                ? "فعال"
                                : "غیرفعال",
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          subscription["starts_at"]
                              ?.toString()
                              .substring(0, 10) ??
                              "-",
                        ),
                      ),
                      DataCell(
                        Text(
                          subscription["expires_at"]
                              ?.toString()
                              .substring(0, 10) ??
                              "-",
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}