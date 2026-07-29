import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import '../../application/dashboard_provider.dart';
import '../../domain/models/chart_point.dart';

class UsersChart extends ConsumerWidget {
  const UsersChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(usersGrowthProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('خطا در دریافت نمودار')),
          data: (list) {
            return charts.SfCartesianChart(
              title: charts.ChartTitle(text: 'رشد کاربران در سال جاری'),
              primaryXAxis: const charts.CategoryAxis(),
              series: [
                charts.ColumnSeries<DashboardChartPoint, String>(
                  dataSource: list,
                  xValueMapper: (e, _) => e.x,
                  yValueMapper: (e, _) => e.y,
                )
              ],
            );
          },
        ),
      ),
    );
  }
}