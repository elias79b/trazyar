// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shamsi_date/shamsi_date.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../../data/employment_contract_model.dart';
//
// class EmploymentContractFormDialog extends ConsumerStatefulWidget {
//   const EmploymentContractFormDialog({
//     super.key,
//     required this.companyId,
//     this.contract,
//   });
//
//   final String companyId;
//   final EmploymentContractModel? contract;
//
//   bool get isEdit => contract != null;
//
//   @override
//   ConsumerState<EmploymentContractFormDialog> createState() =>
//       _EmploymentContractFormDialogState();
// }
//
// class _EmploymentContractFormDialogState
//     extends ConsumerState<EmploymentContractFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//
//   late final TextEditingController _contractNumberController;
//   late final TextEditingController _startDateController;
//   late final TextEditingController _endDateController;
//
//   String? _selectedCostCenterId;
//
//   late String _contractType;
//   late String _status;
//
//   DateTime? _startDate;
//   DateTime? _endDate;
//
//   bool _saving = false;
//
//   static const List<String> _contractTypes = [
//     'permanent',
//     'temporary',
//     'contract',
//     'probation',
//     'internship',
//   ];
//
//   static const List<String> _statuses = [
//     'active',
//     'expired',
//     'terminated',
//     'cancelled',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     final contract = widget.contract;
//
//     _contractNumberController = TextEditingController(
//       text: contract?.contractNumber ?? '',
//     );
//
//     _startDate = contract?.startDate;
//     _endDate = contract?.endDate;
//
//     _startDateController = TextEditingController(
//       text: _startDate == null ? '' : _formatShamsiDate(_startDate!),
//     );
//
//     _endDateController = TextEditingController(
//       text: _endDate == null ? '' : _formatShamsiDate(_endDate!),
//     );
//
//     _selectedCostCenterId = contract?.costCenterId;
//
//     _contractType = contract?.contractType ?? 'permanent';
//     _status = contract?.status ?? 'active';
//   }
//
//   @override
//   void dispose() {
//     _contractNumberController.dispose();
//     _startDateController.dispose();
//     _endDateController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: AlertDialog(
//         title: Text(
//           widget.isEdit ? 'ویرایش قرارداد' : 'ثبت قرارداد',
//           style: const TextStyle(fontWeight: FontWeight.w900),
//         ),
//         content: SizedBox(
//           width: 650,
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildCostCenterField(),
//
//                   _buildTextField(
//                     controller: _contractNumberController,
//                     label: 'شماره قرارداد',
//                   ),
//
//                   _buildContractTypeField(),
//
//                   _buildShamsiDateField(
//                     controller: _startDateController,
//                     label: 'تاریخ شروع',
//                     selectedDate: _startDate,
//                     onDateSelected: (date) {
//                       setState(() {
//                         _startDate = date;
//                         _startDateController.text = _formatShamsiDate(date);
//                       });
//                     },
//                   ),
//
//                   _buildShamsiDateField(
//                     controller: _endDateController,
//                     label: 'تاریخ پایان',
//                     selectedDate: _endDate,
//                     onDateSelected: (date) {
//                       setState(() {
//                         _endDate = date;
//                         _endDateController.text = _formatShamsiDate(date);
//                       });
//                     },
//                   ),
//
//                   _buildStatusField(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed:
//                 _saving
//                     ? null
//                     : () {
//                       Navigator.of(context).pop(false);
//                     },
//             child: const Text('انصراف'),
//           ),
//           FilledButton.icon(
//             onPressed: _saving ? null : _save,
//             icon:
//                 _saving
//                     ? const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                     : const Icon(Icons.save_rounded),
//             label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت قرارداد'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // COST CENTER
//   // ==========================================================
//
//   Widget _buildCostCenterField() {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _fetchCostCenters(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Padding(
//             padding: EdgeInsets.only(bottom: 14),
//             child: InputDecorator(
//               decoration: InputDecoration(
//                 labelText: 'مرکز هزینه',
//                 border: OutlineInputBorder(),
//               ),
//               child: Row(
//                 children: [
//                   SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   SizedBox(width: 10),
//                   Text('در حال دریافت مراکز هزینه...'),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         if (snapshot.hasError) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 14),
//             child: InputDecorator(
//               decoration: const InputDecoration(
//                 labelText: 'مرکز هزینه',
//                 border: OutlineInputBorder(),
//               ),
//               child: Text(
//                 'دریافت مراکز هزینه ناموفق بود.',
//                 style: TextStyle(color: Colors.red.shade700, fontSize: 11),
//               ),
//             ),
//           );
//         }
//
//         final centers = snapshot.data ?? [];
//
//         if (centers.isEmpty) {
//           return const Padding(
//             padding: EdgeInsets.only(bottom: 14),
//             child: InputDecorator(
//               decoration: InputDecoration(
//                 labelText: 'مرکز هزینه',
//                 border: OutlineInputBorder(),
//               ),
//               child: Text('ابتدا حداقل یک مرکز هزینه ثبت کنید.'),
//             ),
//           );
//         }
//
//         final selectedExists = centers.any(
//           (item) => item['id']?.toString() == _selectedCostCenterId,
//         );
//
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 14),
//           child: DropdownButtonFormField<String>(
//             value: selectedExists ? _selectedCostCenterId : null,
//             isExpanded: true,
//             decoration: const InputDecoration(
//               labelText: 'مرکز هزینه *',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.account_tree_rounded),
//             ),
//             items:
//                 centers.map((center) {
//                   final id = center['id'].toString();
//                   final name = (center['name'] ?? 'بدون نام').toString();
//                   final code = center['code']?.toString();
//
//                   return DropdownMenuItem<String>(
//                     value: id,
//                     child: Text(
//                       code == null || code.trim().isEmpty
//                           ? name
//                           : '$code - $name',
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   );
//                 }).toList(),
//             onChanged:
//                 _saving
//                     ? null
//                     : (value) {
//                       setState(() {
//                         _selectedCostCenterId = value;
//                       });
//                     },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'مرکز هزینه را انتخاب کنید.';
//               }
//
//               return null;
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Future<List<Map<String, dynamic>>> _fetchCostCenters() async {
//     final response = await Supabase.instance.client
//         .from('cost_centers')
//         .select('id, name, code, description, is_active')
//         .eq('company_id', widget.companyId)
//         .eq('is_active', true)
//         .order('name', ascending: true);
//
//     return (response as List)
//         .map((row) => Map<String, dynamic>.from(row))
//         .toList();
//   }
//
//   // ==========================================================
//   // CONTRACT NUMBER
//   // ==========================================================
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextFormField(
//         controller: controller,
//         enabled: !_saving,
//         textDirection: TextDirection.rtl,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // CONTRACT TYPE
//   // ==========================================================
//
//   Widget _buildContractTypeField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: DropdownButtonFormField<String>(
//         value: _contractType,
//         isExpanded: true,
//         decoration: const InputDecoration(
//           labelText: 'نوع قرارداد',
//           border: OutlineInputBorder(),
//         ),
//         items:
//             _contractTypes.map((value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(_contractTypeTitle(value)),
//               );
//             }).toList(),
//         onChanged:
//             _saving
//                 ? null
//                 : (value) {
//                   if (value == null) return;
//
//                   setState(() {
//                     _contractType = value;
//                   });
//                 },
//       ),
//     );
//   }
//
//   // ==========================================================
//   // SHAMSI DATE
//   // ==========================================================
//
//   Widget _buildShamsiDateField({
//     required TextEditingController controller,
//     required String label,
//     required DateTime? selectedDate,
//     required ValueChanged<DateTime> onDateSelected,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextFormField(
//         controller: controller,
//         readOnly: true,
//         enabled: !_saving,
//         textDirection: TextDirection.rtl,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           prefixIcon: const Icon(Icons.calendar_month_rounded),
//           suffixIcon:
//               controller.text.isEmpty
//                   ? null
//                   : IconButton(
//                     tooltip: 'پاک کردن تاریخ',
//                     onPressed:
//                         _saving
//                             ? null
//                             : () {
//                               setState(() {
//                                 controller.clear();
//
//                                 if (label == 'تاریخ شروع') {
//                                   _startDate = null;
//                                 } else {
//                                   _endDate = null;
//                                 }
//                               });
//                             },
//                     icon: const Icon(Icons.clear_rounded),
//                   ),
//         ),
//         onTap:
//             _saving
//                 ? null
//                 : () async {
//                   final date = await _showPersianDatePicker(
//                     context: context,
//                     initialDate: selectedDate ?? DateTime.now(),
//                   );
//
//                   if (date == null) {
//                     return;
//                   }
//
//                   onDateSelected(date);
//                 },
//       ),
//     );
//   }
//
//   Future<DateTime?> _showPersianDatePicker({
//     required BuildContext context,
//     required DateTime initialDate,
//   }) async {
//     final initialJalali = Jalali.fromDateTime(initialDate);
//
//     final firstJalali = Jalali(1400, 1, 1);
//
//     final lastJalali = Jalali(1500, 12, 29);
//
//     Jalali selected = initialJalali;
//
//     final result = await showDialog<Jalali>(
//       context: context,
//       builder: (dialogContext) {
//         return Directionality(
//           textDirection: TextDirection.rtl,
//           child: AlertDialog(
//             title: const Text('انتخاب تاریخ'),
//             content: StatefulBuilder(
//               builder: (context, setState) {
//                 return SizedBox(
//                   width: 340,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: DropdownButtonFormField<int>(
//                               value: selected.year,
//                               decoration: const InputDecoration(
//                                 labelText: 'سال',
//                                 border: OutlineInputBorder(),
//                               ),
//                               items: List.generate(100, (index) {
//                                 final year = 1400 + index;
//
//                                 return DropdownMenuItem<int>(
//                                   value: year,
//                                   child: Text(
//                                     _toPersianDigits(year.toString()),
//                                   ),
//                                 );
//                               }),
//                               onChanged: (year) {
//                                 if (year == null) return;
//
//                                 final maxDay =
//                                     Jalali(year, selected.month, 1).monthLength;
//
//                                 final day =
//                                     selected.day > maxDay
//                                         ? maxDay
//                                         : selected.day;
//
//                                 setState(() {
//                                   selected = Jalali(year, selected.month, day);
//                                 });
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: DropdownButtonFormField<int>(
//                               value: selected.month,
//                               decoration: const InputDecoration(
//                                 labelText: 'ماه',
//                                 border: OutlineInputBorder(),
//                               ),
//                               items: List.generate(12, (index) {
//                                 final month = index + 1;
//
//                                 return DropdownMenuItem<int>(
//                                   value: month,
//                                   child: Text(_persianMonthName(month)),
//                                 );
//                               }),
//                               onChanged: (month) {
//                                 if (month == null) {
//                                   return;
//                                 }
//
//                                 final maxDay =
//                                     Jalali(selected.year, month, 1).monthLength;
//
//                                 final day =
//                                     selected.day > maxDay
//                                         ? maxDay
//                                         : selected.day;
//
//                                 setState(() {
//                                   selected = Jalali(selected.year, month, day);
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 14),
//                       DropdownButtonFormField<int>(
//                         value: selected.day,
//                         decoration: const InputDecoration(
//                           labelText: 'روز',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: List.generate(selected.monthLength, (index) {
//                           final day = index + 1;
//
//                           return DropdownMenuItem<int>(
//                             value: day,
//                             child: Text(_toPersianDigits(day.toString())),
//                           );
//                         }),
//                         onChanged: (day) {
//                           if (day == null) {
//                             return;
//                           }
//
//                           setState(() {
//                             selected = Jalali(
//                               selected.year,
//                               selected.month,
//                               day,
//                             );
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(dialogContext);
//                 },
//                 child: const Text('انصراف'),
//               ),
//               FilledButton(
//                 onPressed: () {
//                   Navigator.pop(dialogContext, selected);
//                 },
//                 child: const Text('تأیید'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//
//     if (result == null) {
//       return null;
//     }
//
//     return result.toDateTime();
//   }
//
//   // ==========================================================
//   // STATUS
//   // ==========================================================
//
//   Widget _buildStatusField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: DropdownButtonFormField<String>(
//         value: _status,
//         isExpanded: true,
//         decoration: const InputDecoration(
//           labelText: 'وضعیت قرارداد',
//           border: OutlineInputBorder(),
//           prefixIcon: Icon(Icons.toggle_on_rounded),
//         ),
//         items:
//             _statuses.map((value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(_statusTitle(value)),
//               );
//             }).toList(),
//         onChanged:
//             _saving
//                 ? null
//                 : (value) {
//                   if (value == null) return;
//
//                   setState(() {
//                     _status = value;
//                   });
//                 },
//       ),
//     );
//   }
//
//   // ==========================================================
//   // SAVE
//   // ==========================================================
//
//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     if (_selectedCostCenterId == null || _selectedCostCenterId!.isEmpty) {
//       _showError('مرکز هزینه را انتخاب کنید.');
//       return;
//     }
//
//     if (_startDate != null &&
//         _endDate != null &&
//         _endDate!.isBefore(_startDate!)) {
//       _showError('تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.');
//       return;
//     }
//
//     setState(() {
//       _saving = true;
//     });
//
//     try {
//       final client = Supabase.instance.client;
//
//       final user = client.auth.currentUser;
//
//       if (user == null) {
//         throw Exception('کاربر وارد نشده است.');
//       }
//
//       final data = <String, dynamic>{
//         'cost_center_id': _selectedCostCenterId,
//         'contract_number': _nullable(_contractNumberController.text),
//         'contract_type': _contractType,
//         'start_date': _dateForDatabase(_startDate),
//         'end_date': _dateForDatabase(_endDate),
//         'status': _status,
//       };
//
//       if (widget.isEdit) {
//         await client
//             .from('employment_contracts')
//             .update(data)
//             .eq('id', widget.contract!.id);
//       } else {
//         await client.from('employment_contracts').insert({
//           ...data,
//           'company_id': widget.companyId,
//           'employee_id': null,
//           'base_salary': 0,
//           'working_hours': null,
//           'created_by': user.id,
//         });
//       }
//
//       if (!mounted) {
//         return;
//       }
//
//       Navigator.of(context).pop(true);
//     } catch (error) {
//       if (!mounted) {
//         return;
//       }
//
//       _showError(_cleanError(error));
//     } finally {
//       if (mounted) {
//         setState(() {
//           _saving = false;
//         });
//       }
//     }
//   }
//
//   // ==========================================================
//   // HELPERS
//   // ==========================================================
//
//   String? _nullable(String value) {
//     final result = value.trim();
//
//     return result.isEmpty ? null : result;
//   }
//
//   String? _dateForDatabase(DateTime? value) {
//     if (value == null) {
//       return null;
//     }
//
//     return value.toIso8601String().split('T').first;
//   }
//
//   String _formatShamsiDate(DateTime value) {
//     final jalali = Jalali.fromDateTime(value);
//
//     return '${_toPersianDigits(jalali.year.toString())}/'
//         '${_toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/'
//         '${_toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
//   }
//
//   String _toPersianDigits(String value) {
//     const english = '0123456789';
//
//     const persian = '۰۱۲۳۴۵۶۷۸۹';
//
//     var result = value;
//
//     for (var i = 0; i < english.length; i++) {
//       result = result.replaceAll(english[i], persian[i]);
//     }
//
//     return result;
//   }
//
//   String _persianMonthName(int month) {
//     const months = [
//       'فروردین',
//       'اردیبهشت',
//       'خرداد',
//       'تیر',
//       'مرداد',
//       'شهریور',
//       'مهر',
//       'آبان',
//       'آذر',
//       'دی',
//       'بهمن',
//       'اسفند',
//     ];
//
//     return months[month - 1];
//   }
//
//   String _contractTypeTitle(String value) {
//     switch (value) {
//       case 'permanent':
//         return 'دائم';
//       case 'temporary':
//         return 'موقت';
//       case 'contract':
//         return 'قراردادی';
//       case 'probation':
//         return 'آزمایشی';
//       case 'internship':
//         return 'کارآموزی';
//       default:
//         return value;
//     }
//   }
//
//   String _statusTitle(String value) {
//     switch (value) {
//       case 'active':
//         return 'فعال';
//       case 'expired':
//         return 'منقضی';
//       case 'terminated':
//         return 'خاتمه‌یافته';
//       case 'cancelled':
//         return 'لغوشده';
//       default:
//         return value;
//     }
//   }
//
//   String _cleanError(Object error) {
//     final text = error.toString();
//
//     if (text.startsWith('Exception: ')) {
//       return text.substring('Exception: '.length);
//     }
//
//     return text;
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/shared/presentation/widgets/persian_date_field.dart';

import '../../application/employee_provider.dart';
import '../../data/employee_model.dart';
import '../../data/employment_contract_model.dart';

class EmploymentContractFormDialog extends ConsumerStatefulWidget {
  const EmploymentContractFormDialog({
    super.key,
    required this.companyId,
    this.contract,
  });

  final String companyId;
  final EmploymentContractModel? contract;

  bool get isEdit => contract != null;

  @override
  ConsumerState<EmploymentContractFormDialog> createState() =>
      _EmploymentContractFormDialogState();
}

class _EmploymentContractFormDialogState
    extends ConsumerState<EmploymentContractFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _client => Supabase.instance.client;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _contractNumberController;

  late final TextEditingController _startDateController;

  late final TextEditingController _endDateController;

  late final TextEditingController _baseSalaryController;

  // ============================================================
  // SELECTIONS
  // ============================================================

  String? _selectedEmployeeId;

  String? _selectedCostCenterId;

  late String _contractType;

  late String _status;

  // ============================================================
  // DATES
  // ============================================================

  DateTime? _startDate;

  DateTime? _endDate;

  // ============================================================
  // STATE
  // ============================================================

  bool _saving = false;

  bool _loadingCostCenters = true;

  String? _costCenterError;

  List<Map<String, dynamic>> _costCenters = [];

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const List<String> _contractTypes = [
    'permanent',
    'temporary',
    'contract',
    'probation',
    'internship',
  ];

  static const List<String> _contractStatuses = [
    'active',
    'expired',
    'terminated',
    'cancelled',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final contract = widget.contract;

    // ----------------------------------------------------------
    // Contract number
    // ----------------------------------------------------------

    _contractNumberController = TextEditingController(
      text: contract?.contractNumber ?? '',
    );

    // ----------------------------------------------------------
    // Dates
    // ----------------------------------------------------------

    _startDate = contract?.startDate;

    _endDate = contract?.endDate;

    _startDateController = TextEditingController(
      text: _startDate == null ? '' : _formatShamsiDate(_startDate!),
    );

    _endDateController = TextEditingController(
      text: _endDate == null ? '' : _formatShamsiDate(_endDate!),
    );

    // ----------------------------------------------------------
    // Salary
    // ----------------------------------------------------------

    _baseSalaryController = TextEditingController(
      text: contract == null ? '' : _formatMoney(contract.baseSalary),
    );

    // ----------------------------------------------------------
    // Contract type
    // ----------------------------------------------------------

    _contractType =
        _contractTypes.contains(contract?.contractType)
            ? contract!.contractType
            : 'permanent';

    // ----------------------------------------------------------
    // Status
    // ----------------------------------------------------------

    _status =
        _contractStatuses.contains(contract?.status)
            ? contract!.status
            : 'active';

    // ----------------------------------------------------------
    // Employee
    // ----------------------------------------------------------

    _selectedEmployeeId = contract?.employeeId;

    // ----------------------------------------------------------
    // Cost Center
    // ----------------------------------------------------------

    _selectedCostCenterId = contract?.costCenterId;

    // ----------------------------------------------------------
    // Load cost centers
    // ----------------------------------------------------------

    _loadCostCenters();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _contractNumberController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _baseSalaryController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider(widget.companyId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.isEdit ? 'ویرایش قرارداد' : 'ثبت قرارداد',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),

        content: SizedBox(
          width: 700,

          child: SingleChildScrollView(
            child: Form(
              key: _formKey,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // COST CENTER
                  // ==================================================
                  _buildCostCenterField(),

                  // ==================================================
                  // EMPLOYEE
                  // ==================================================
                  _buildEmployeeField(employeesAsync),

                  // ==================================================
                  // CONTRACT NUMBER
                  // ==================================================
                  _textField(
                    controller: _contractNumberController,
                    label: 'شماره قرارداد',
                    requiredField: false,
                    icon: Icons.numbers_rounded,
                  ),

                  // ==================================================
                  // CONTRACT TYPE
                  // ==================================================
                  _dropdownField<String>(
                    label: 'نوع قرارداد',
                    value: _contractType,
                    items: _contractTypes,
                    titleBuilder: _contractTypeTitle,
                    onChanged:
                        _saving
                            ? null
                            : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _contractType = value;
                              });
                            },
                  ),

                  // ==================================================
                  // START DATE
                  // ==================================================
                  PersianDateField(
                    controller: _startDateController,
                    label: 'تاریخ شروع',
                    initialDate: _startDate,
                    requiredField: false,
                    onDateSelected: (date) {
                      setState(() {
                        _startDate = date;
                      });
                    },
                  ),

                  // ==================================================
                  // END DATE
                  // ==================================================
                  PersianDateField(
                    controller: _endDateController,
                    label: 'تاریخ پایان',
                    initialDate: _endDate,
                    requiredField: false,
                    onDateSelected: (date) {
                      setState(() {
                        _endDate = date;
                      });
                    },
                  ),

                  // ==================================================
                  // BASE SALARY
                  // ==================================================
                  _numberField(
                    controller: _baseSalaryController,
                    label: 'حقوق پایه',
                  ),

                  // ==================================================
                  // STATUS
                  // ==================================================
                  _dropdownField<String>(
                    label: 'وضعیت قرارداد',
                    value: _status,
                    items: _contractStatuses,
                    titleBuilder: _statusTitle,
                    onChanged:
                        _saving
                            ? null
                            : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _status = value;
                              });
                            },
                  ),
                ],
              ),
            ),
          ),
        ),

        // ==========================================================
        // ACTIONS
        // ==========================================================
        actions: [
          TextButton(
            onPressed:
                _saving
                    ? null
                    : () {
                      Navigator.of(context).pop(false);
                    },
            child: const Text('انصراف'),
          ),

          FilledButton.icon(
            onPressed: _saving ? null : _save,

            icon:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.save_rounded),

            label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت قرارداد'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COST CENTER
  // ============================================================

  Widget _buildCostCenterField() {
    if (_loadingCostCenters) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'مرکز هزینه *',
            border: OutlineInputBorder(),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('در حال دریافت مراکز هزینه...'),
            ],
          ),
        ),
      );
    }

    if (_costCenterError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'مرکز هزینه *',
            border: OutlineInputBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _costCenterError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving ? null : _loadCostCenters,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تلاش مجدد'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_costCenters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'مرکز هزینه *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_tree_rounded),
          ),
          child: const Text(
            'برای ثبت قرارداد ابتدا یک مرکز هزینه فعال ایجاد کنید.',
          ),
        ),
      );
    }

    final selectedExists = _costCenters.any(
      (center) => center['id']?.toString() == _selectedCostCenterId,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: selectedExists ? _selectedCostCenterId : null,

        isExpanded: true,

        decoration: const InputDecoration(
          labelText: 'مرکز هزینه *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.account_tree_rounded),
        ),

        items:
            _costCenters.map((center) {
              final id = center['id']?.toString() ?? '';

              final name = center['name']?.toString() ?? '';

              final code = center['code']?.toString().trim();

              final title =
                  code == null || code.isEmpty ? name : '$code - $name';

              return DropdownMenuItem<String>(
                value: id,
                child: Text(title, overflow: TextOverflow.ellipsis),
              );
            }).toList(),

        onChanged:
            _saving
                ? null
                : (value) {
                  setState(() {
                    _selectedCostCenterId = value;
                  });
                },

        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'مرکز هزینه را انتخاب کنید.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // LOAD COST CENTERS
  // ============================================================

  Future<void> _loadCostCenters() async {
    if (mounted) {
      setState(() {
        _loadingCostCenters = true;
        _costCenterError = null;
      });
    }

    try {
      final response = await _client
          .from('cost_centers')
          .select('id, name, code, is_active')
          .eq('company_id', widget.companyId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final centers =
          (response as List)
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _costCenters = centers;

        _loadingCostCenters = false;

        final selectedStillExists = centers.any(
          (center) => center['id']?.toString() == _selectedCostCenterId,
        );

        if (!selectedStillExists) {
          _selectedCostCenterId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingCostCenters = false;

        _costCenterError = _cleanError(error);
      });
    }
  }

  // ============================================================
  // EMPLOYEE
  // ============================================================

  Widget _buildEmployeeField(AsyncValue<List<EmployeeModel>> employeesAsync) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: employeesAsync.when(
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------
        loading: () {
          return const InputDecorator(
            decoration: InputDecoration(
              labelText: 'پرسنل *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('در حال دریافت پرسنل...'),
              ],
            ),
          );
        },

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------
        error: (error, stackTrace) {
          return InputDecorator(
            decoration: const InputDecoration(
              labelText: 'پرسنل *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'دریافت لیست پرسنل ناموفق بود.',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        _saving
                            ? null
                            : () {
                              ref.invalidate(
                                employeesProvider(widget.companyId),
                              );
                            },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تلاش مجدد'),
                  ),
                ),
              ],
            ),
          );
        },

        // --------------------------------------------------------
        // DATA
        // --------------------------------------------------------
        data: (employees) {
          if (employees.isEmpty) {
            return const InputDecorator(
              decoration: InputDecoration(
                labelText: 'پرسنل *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              child: Text('ابتدا حداقل یک پرسنل ثبت کنید.'),
            );
          }

          final employeeExists = employees.any(
            (employee) => employee.id == _selectedEmployeeId,
          );

          final selectedValue = employeeExists ? _selectedEmployeeId : null;

          return DropdownButtonFormField<String>(
            value: selectedValue,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'پرسنل *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),

            items:
                employees.map((employee) {
                  return DropdownMenuItem<String>(
                    value: employee.id,

                    child: Text(
                      '${employee.personnelCode} - ${employee.fullName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),

            onChanged:
                _saving
                    ? null
                    : (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
                    },

            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'پرسنل را انتخاب کنید.';
              }

              return null;
            },

            hint: const Text('انتخاب پرسنل'),
          );
        },
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required bool requiredField,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,

        enabled: !_saving,

        textDirection: TextDirection.rtl,

        decoration: InputDecoration(
          labelText: label,

          border: const OutlineInputBorder(),

          prefixIcon: icon == null ? null : Icon(icon),
        ),

        validator: (value) {
          if (!requiredField) {
            return null;
          }

          if (value == null || value.trim().isEmpty) {
            return 'این فیلد الزامی است.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,

        enabled: !_saving,

        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),

        textDirection: TextDirection.ltr,

        inputFormatters: const [_ThousandsSeparatorFormatter()],

        decoration: InputDecoration(
          labelText: label,

          suffixText: 'ریال',

          border: const OutlineInputBorder(),

          prefixIcon: const Icon(Icons.payments_outlined),
        ),

        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'حقوق پایه را وارد کنید.';
          }

          final number = _parseDouble(value);

          if (number == null || number < 0) {
            return 'مبلغ معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) titleBuilder,
    required ValueChanged<T?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,

        isExpanded: true,

        decoration: InputDecoration(
          labelText: label,

          border: const OutlineInputBorder(),
        ),

        items:
            items.map((item) {
              return DropdownMenuItem<T>(
                value: item,

                child: Text(titleBuilder(item)),
              );
            }).toList(),

        onChanged: onChanged,
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // EMPLOYEE
    // ----------------------------------------------------------

    if (_selectedEmployeeId == null || _selectedEmployeeId!.isEmpty) {
      _showMessage('پرسنل را انتخاب کنید.');
      return;
    }

    // ----------------------------------------------------------
    // COST CENTER
    // ----------------------------------------------------------

    if (_selectedCostCenterId == null || _selectedCostCenterId!.isEmpty) {
      _showMessage('مرکز هزینه را انتخاب کنید.');
      return;
    }

    // ----------------------------------------------------------
    // DATE VALIDATION
    // ----------------------------------------------------------

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _showMessage('تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.');
      return;
    }

    // ----------------------------------------------------------
    // SALARY
    // ----------------------------------------------------------

    final baseSalary = _parseDouble(_baseSalaryController.text) ?? 0;

    if (baseSalary < 0) {
      _showMessage('حقوق پایه نمی‌تواند منفی باشد.');
      return;
    }

    // ----------------------------------------------------------
    // AUTH
    // ----------------------------------------------------------

    final user = _client.auth.currentUser;

    if (user == null) {
      _showMessage('کاربر وارد نشده است.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // ========================================================
      // DATA
      // ========================================================

      final data = <String, dynamic>{
        'employee_id': _selectedEmployeeId,

        'cost_center_id': _selectedCostCenterId,

        'contract_number': _nullable(_contractNumberController.text),

        'contract_type': _contractType,

        'start_date': _dateForDatabase(_startDate),

        'end_date': _dateForDatabase(_endDate),

        'base_salary': baseSalary,

        'status': _status,
      };

      // ========================================================
      // UPDATE
      // ========================================================

      if (widget.isEdit) {
        await _client
            .from('employment_contracts')
            .update(data)
            .eq('id', widget.contract!.id);
      }
      // ========================================================
      // CREATE
      // ========================================================
      else {
        await _client.from('employment_contracts').insert({
          ...data,

          'company_id': widget.companyId,

          'created_by': user.id,
        });
      }

      if (!mounted) {
        return;
      }

      // ========================================================
      // CLOSE
      // ========================================================

      Navigator.of(context).pop(true);

      // ========================================================
      // MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'قرارداد با موفقیت ویرایش شد.'
                : 'قرارداد با موفقیت ثبت شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          content: Text(_cleanError(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullable(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // DATABASE DATE
  // ============================================================

  String? _dateForDatabase(DateTime? date) {
    if (date == null) {
      return null;
    }

    return date.toIso8601String().split('T').first;
  }

  // ============================================================
  // CONTRACT TYPE TITLE
  // ============================================================

  String _contractTypeTitle(String value) {
    switch (value) {
      case 'permanent':
        return 'دائم';

      case 'temporary':
        return 'موقت';

      case 'contract':
        return 'قراردادی';

      case 'probation':
        return 'آزمایشی';

      case 'internship':
        return 'کارآموزی';

      default:
        return value;
    }
  }

  // ============================================================
  // STATUS TITLE
  // ============================================================

  String _statusTitle(String value) {
    switch (value) {
      case 'active':
        return 'فعال';

      case 'expired':
        return 'منقضی';

      case 'terminated':
        return 'خاتمه‌یافته';

      case 'cancelled':
        return 'لغوشده';

      default:
        return value;
    }
  }

  // ============================================================
  // PARSE NUMBER
  // ============================================================

  double? _parseDouble(String value) {
    var normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    const persian = '۰۱۲۳۴۵۶۷۸۹';

    const arabic = '٠١٢٣٤٥٦٧٨٩';

    const english = '0123456789';

    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(persian[i], english[i]);

      normalized = normalized.replaceAll(arabic[i], english[i]);
    }

    normalized = normalized.replaceAll(',', '');

    return double.tryParse(normalized);
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(double value) {
    final integer = value.round().toString();

    final buffer = StringBuffer();

    for (var i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(integer[i]);
    }

    return buffer.toString();
  }

  // ============================================================
  // FORMAT SHAMSI DATE
  // ============================================================

  String _formatShamsiDate(DateTime value) {
    final jalali = Jalali.fromDateTime(value);

    return '${_fa(jalali.year.toString())}/'
        '${_fa(jalali.month.toString().padLeft(2, '0'))}/'
        '${_fa(jalali.day.toString().padLeft(2, '0'))}';
  }

  // ============================================================
  // PERSIAN DIGITS
  // ============================================================

  String _fa(String value) {
    const english = '0123456789';

    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }
}

// ================================================================
// THOUSANDS SEPARATOR
// ================================================================

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  const _ThousandsSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var normalized = newValue.text;

    normalized = normalized
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll(',', '');

    if (normalized.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final clean = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.isEmpty) {
      return oldValue;
    }

    final buffer = StringBuffer();

    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(clean[i]);
    }

    final result = buffer.toString();

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
      composing: TextRange.empty,
    );
  }
}
