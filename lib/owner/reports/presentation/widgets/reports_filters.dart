import 'package:flutter/material.dart';

class ReportsFilters extends StatefulWidget {
  const ReportsFilters({super.key});

  @override
  State<ReportsFilters> createState() => _ReportsFiltersState();
}

class _ReportsFiltersState extends State<ReportsFilters> {
  DateTimeRange? range;

  String reportType = 'همه';

  final types = const [
    'همه',
    'کاربران',
    'شرکت ها',
    'اشتراک ها',
    'درآمد',
    'فعالیت ها',
  ];

  Future<void> _pickDate() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (result != null) {
      setState(() {
        range = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [

            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                value: reportType,
                decoration: const InputDecoration(
                  labelText: 'نوع گزارش',
                  border: OutlineInputBorder(),
                ),
                items: types
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    reportType = v!;
                  });
                },
              ),
            ),

            SizedBox(
              width: 260,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range),
                label: Text(
                  range == null
                      ? "انتخاب بازه زمانی"
                      : "${range!.start.day}/${range!.start.month}/${range!.start.year}"
                      "   تا   "
                      "${range!.end.day}/${range!.end.month}/${range!.end.year}",
                ),
              ),
            ),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.search),
              label: const Text("اعمال فیلتر"),
            ),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text("بازنشانی"),
            ),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("PDF"),
            ),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.table_view),
              label: const Text("Excel"),
            ),

          ],
        ),
      ),
    );
  }
}