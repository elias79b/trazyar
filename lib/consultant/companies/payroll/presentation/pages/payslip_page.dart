import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/employee_provider.dart';
import '../../data/employee_model.dart';
import '../../data/payroll_period_model.dart';
import '../../data/payroll_record_model.dart';

class PayslipPage extends ConsumerWidget {
  const PayslipPage({
    super.key,
    required this.companyId,
    required this.period,
    required this.record,
  });

  final String companyId;
  final PayrollPeriodModel period;
  final PayrollRecordModel record;

  String get _currentRoute =>
      '/consultant/companies/$companyId/payroll/payslip';

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final employeeAsync = ref.watch(
      employeeProvider(record.employeeId),
    );

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: _currentRoute,
      title: 'فیش حقوقی',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: employeeAsync.when(
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          error: (error, stackTrace) {
            return _ErrorView(
              message: error.toString(),
            );
          },
          data: (employee) {
            if (employee == null) {
              return const _ErrorView(
                message: 'اطلاعات پرسنل پیدا نشد.',
              );
            }

            return _PayslipContent(
              companyId: companyId,
              period: period,
              record: record,
              employee: employee,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// PAYSLIP CONTENT
// ============================================================

class _PayslipContent extends StatelessWidget {
  const _PayslipContent({
    required this.companyId,
    required this.period,
    required this.record,
    required this.employee,
  });

  final String companyId;
  final PayrollPeriodModel period;
  final PayrollRecordModel record;
  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // PAGE HEADER
        // ======================================================

        Row(
          children: [
            IconButton(
              tooltip: 'بازگشت',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'فیش حقوقی',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${employee.fullName} - ${_periodTitle(period)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // PDF
            // ==================================================

            FilledButton.icon(
              onPressed: () async {
                await _printPayslip(context);
              },
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
              ),
              label: const Text(
                'خروجی PDF',
              ),
            ),

            const SizedBox(width: 10),

            // ==================================================
            // PRINT
            // ==================================================

            OutlinedButton.icon(
              onPressed: () async {
                await _printPayslip(context);
              },
              icon: const Icon(
                Icons.print_rounded,
              ),
              label: const Text(
                'چاپ',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ======================================================
        // PREVIEW
        // ======================================================

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 850,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    _PayslipHeader(
                      employee: employee,
                      period: period,
                    ),

                    const SizedBox(height: 22),

                    _EmployeeInformation(
                      employee: employee,
                      record: record,
                    ),

                    const SizedBox(height: 16),

                    _IncomeSection(
                      record: record,
                    ),

                    const SizedBox(height: 14),

                    _DeductionSection(
                      record: record,
                    ),

                    const SizedBox(height: 16),

                    _NetSalaryCard(
                      amount: record.netSalary,
                    ),

                    const SizedBox(height: 24),

                    _Footer(
                      record: record,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PRINT
  // ==========================================================

  Future<void> _printPayslip(
      BuildContext context,
      ) async {
    try {
      await Printing.layoutPdf(
        name:
        'payslip-${employee.personnelCode}-${period.periodYear}-${period.periodMonth}.pdf',
        onLayout: (
            PdfPageFormat format,
            ) async {
          return _generatePdf();
        },
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'خطا در تولید PDF: $error',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // GENERATE PDF
  // ==========================================================

  Future<Uint8List> _generatePdf() async {
    // --------------------------------------------------------
    // LOAD FONTS
    // --------------------------------------------------------

    final regularFontData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Regular.ttf',
    );

    final boldFontData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(
      regularFontData,
    );

    final boldFont = pw.Font.ttf(
      boldFontData,
    );

    // --------------------------------------------------------
    // THEME
    // --------------------------------------------------------

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    final pdf = pw.Document(
      theme: theme,
    );

    // --------------------------------------------------------
    // SINGLE A4 PAGE
    // --------------------------------------------------------

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          28,
          24,
          28,
          24,
        ),
        theme: theme,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.stretch,
              children: [
                // =================================================
                // HEADER
                // =================================================

                pw.Container(
                  height: 72,
                  padding:
                  const pw.EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration:
                  pw.BoxDecoration(
                    color:
                    PdfColor.fromHex(
                      '#1B4332',
                    ),
                    borderRadius:
                    pw.BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          mainAxisAlignment:
                          pw.MainAxisAlignment.center,
                          crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'فیش حقوق و دستمزد',
                              style:
                              pw.TextStyle(
                                color:
                                PdfColors.white,
                                fontSize: 16,
                                fontWeight:
                                pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(
                              height: 4,
                            ),
                            pw.Text(
                              _periodTitle(period),
                              style:
                              const pw.TextStyle(
                                color:
                                PdfColors.white,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.Column(
                        mainAxisAlignment:
                        pw.MainAxisAlignment.center,
                        crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'پرسنل',
                            style:
                            pw.TextStyle(
                              color:
                              PdfColors.white,
                              fontSize: 7,
                            ),
                          ),
                          pw.SizedBox(
                            height: 3,
                          ),
                          pw.Text(
                            employee.fullName,
                            style:
                            pw.TextStyle(
                              color:
                              PdfColors.white,
                              fontSize: 10,
                              fontWeight:
                              pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(
                  height: 9,
                ),

                // =================================================
                // EMPLOYEE INFORMATION
                // =================================================

                _pdfCompactSection(
                  title: 'اطلاعات پرسنل',
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'نام و نام خانوادگی',
                            employee.fullName,
                          ),
                        ),
                        pw.SizedBox(
                          width: 8,
                        ),
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'کد پرسنلی',
                            employee.personnelCode,
                          ),
                        ),
                        pw.SizedBox(
                          width: 8,
                        ),
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'شماره موبایل',
                            employee.mobile ?? '-',
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(
                      height: 6,
                    ),

                    pw.Row(
                      children: [
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'سمت',
                            employee.jobTitle ?? '-',
                          ),
                        ),
                        pw.SizedBox(
                          width: 8,
                        ),
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'واحد',
                            employee.department ?? '-',
                          ),
                        ),
                        pw.SizedBox(
                          width: 8,
                        ),
                        pw.Expanded(
                          child:
                          _pdfCompactInfo(
                            'شناسه فیش',
                            record.id.length >= 8
                                ? record.id
                                .substring(
                              0,
                              8,
                            )
                                : record.id,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(
                  height: 9,
                ),

                // =================================================
                // INCOME
                // =================================================

                _pdfCompactSection(
                  title:
                  'مزایا و دریافتی‌ها',
                  children: [
                    _pdfCompactMoneyRow(
                      'حقوق پایه',
                      record.baseSalary,
                    ),

                    _pdfCompactMoneyRow(
                      'اضافه‌کاری',
                      record.overtimeAmount,
                      subtitle:
                      '${_formatNumber(record.overtimeHours)} ساعت',
                    ),

                    _pdfCompactMoneyRow(
                      'پاداش',
                      record.bonusAmount,
                    ),

                    _pdfCompactMoneyRow(
                      'مزایا',
                      record.allowanceAmount,
                    ),

                    pw.Divider(
                      color:
                      PdfColors.grey400,
                      thickness: .6,
                    ),

                    _pdfCompactMoneyRow(
                      'حقوق ناخالص',
                      record.grossSalary,
                      bold: true,
                    ),
                  ],
                ),

                pw.SizedBox(
                  height: 9,
                ),

                // =================================================
                // DEDUCTIONS
                // =================================================

                _pdfCompactSection(
                  title: 'کسورات',
                  children: [
                    _pdfCompactMoneyRow(
                      'بیمه سهم کارمند',
                      record.employeeInsurance,
                    ),

                    _pdfCompactMoneyRow(
                      'مالیات',
                      record.taxAmount,
                    ),

                    _pdfCompactMoneyRow(
                      'کسری غیبت',
                      record.absenceAmount,
                    ),

                    _pdfCompactMoneyRow(
                      'سایر کسورات',
                      record.otherDeductions,
                    ),

                    _pdfCompactMoneyRow(
                      'علی‌الحساب',
                      record.advanceAmount,
                    ),
                  ],
                ),

                pw.SizedBox(
                  height: 10,
                ),

                // =================================================
                // NET SALARY
                // =================================================

                pw.Container(
                  height: 52,
                  padding:
                  const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration:
                  pw.BoxDecoration(
                    color:
                    PdfColor.fromHex(
                      '#E8F1EC',
                    ),
                    borderRadius:
                    pw.BorderRadius.circular(
                      8,
                    ),
                    border:
                    pw.Border.all(
                      color:
                      PdfColor.fromHex(
                        '#B7CCBF',
                      ),
                      width: .8,
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'حقوق خالص پرداختی',
                          style:
                          pw.TextStyle(
                            fontSize: 12,
                            fontWeight:
                            pw.FontWeight.bold,
                          ),
                        ),
                      ),

                      pw.Text(
                        _formatMoney(
                          record.netSalary,
                        ),
                        style:
                        pw.TextStyle(
                          color:
                          PdfColor.fromHex(
                            '#1B4332',
                          ),
                          fontSize: 13,
                          fontWeight:
                          pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // NOTES
                // =================================================

                if (record.notes != null &&
                    record.notes!
                        .trim()
                        .isNotEmpty) ...[
                  pw.SizedBox(
                    height: 9,
                  ),

                  pw.Container(
                    padding:
                    const pw.EdgeInsets.all(
                      8,
                    ),
                    decoration:
                    pw.BoxDecoration(
                      color:
                      PdfColors.grey100,
                      borderRadius:
                      pw.BorderRadius.circular(
                        6,
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'توضیحات:',
                          style:
                          pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight:
                            pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(
                          width: 5,
                        ),

                        pw.Expanded(
                          child: pw.Text(
                            record.notes!,
                            style:
                            const pw.TextStyle(
                              fontSize: 7.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // =================================================
                // SPACE
                // =================================================

                pw.Spacer(),

                // =================================================
                // FOOTER
                // =================================================

                pw.Divider(
                  color:
                  PdfColors.grey400,
                  thickness: .6,
                ),

                pw.SizedBox(
                  height: 10,
                ),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'امضای کارفرما',
                            style:
                            const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.SizedBox(
                            height: 24,
                          ),
                          pw.Text(
                            '........................',
                            style:
                            const pw.TextStyle(
                              color:
                              PdfColors.grey600,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(
                      width: 40,
                    ),

                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'امضای پرسنل',
                            style:
                            const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                          pw.SizedBox(
                            height: 24,
                          ),
                          pw.Text(
                            '........................',
                            style:
                            const pw.TextStyle(
                              color:
                              PdfColors.grey600,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // ==========================================================
    // RETURN PDF
    // ==========================================================

    final bytes = await pdf.save();

    return Uint8List.fromList(bytes);
  }
}

// ============================================================
// PDF COMPACT SECTION
// ============================================================

pw.Widget _pdfCompactSection({
  required String title,
  required List<pw.Widget> children,
}) {
  return pw.Container(
    padding:
    const pw.EdgeInsets.fromLTRB(
      10,
      8,
      10,
      7,
    ),
    decoration:
    pw.BoxDecoration(
      border:
      pw.Border.all(
        color:
        PdfColors.grey300,
        width: .7,
      ),
      borderRadius:
      pw.BorderRadius.circular(
        7,
      ),
    ),
    child:
    pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title,
          style:
          pw.TextStyle(
            fontSize: 9,
            fontWeight:
            pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(
          height: 6,
        ),

        ...children,
      ],
    ),
  );
}

// ============================================================
// PDF COMPACT INFO
// ============================================================

pw.Widget _pdfCompactInfo(
    String label,
    String value,
    ) {
  return pw.Container(
    height: 27,
    padding:
    const pw.EdgeInsets.symmetric(
      horizontal: 7,
      vertical: 4,
    ),
    decoration:
    pw.BoxDecoration(
      color:
      PdfColors.grey100,
      borderRadius:
      pw.BorderRadius.circular(
        5,
      ),
    ),
    child:
    pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style:
            const pw.TextStyle(
              fontSize: 6.5,
              color:
              PdfColors.grey600,
            ),
          ),
        ),

        pw.SizedBox(
          width: 5,
        ),

        pw.Expanded(
          child: pw.Text(
            value,
            maxLines: 1,
            overflow:
            pw.TextOverflow.clip,
            style:
            pw.TextStyle(
              fontSize: 7.2,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// PDF MONEY ROW
// ============================================================

pw.Widget _pdfCompactMoneyRow(
    String title,
    double amount, {
      String? subtitle,
      bool bold = false,
    }) {
  return pw.Padding(
    padding:
    const pw.EdgeInsets.symmetric(
      vertical: 2.5,
    ),
    child:
    pw.Row(
      children: [
        pw.Expanded(
          child:
          pw.Row(
            children: [
              pw.Text(
                title,
                style:
                pw.TextStyle(
                  fontSize: 8,
                  fontWeight: bold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),

              if (subtitle != null) ...[
                pw.SizedBox(
                  width: 6,
                ),
                pw.Text(
                  subtitle,
                  style:
                  const pw.TextStyle(
                    fontSize: 6.5,
                    color:
                    PdfColors.grey600,
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.Text(
          _formatMoney(amount),
          style:
          pw.TextStyle(
            fontSize: 8,
            fontWeight: bold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// PREVIEW HEADER
// ============================================================

class _PayslipHeader
    extends StatelessWidget {
  const _PayslipHeader({
    required this.employee,
    required this.period,
  });

  final EmployeeModel employee;
  final PayrollPeriodModel period;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFF1B4332),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_rounded,
              color:
              Color(0xFF1B4332),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'فیش حقوق و دستمزد',
                  style:
                  TextStyle(
                    color:
                    Colors.white,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  _periodTitle(period),
                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              const Text(
                'پرسنل',
                style:
                TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                employee.fullName,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPLOYEE INFORMATION
// ============================================================

class _EmployeeInformation
    extends StatelessWidget {
  const _EmployeeInformation({
    required this.employee,
    required this.record,
  });

  final EmployeeModel employee;
  final PayrollRecordModel record;

  @override
  Widget build(
      BuildContext context,
      ) {
    return _Section(
      title:
      'اطلاعات پرسنل',
      icon:
      Icons.person_rounded,
      child:
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics:
        const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 4.4,
        children: [
          _InfoItem(
            label:
            'نام و نام خانوادگی',
            value:
            employee.fullName,
          ),

          _InfoItem(
            label:
            'کد پرسنلی',
            value:
            employee.personnelCode,
          ),

          _InfoItem(
            label:
            'شماره موبایل',
            value:
            employee.mobile ??
                '-',
          ),

          _InfoItem(
            label:
            'سمت',
            value:
            employee.jobTitle ??
                '-',
          ),

          _InfoItem(
            label:
            'واحد',
            value:
            employee.department ??
                '-',
          ),

          _InfoItem(
            label:
            'شناسه فیش',
            value:
            record.id.length >= 8
                ? record.id.substring(
              0,
              8,
            )
                : record.id,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INCOME
// ============================================================

class _IncomeSection
    extends StatelessWidget {
  const _IncomeSection({
    required this.record,
  });

  final PayrollRecordModel record;

  @override
  Widget build(
      BuildContext context,
      ) {
    return _Section(
      title:
      'مزایا و دریافتی‌ها',
      icon:
      Icons.add_circle_outline_rounded,
      child:
      Column(
        children: [
          _MoneyRow(
            title:
            'حقوق پایه',
            amount:
            record.baseSalary,
          ),

          _MoneyRow(
            title:
            'اضافه‌کاری',
            subtitle:
            '${_formatNumber(record.overtimeHours)} ساعت',
            amount:
            record.overtimeAmount,
          ),

          _MoneyRow(
            title:
            'پاداش',
            amount:
            record.bonusAmount,
          ),

          _MoneyRow(
            title:
            'مزایا',
            amount:
            record.allowanceAmount,
          ),

          const Divider(
            height: 20,
          ),

          _MoneyRow(
            title:
            'حقوق ناخالص',
            amount:
            record.grossSalary,
            emphasized:
            true,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DEDUCTIONS
// ============================================================

class _DeductionSection
    extends StatelessWidget {
  const _DeductionSection({
    required this.record,
  });

  final PayrollRecordModel record;

  @override
  Widget build(
      BuildContext context,
      ) {
    return _Section(
      title:
      'کسورات',
      icon:
      Icons.remove_circle_outline_rounded,
      child:
      Column(
        children: [
          _MoneyRow(
            title:
            'بیمه سهم کارمند',
            amount:
            record.employeeInsurance,
          ),

          _MoneyRow(
            title:
            'مالیات',
            amount:
            record.taxAmount,
          ),

          _MoneyRow(
            title:
            'کسری غیبت',
            amount:
            record.absenceAmount,
          ),

          _MoneyRow(
            title:
            'سایر کسورات',
            amount:
            record.otherDeductions,
          ),

          _MoneyRow(
            title:
            'علی‌الحساب',
            amount:
            record.advanceAmount,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NET SALARY
// ============================================================

class _NetSalaryCard
    extends StatelessWidget {
  const _NetSalaryCard({
    required this.amount,
  });

  final double amount;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFF1B4332)
            .withOpacity(.08),
        borderRadius:
        BorderRadius.circular(15),
        border:
        Border.all(
          color:
          const Color(0xFF1B4332)
              .withOpacity(.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFF1B4332),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child:
            const Icon(
              Icons.payments_rounded,
              color:
              Colors.white,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          const Expanded(
            child: Text(
              'حقوق خالص پرداختی',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),

          Text(
            _formatMoney(amount),
            style:
            const TextStyle(
              color:
              Color(0xFF1B4332),
              fontSize: 18,
              fontWeight:
              FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION
// ============================================================

class _Section
    extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(13),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color:
                const Color(
                  0xFF1B4332,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// MONEY ROW
// ============================================================

class _MoneyRow
    extends StatelessWidget {
  const _MoneyRow({
    required this.title,
    required this.amount,
    this.subtitle,
    this.emphasized =
    false,
  });

  final String title;
  final double amount;
  final String? subtitle;
  final bool emphasized;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    emphasized
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    subtitle!,
                    style:
                    TextStyle(
                      color:
                      Colors.grey.shade500,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Text(
            _formatMoney(amount),
            style:
            TextStyle(
              fontSize:
              emphasized
                  ? 12
                  : 11,
              fontWeight:
              emphasized
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ITEM
// ============================================================

class _InfoItem
    extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          9,
        ),
      ),
      child:
      Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 8,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

class _Footer
    extends StatelessWidget {
  const _Footer({
    required this.record,
  });

  final PayrollRecordModel record;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        if (record.notes != null &&
            record.notes!
                .trim()
                .isNotEmpty) ...[
          const Text(
            'توضیحات',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w900,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            record.notes!,
            style:
            const TextStyle(
              fontSize: 10,
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],

        const Divider(),

        const SizedBox(
          height: 15,
        ),

        Row(
          children: [
            const Expanded(
              child: Column(
                children: [
                  Text(
                    'امضای کارفرما',
                    style:
                    TextStyle(
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  SizedBox(
                    height: 35,
                  ),

                  Text(
                    '........................',
                    style:
                    TextStyle(
                      color:
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 30,
            ),

            const Expanded(
              child: Column(
                children: [
                  Text(
                    'امضای پرسنل',
                    style:
                    TextStyle(
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  SizedBox(
                    height: 35,
                  ),

                  Text(
                    '........................',
                    style:
                    TextStyle(
                      color:
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// ERROR VIEW
// ============================================================

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child:
      Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .error_outline_rounded,
            size: 55,
            color:
            Colors.red.shade700,
          ),

          const SizedBox(
            height: 12,
          ),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child:
            Text(
              message,
              textAlign:
              TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PERIOD TITLE
// ============================================================

String _periodTitle(
    PayrollPeriodModel period,
    ) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (period.periodMonth < 1 ||
      period.periodMonth > 12) {
    return period.periodYear
        .toString();
  }

  return '${months[period.periodMonth - 1]} ${period.periodYear}';
}

// ============================================================
// FORMAT MONEY
// ============================================================

String _formatMoney(
    double value,
    ) {
  final number = value.round();

  final isNegative = number < 0;

  final digits = number
      .abs()
      .toString();

  final groups = <String>[];

  var end = digits.length;

  while (end > 0) {
    final start =
    end - 3 < 0
        ? 0
        : end - 3;

    groups.insert(
      0,
      digits.substring(
        start,
        end,
      ),
    );

    end = start;
  }

  final formatted =
  groups.join(',');

  if (isNegative) {
    return '-$formatted تومان';
  }

  return '$formatted تومان';
}

// ============================================================
// FORMAT NUMBER
// ============================================================

String _formatNumber(
    double value,
    ) {
  if (value ==
      value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toString();
}