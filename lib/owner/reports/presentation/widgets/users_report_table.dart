import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';


class UsersReportTable extends ConsumerWidget {
  const UsersReportTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersReportProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: users.when(
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
                  child: Text("کاربری یافت نشد"),
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
                  DataColumn(label: Text("نام")),
                  DataColumn(label: Text("ایمیل")),
                  DataColumn(label: Text("نقش")),
                  DataColumn(label: Text("وضعیت")),
                  DataColumn(label: Text("تاریخ عضویت")),
                ],
                rows: data.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(user["full_name"] ?? "-"),
                      ),
                      DataCell(
                        Text(user["email"] ?? "-"),
                      ),
                      DataCell(
                        Text(user["role"] ?? "-"),
                      ),
                      DataCell(
                        Chip(
                          label: Text(
                            user["is_active"] == true
                                ? "فعال"
                                : "غیرفعال",
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user["created_at"]
                              ?.toString()
                              .substring(0, 10) ??
                              "",
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