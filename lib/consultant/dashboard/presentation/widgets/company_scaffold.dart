import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/company_alerts_provider.dart';
import 'company_sidebar.dart';

class CompanyScaffold extends ConsumerWidget {
  const CompanyScaffold({
    super.key,
    required this.companyId,
    required this.currentRoute,
    required this.title,
    required this.body,
  });

  final String companyId;
  final String currentRoute;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: Row(
        children: [
          if (isDesktop)
            CompanySidebar(companyId: companyId, currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                _CompanyTopBar(
                  companyId: companyId,
                  title: title,
                  showMenu: !isDesktop,
                  onMenuPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      drawer:
          isDesktop
              ? null
              : Drawer(
                child: CompanySidebar(
                  companyId: companyId,
                  currentRoute: currentRoute,
                ),
              ),
    );
  }
}

// ============================================================
// COMPANY TOP BAR
// ============================================================

class _CompanyTopBar extends StatelessWidget {
  const _CompanyTopBar({
    required this.companyId,
    required this.title,
    required this.showMenu,
    required this.onMenuPressed,
  });

  final String companyId;
  final String title;
  final bool showMenu;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (showMenu) ...[
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: onMenuPressed,
                  tooltip: 'منوی شرکت',
                  icon: const Icon(Icons.menu_rounded),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17211D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'پنل شرکت',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          _CompanyAlertBell(companyId: companyId),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ALERT BELL
// ============================================================

class _CompanyAlertBell extends ConsumerStatefulWidget {
  const _CompanyAlertBell({required this.companyId});

  final String companyId;

  @override
  ConsumerState<_CompanyAlertBell> createState() => _CompanyAlertBellState();
}

class _CompanyAlertBellState extends ConsumerState<_CompanyAlertBell> {
  OverlayEntry? _overlayEntry;

  bool get _isOpen => _overlayEntry != null;

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    super.dispose();
  }

  void _toggle() {
    if (!mounted) {
      return;
    }

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted) {
      return;
    }

    final overlay = Overlay.of(context);

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final renderBox = renderObject;

    if (!renderBox.hasSize) {
      return;
    }

    final overlayRenderObject = overlay.context.findRenderObject();

    if (overlayRenderObject is! RenderBox) {
      return;
    }

    final position = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderObject,
    );

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final screenWidth = MediaQuery.sizeOf(overlayContext).width;

        const popupWidth = 380.0;

        final desiredRight = screenWidth - (position.dx + size.width);

        final right = desiredRight.clamp(10.0, screenWidth - popupWidth - 10.0);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: position.dy + size.height + 8,
              right: right,
              child: _AlertPopup(
                companyId: widget.companyId,
                onClose: _removeOverlay,
              ),
            ),
          ],
        );
      },
    );

    final entry = _overlayEntry;

    if (entry == null) {
      return;
    }

    overlay.insert(entry);

    if (mounted) {
      setState(() {});
    }
  }

  void _removeOverlay({bool updateState = true}) {
    final entry = _overlayEntry;

    _overlayEntry = null;

    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {}
    }

    if (updateState && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(companyAlertsProvider(widget.companyId));

    final alertCount = alertsAsync.maybeWhen(
      data: (alerts) => alerts.length,
      orElse: () => 0,
    );

    return Tooltip(
      message: 'هشدارهای شرکت',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: _toggle,
            tooltip: 'هشدارهای شرکت',
            icon: Icon(
              _isOpen
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: const Color(0xFF1B4332),
              size: 24,
            ),
          ),
          if (alertCount > 0)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    alertCount > 99 ? '99+' : alertCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ALERT POPUP
// ============================================================

class _AlertPopup extends ConsumerWidget {
  const _AlertPopup({required this.companyId, required this.onClose});

  final String companyId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(companyAlertsProvider(companyId));

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'هشدارهای شرکت',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'بستن',
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Flexible(
              child: alertsAsync.when(
                loading: () {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                error: (error, stackTrace) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  );
                },
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF2D6A4F),
                              size: 42,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'هشدار فعالی وجود ندارد',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'وضعیت فعلی شرکت مناسب است.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (var i = 0; i < alerts.length; i++) ...[
                          _AlertItem(
                            alert: alerts[i],
                            onTap: () {
                              onClose();
                              context.go(alerts[i].route);
                            },
                          ),
                          if (i != alerts.length - 1) const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    onClose();
                    context.go('/consultant/companies/$companyId/banking');
                  },
                  icon: const Icon(Icons.account_balance_rounded, size: 18),
                  label: const Text('مشاهده داشبورد بانک و نقد'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ALERT ITEM
// ============================================================

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.alert, required this.onTap});

  final CompanyAlert alert;
  final VoidCallback onTap;

  Color get _color {
    switch (alert.severity) {
      case CompanyAlertSeverity.danger:
        return Colors.red.shade700;

      case CompanyAlertSeverity.warning:
        return Colors.orange.shade700;

      case CompanyAlertSeverity.info:
        return Colors.blue.shade700;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      // ========================================================
      // BANKING
      // ========================================================

      case CompanyAlertType.bankDiscrepancy:
        return Icons.account_balance_rounded;

      case CompanyAlertType.cashDiscrepancy:
        return Icons.point_of_sale_rounded;

      case CompanyAlertType.pettyCashDiscrepancy:
        return Icons.payments_outlined;

      case CompanyAlertType.upcomingCheck:
        return Icons.schedule_rounded;

      case CompanyAlertType.overdueCheck:
        return Icons.warning_amber_rounded;

      case CompanyAlertType.loan:
        return Icons.request_quote_rounded;

      // ========================================================
      // PAYROLL
      // ========================================================

      case CompanyAlertType.payrollPendingCeo:
        return Icons.pending_actions_rounded;

      case CompanyAlertType.payrollCeoApproved:
        return Icons.verified_rounded;

      case CompanyAlertType.payrollPendingConsultant:
        return Icons.fact_check_rounded;

      case CompanyAlertType.payrollRejected:
        return Icons.cancel_rounded;

      case CompanyAlertType.payrollDraft:
        return Icons.edit_note_rounded;

      // ========================================================
      // INCOME
      // ========================================================

      case CompanyAlertType.incomeNoRecognition:
        return Icons.pending_actions_rounded;

      case CompanyAlertType.incomeReceivableWithoutRecognition:
        return Icons.warning_amber_rounded;

      case CompanyAlertType.incomeReceivableExceededRecognition:
        return Icons.difference_rounded;

      case CompanyAlertType.incomeUnreceivedReceivable:
        return Icons.receipt_long_rounded;

      case CompanyAlertType.incomeOpenPeriod:
        return Icons.calendar_month_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
