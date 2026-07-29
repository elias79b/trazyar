import 'package:flutter/material.dart';
import 'package:tarazyar/core/responsive/responsive.dart';

class DashboardGrid extends StatelessWidget {
  final List<Widget> children;

  const DashboardGrid({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.dashboardGridCount(context),
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (_, index) => children[index],
    );
  }
}