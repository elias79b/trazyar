import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';

import '../../domain/models/chart_point.dart' as model;

class UsersChart extends ConsumerWidget {
  const UsersChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chart = ref.watch(usersChartProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: chart.when(
          loading: () => const SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => SizedBox(
            height: 320,
            child: Center(
              child: Text(e.toString()),
            ),
          ),
          data: (data) {
            return SizedBox(
              height: 320,
              child: SfCartesianChart(
                title: const ChartTitle(
                  text: "رشد کاربران",
                ),
                legend: const Legend(
                  isVisible: true,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                ),
                primaryXAxis: const CategoryAxis(),
                series: <CartesianSeries>[
                  LineSeries<model.ChartPoint, String>(
                    dataSource: data,
                    xValueMapper: (model.ChartPoint item, _) => item.x,
                    yValueMapper: (model.ChartPoint item, _) => item.y,
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                    ),
                    name: "کاربران",
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}