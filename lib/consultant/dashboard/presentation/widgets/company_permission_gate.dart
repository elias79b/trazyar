import 'package:flutter/material.dart';
import 'package:tarazyar/consultant/dashboard/data/services/company_permission_service.dart';

class CompanyPermissionGate extends StatefulWidget {
  final String companyId;
  final String permission;
  final Widget child;
  final Widget? denied;

  const CompanyPermissionGate({
    super.key,
    required this.companyId,
    required this.permission,
    required this.child,
    this.denied,
  });

  @override
  State<CompanyPermissionGate> createState() =>
      _CompanyPermissionGateState();
}

class _CompanyPermissionGateState
    extends State<CompanyPermissionGate> {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant CompanyPermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.companyId != widget.companyId ||
        oldWidget.permission != widget.permission) {
      _check();
    }
  }

  Future<void> _check() async {
    try {
      final allowed = await CompanyPermissionService.can(
        widget.companyId,
        widget.permission,
      );

      if (!mounted) return;

      setState(() {
        _allowed = allowed;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allowed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == null) {
      return const SizedBox.shrink();
    }

    if (_allowed == false) {
      return widget.denied ?? const SizedBox.shrink();
    }

    return widget.child;
  }
}