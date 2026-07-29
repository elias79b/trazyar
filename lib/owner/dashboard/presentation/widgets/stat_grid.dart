import 'package:flutter/material.dart';
import 'stat_card.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: const [
        StatCard(
          title: "شرکت ها",
          value: "12",
          icon: Icons.apartment,
          color: Colors.blue,
        ),
        StatCard(
          title: "کاربران",
          value: "84",
          icon: Icons.people,
          color: Colors.green,
        ),
        StatCard(
          title: "اشتراک فعال",
          value: "51",
          icon: Icons.workspace_premium,
          color: Colors.orange,
        ),
        StatCard(
          title: "درآمد این ماه",
          value: "58M",
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }
}