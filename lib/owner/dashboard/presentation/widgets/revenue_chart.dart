import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import '../../application/dashboard_provider.dart';
import '../../domain/models/chart_point.dart';

class RevenueChart extends ConsumerWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(companiesGrowthProvider);

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
              title: charts.ChartTitle(text: 'رشد شرکت‌ها در سال جاری'),
              legend: const charts.Legend(isVisible: false),
              primaryXAxis: const charts.CategoryAxis(),
              series: [
                charts.LineSeries<DashboardChartPoint, String>(
                  dataSource: list,
                  xValueMapper: (e, _) => e.x,
                  yValueMapper: (e, _) => e.y,
                  width: 4,
                  markerSettings: const charts.MarkerSettings(isVisible: true),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}