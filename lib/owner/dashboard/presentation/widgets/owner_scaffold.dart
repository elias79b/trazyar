import 'package:flutter/material.dart';
import 'owner_sidebar.dart';

class OwnerScaffold extends StatelessWidget {
  const OwnerScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
  });

  final String currentRoute;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: isDesktop
          ? null
          : AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(title),
      ),
      drawer: isDesktop
          ? null
          : Drawer(
        width: 280,
        child: SafeArea(
          child: OwnerSidebar(currentRoute: currentRoute),
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) OwnerSidebar(currentRoute: currentRoute),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1700),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}