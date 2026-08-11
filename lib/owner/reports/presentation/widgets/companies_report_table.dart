import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';


class CompaniesReportTable extends ConsumerWidget {
  const CompaniesReportTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesReportProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: companies.when(
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
                  child: Text("شرکتی ثبت نشده است"),
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
                  DataColumn(label: Text("نام شرکت")),
                  DataColumn(label: Text("مدیر")),
                  DataColumn(label: Text("پلن")),
                  DataColumn(label: Text("وضعیت")),
                  DataColumn(label: Text("تاریخ ثبت")),
                ],
                rows: data.map((company) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(company["name"] ?? "-"),
                      ),
                      DataCell(
                        Text(company["owner_name"] ?? "-"),
                      ),
                      DataCell(
                        Text(company["plan_name"] ?? "-"),
                      ),
                      DataCell(
                        Chip(
                          label: Text(
                            company["is_active"] == true
                                ? "فعال"
                                : "غیرفعال",
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          company["created_at"]
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