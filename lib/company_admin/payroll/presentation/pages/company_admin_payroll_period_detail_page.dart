import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

import '../../application/company_admin_payroll_period_detail_provider.dart';

class CompanyAdminPayrollPeriodDetailPage extends ConsumerWidget {
  final String periodId;

  const CompanyAdminPayrollPeriodDetailPage({
    super.key,
    required this.periodId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      companyAdminPayrollPeriodDetailProvider(periodId),
    );

    return state.when(
      loading: () {
        return const CompanyAdminScaffold(
          child: Scaffold(
            backgroundColor: Color(0xfff5f7fb),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return CompanyAdminScaffold(
          child: Scaffold(
            backgroundColor: const Color(0xfff5f7fb),
            body: Center(
              child: _ErrorState(error: error),
            ),
          ),
        );
      },
      data: (data) {
        return CompanyAdminScaffold(
          child: _PayrollPeriodDetailView(
            periodId: periodId,
            data: data,
          ),
        );
      },
    );
  }
}

class _PayrollPeriodDetailView extends ConsumerStatefulWidget {
  final String periodId;
  final CompanyAdminPayrollPeriodDetailData data;

  const _PayrollPeriodDetailView({
    required this.periodId,
    required this.data,
  });

  @override
  ConsumerState<_PayrollPeriodDetailView> createState() =>
      _PayrollPeriodDetailViewState();
}

class _PayrollPeriodDetailViewState
    extends ConsumerState<_PayrollPeriodDetailView> {
  bool _processing = false;

  Future<void> _runWorkflow({
    required String action,
    required String title,
    required String successMessage,
    bool askForNote = false,
  }) async {
    if (_processing) {
      return;
    }

    String? note;

    if (askForNote) {
      note = await _showNoteDialog(
        context,
        title: title,
      );

      if (note == null) {
        return;
      }
    }

    setState(() {
      _processing = true;
    });

    try {
      final client = ref.read(_supabaseClientProvider);

      await client.rpc(
        'process_payroll_period',
        params: {
          'p_period_id': widget.periodId,
          'p_action': action,
          'p_note': note,
        },
      );

      ref.invalidate(
        companyAdminPayrollPeriodDetailProvider(widget.periodId),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xffdc2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در انجام عملیات: $error'),
          backgroundColor: const Color(0xffdc2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<String?> _showNoteDialog(
      BuildContext context, {
        required String title,
      }) async {
    final controller = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                hintText: 'توضیحات عملیات را وارد کنید...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(null);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    controller.text.trim(),
                  );
                },
                child: const Text('ثبت'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<void> _confirmAction({
    required String action,
    required String title,
    required String message,
    required String successMessage,
    bool askForNote = true,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('تأیید'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runWorkflow(
      action: action,
      title: title,
      successMessage: successMessage,
      askForNote: askForNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final period = data.period;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff5f7fb),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  period: period,
                  processing: _processing,
                ),

                const SizedBox(height: 16),

                _WorkflowActions(
                  period: period,
                  processing: _processing,
                  onApproveByCeo: () {
                    _confirmAction(
                      action: 'approve_by_ceo',
                      title: 'تأیید دوره حقوق',
                      message:
                      'آیا از تأیید این دوره حقوق توسط مدیرعامل اطمینان دارید؟',
                      successMessage:
                      'دوره حقوق با موفقیت توسط مدیرعامل تأیید شد.',
                    );
                  },
                  onReturnToAccountant: () {
                    _confirmAction(
                      action: 'return_to_accountant',
                      title: 'برگشت دوره به حسابدار',
                      message:
                      'آیا می‌خواهید این دوره برای اصلاح به حسابدار برگشت داده شود؟',
                      successMessage:
                      'دوره حقوق برای اصلاح به حسابدار برگشت داده شد.',
                    );
                  },
                  onSendToConsultant: () {
                    _confirmAction(
                      action: 'send_to_consultant',
                      title: 'ارسال به مشاور',
                      message:
                      'آیا می‌خواهید دوره تأییدشده را برای بررسی مشاور ارسال کنید؟',
                      successMessage:
                      'دوره حقوق برای مشاور ارسال شد.',
                    );
                  },
                ),

                const SizedBox(height: 18),

                _Summary(data: data),

                const SizedBox(height: 20),

                _SectionTitle(
                  title: 'ریز حقوق کارکنان',
                  count: data.records.length,
                ),

                const SizedBox(height: 12),

                _EmployeePayrollTable(
                  records: data.records,
                ),

                const SizedBox(height: 24),

                _SectionTitle(
                  title: 'هزینه مراکز هزینه',
                  count: data.costCenters.length,
                ),

                const SizedBox(height: 12),

                _CostCenterSection(
                  records: data.costCenters,
                ),

                const SizedBox(height: 24),

                _WorkflowHistorySection(
                  workflow: data.workflow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowActions extends StatelessWidget {
  final CompanyAdminPayrollPeriodDetail period;
  final bool processing;

  final VoidCallback onApproveByCeo;
  final VoidCallback onReturnToAccountant;
  final VoidCallback onSendToConsultant;

  const _WorkflowActions({
    required this.period,
    required this.processing,
    required this.onApproveByCeo,
    required this.onReturnToAccountant,
    required this.onSendToConsultant,
  });

  @override
  Widget build(BuildContext context) {
    if (processing) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xffe5e7eb),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'در حال ثبت عملیات...',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (period.isPendingCeo) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xfffffbeb),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xfff59e0b),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  color: Color(0xffd97706),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'این دوره در انتظار بررسی مدیرعامل است.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xff92400e),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onApproveByCeo,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 19,
                  ),
                  label: const Text('تأیید و ادامه'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff059669),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onReturnToAccountant,
                  icon: const Icon(
                    Icons.undo_outlined,
                    size: 19,
                  ),
                  label: const Text('برگشت به حسابدار'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffdc2626),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (period.isCeoApproved) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xffeff6ff),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xff93c5fd),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: Color(0xff2563eb),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'دوره توسط مدیرعامل تأیید شده و آماده ارسال برای مشاور است.',
                style: TextStyle(
                  color: Color(0xff1e40af),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onSendToConsultant,
              icon: const Icon(
                Icons.send_outlined,
                size: 18,
              ),
              label: const Text('ارسال به مشاور'),
            ),
          ],
        ),
      );
    }

    if (period.isPendingConsultant) {
      return _InfoWorkflowBox(
        icon: Icons.hourglass_top_outlined,
        color: const Color(0xff7c3aed),
        background: const Color(0xfff5f3ff),
        text: 'دوره برای بررسی مشاور ارسال شده است.',
      );
    }

    if (period.isConsultantApproved) {
      return _InfoWorkflowBox(
        icon: Icons.verified_outlined,
        color: const Color(0xff059669),
        background: const Color(0xffecfdf5),
        text: 'این دوره تأیید نهایی شده است.',
      );
    }

    return const SizedBox.shrink();
  }
}

class _InfoWorkflowBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  const _InfoWorkflowBox({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CompanyAdminPayrollPeriodDetail period;
  final bool processing;

  const _Header({
    required this.period,
    required this.processing,
  });

  @override
  Widget build(BuildContext context) {
    final pending = period.isPendingCeo;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
          pending
              ? const Color(0xfff59e0b)
              : const Color(0xffe5e7eb),
          width: pending ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
              pending
                  ? const Color(0xfffff7ed)
                  : const Color(0xffeef6ff),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color:
              pending
                  ? const Color(0xffea580c)
                  : const Color(0xff2563eb),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جزئیات دوره ${period.title}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _StatusBadge(period: period),
              ],
            ),
          ),
          if (processing)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CompanyAdminPayrollPeriodDetail period;

  const _StatusBadge({
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(period.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            period.statusTitle,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CompanyAdminPayrollPeriodDetailData data;

  const _Summary({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
        constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 650
            ? 2
            : 1;

        const gap = 14.0;

        final width =
            (constraints.maxWidth - ((columns - 1) * gap)) /
                columns;

        final cards = [
          _MetricCard(
            width: width,
            title: 'تعداد کارکنان',
            value: _number(data.employeeCount),
            icon: Icons.people_outline,
          ),
          _MetricCard(
            width: width,
            title: 'حقوق ناخالص',
            value: _money(data.totalGrossSalary),
            icon: Icons.account_balance_wallet_outlined,
          ),
          _MetricCard(
            width: width,
            title: 'حقوق خالص',
            value: _money(data.totalNetSalary),
            icon: Icons.payments_outlined,
          ),
          _MetricCard(
            width: width,
            title: 'هزینه کل کارفرما',
            value: _money(data.totalEmployerCost),
            icon: Icons.business_center_outlined,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xffe5e7eb),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xffeff6ff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xff2563eb),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffeef2ff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_number(count)} مورد',
            style: const TextStyle(
              color: Color(0xff4f46e5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeePayrollTable extends StatelessWidget {
  final List<CompanyAdminPayrollRecord> records;

  const _EmployeePayrollTable({
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyBox(
        text: 'برای این دوره هنوز ریز حقوق کارکنان ثبت نشده است.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe5e7eb),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 58,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(label: Text('کارمند')),
            DataColumn(label: Text('حقوق پایه')),
            DataColumn(label: Text('اضافه‌کاری')),
            DataColumn(label: Text('ناخالص')),
            DataColumn(label: Text('بیمه کارفرما')),
            DataColumn(label: Text('مالیات')),
            DataColumn(label: Text('خالص پرداختی')),
          ],
          rows:
          records
              .map(
                (record) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 190,
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.employee?.fullName ??
                              'کارمند نامشخص',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (record.employee?.personnelCode !=
                            null)
                          Text(
                            'کد پرسنلی: ${_persian(record.employee!.personnelCode!)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xff6b7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Text(_money(record.baseSalary)),
                ),
                DataCell(
                  Text(_money(record.overtimeAmount)),
                ),
                DataCell(
                  Text(_money(record.grossSalary)),
                ),
                DataCell(
                  Text(_money(record.employerInsurance)),
                ),
                DataCell(
                  Text(_money(record.taxAmount)),
                ),
                DataCell(
                  Text(
                    _money(record.netSalary),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

class _CostCenterSection extends StatelessWidget {
  final List<CompanyAdminPayrollCostCenterRecord> records;

  const _CostCenterSection({
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyBox(
        text: 'برای این دوره اطلاعات مرکز هزینه ثبت نشده است.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe5e7eb),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < records.length; i++) ...[
            _CostCenterItem(
              record: records[i],
            ),
            if (i != records.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CostCenterItem extends StatelessWidget {
  final CompanyAdminPayrollCostCenterRecord record;

  const _CostCenterItem({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xfff5f3ff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: Color(0xff7c3aed),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  record.costCenterName ??
                      'مرکز هزینه نامشخص',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'تعداد کارکنان: ${_number(record.employeeCount.toInt())}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(record.totalCost),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowHistorySection extends StatelessWidget {
  final List<CompanyAdminPayrollWorkflowEntry> workflow;

  const _WorkflowHistorySection({
    required this.workflow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'تاریخچه گردش دوره',
          count: workflow.length,
        ),
        const SizedBox(height: 12),
        if (workflow.isEmpty)
          const _EmptyBox(
            text: 'برای این دوره هنوز سابقه‌ای در Workflow ثبت نشده است.',
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xffe5e7eb),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < workflow.length; i++)
                  _WorkflowHistoryItem(
                    entry: workflow[i],
                    isLast: i == workflow.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WorkflowHistoryItem extends StatelessWidget {
  final CompanyAdminPayrollWorkflowEntry entry;
  final bool isLast;

  const _WorkflowHistoryItem({
    required this.entry,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(entry.toStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 55,
                  color: const Color(0xffe5e7eb),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.fromStatusTitle} ← ${entry.toStatusTitle}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                if (entry.note != null &&
                    entry.note!.trim().isNotEmpty)
                  Text(
                    'توضیح: ${entry.note}',
                    style: const TextStyle(
                      color: Color(0xff4b5563),
                      fontSize: 12,
                    ),
                  ),
                if (entry.createdAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _formatDateTime(entry.createdAt!),
                    style: const TextStyle(
                      color: Color(0xff9ca3af),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffe5e7eb),
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff6b7280),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xfffecaca),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xffdc2626),
            size: 52,
          ),
          const SizedBox(height: 15),
          const Text(
            'خطا در دریافت اطلاعات دوره',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff6b7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

final _supabaseClientProvider =
Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Color _statusColor(String status) {
  switch (status) {
    case 'draft':
      return const Color(0xff64748b);

    case 'pending_ceo':
      return const Color(0xffea580c);

    case 'ceo_approved':
      return const Color(0xff2563eb);

    case 'pending_consultant':
      return const Color(0xff7c3aed);

    case 'consultant_approved':
      return const Color(0xff059669);

    case 'rejected':
      return const Color(0xffdc2626);

    case 'paid':
      return const Color(0xff0891b2);

    case 'cancelled':
      return const Color(0xff64748b);

    default:
      return const Color(0xff64748b);
  }
}

String _money(double value) {
  final rounded = value.round().toString();

  return '${_persian(rounded)} ریال';
}

String _number(int value) {
  return _persian(value.toString());
}

String _persian(String value) {
  return value
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹');
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();

  final date =
      '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';

  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

  return _persian('$date - $time');
}