import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/authentication/application/auth_service.dart';
import 'package:tarazyar/shared/presentation/widgets/dashboard_shell_widget.dart';

class ConsultantPage extends ConsumerWidget {
  const ConsultantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardShellWidget(
      title: 'داشبورد مشاور',
      onSignOut: () => ref.read(authServiceProvider).signOut(),
    );
  }
}
