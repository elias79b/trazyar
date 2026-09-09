import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../data/cost_center_repository.dart';

class CostCentersPage extends ConsumerStatefulWidget {
  const CostCentersPage({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<CostCentersPage> createState() => _CostCentersPageState();
}

class _CostCentersPageState extends ConsumerState<CostCentersPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;

  String _search = '';

  SupabaseClient get _client => Supabase.instance.client;

  CostCenterRepository get _repository => CostCenterRepository(client: _client);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadCostCenters();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD COST CENTERS
  // ============================================================

  Future<void> _loadCostCenters() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final response = await _client
          .from('cost_centers')
          .select()
          .eq('company_id', widget.companyId)
          .order('created_at', ascending: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (response as List)
                .map((row) => Map<String, dynamic>.from(row))
                .toList();

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredItems {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';

      final code = item['code']?.toString().toLowerCase() ?? '';

      final description = item['description']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          code.contains(query) ||
          description.contains(query);
    }).toList();
  }

  // ============================================================
  // OPEN FORM
  // ============================================================

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _CostCenterFormDialog(companyId: widget.companyId, item: item);
      },
    );

    if (result == true) {
      await _loadCostCenters();
    }
  }

  // ============================================================
  // DELETE COST CENTER
  // ============================================================

  Future<void> _deleteCostCenter(Map<String, dynamic> item) async {
    final id = item['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final name = item['name']?.toString() ?? '-';

    try {
      // ==========================================================
      // STEP 1
      // بررسی وابستگی‌ها
      // ==========================================================

      final dependencies = await _repository.getDeleteDependencies(id);

      if (!mounted) {
        return;
      }

      // ==========================================================
      // STEP 2
      // اگر وابستگی وجود دارد
      // ==========================================================

      if (dependencies.hasDependencies) {
        await _showDependencyDialog(name: name, dependencies: dependencies);

        return;
      }

      // ==========================================================
      // STEP 3
      // تأیید نهایی
      // ==========================================================

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              icon: Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade700,
                size: 44,
              ),

              title: const Text(
                'حذف مرکز هزینه',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),

              content: Text(
                'مرکز هزینه «$name» '
                'هیچ قرارداد یا رکورد حقوقی مرتبطی ندارد.\n\n'
                'آیا از حذف این مرکز هزینه اطمینان دارید؟',
                textAlign: TextAlign.right,
                style: const TextStyle(height: 1.8),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('انصراف'),
                ),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('حذف نهایی'),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      // ==========================================================
      // STEP 4
      // DELETE
      // ==========================================================

      await _repository.deleteCostCenter(id);

      if (!mounted) {
        return;
      }

      await _loadCostCenters();

      if (!mounted) {
        return;
      }

      _showMessage('مرکز هزینه «$name» با موفقیت حذف شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // DEPENDENCY DIALOG
  // ============================================================

  Future<void> _showDependencyDialog({
    required String name,
    required CostCenterDependencyInfo dependencies,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final hasPayroll = dependencies.hasPayrollRecords;

        final hasContracts = dependencies.hasContracts;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 46,
            ),

            title: const Text(
              'امکان حذف مرکز هزینه وجود ندارد',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرکز هزینه «$name» '
                    'هنوز در بخش‌های دیگر سیستم استفاده شده است.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (hasPayroll)
                    _deleteDependencyRow(
                      icon: Icons.payments_outlined,
                      title: 'رکوردهای حقوق دوره‌ها',
                      count: dependencies.payrollRecordsCount,
                    ),

                  if (hasContracts)
                    _deleteDependencyRow(
                      icon: Icons.description_outlined,
                      title: 'قراردادهای مرتبط',
                      count: dependencies.contractsCount,
                    ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange.withOpacity(.08),
                      border: Border.all(color: Colors.orange.withOpacity(.30)),
                    ),
                    child: const Text(
                      'برای حذف واقعی این مرکز هزینه، '
                      'ابتدا اطلاعات وابسته را حذف یا تعیین تکلیف کنید.\n\n'
                      'ترتیب پیشنهادی:\n'
                      '۱. ابتدا رکوردهای حقوق این مرکز هزینه را از دوره‌های حقوق حذف کنید.\n'
                      '۲. سپس قراردادهای مرتبط با این مرکز هزینه را تعیین تکلیف کنید.\n'
                      '۳. در پایان دوباره به مراکز هزینه برگردید و مرکز هزینه را حذف کنید.',
                      style: TextStyle(height: 1.9, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('متوجه شدم'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DEPENDENCY ROW
  // ============================================================

  Widget _deleteDependencyRow({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF1B4332)),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.orange.withOpacity(.10),
            ),
            child: Text(
              _toPersian(count),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return CompanyScaffold(
      companyId: widget.companyId,

      currentRoute:
          '/consultant/companies/${widget.companyId}/payroll/cost-centers',

      title: 'مراکز هزینه',

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              _buildSearch(),

              const SizedBox(height: 18),

              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                        ? _buildEmpty()
                        : _buildTable(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: Color(0xFF1B4332),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مراکز هزینه',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${_toPersian(_items.length)} مرکز هزینه ثبت شده',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          FilledButton.icon(
            onPressed: () => _openForm(),

            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
            ),

            icon: const Icon(Icons.add_rounded),

            label: const Text('ثبت مرکز هزینه'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,

      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },

      decoration: InputDecoration(
        hintText: 'جستجوی مرکز هزینه...',

        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon:
            _search.isEmpty
                ? null
                : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _search = '';
                    });
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),

        filled: true,

        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable(List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 52,

              dataRowMinHeight: 66,

              dataRowMaxHeight: 76,

              columnSpacing: 36,

              columns: const [
                DataColumn(label: Text('نام مرکز هزینه')),

                DataColumn(label: Text('کد مرکز')),

                DataColumn(label: Text('توضیحات')),

                DataColumn(label: Text('وضعیت')),

                DataColumn(label: Text('عملیات')),
              ],

              rows:
                  items.map((item) {
                    final active = item['is_active'] != false;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Text(
                              item['name']?.toString() ?? '-',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            item['code']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(
                              item['description']?.toString() ?? '-',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),

                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  active
                                      ? Colors.green.withOpacity(.08)
                                      : Colors.grey.withOpacity(.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              active ? 'فعال' : 'غیرفعال',
                              style: TextStyle(
                                color:
                                    active
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'ویرایش',
                                onPressed: () => _openForm(item: item),
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Color(0xFF2D6A4F),
                                ),
                              ),

                              IconButton(
                                tooltip: 'حذف',
                                onPressed: () => _deleteCostCenter(item),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          Text(
            _search.isEmpty
                ? 'هنوز مرکز هزینه‌ای ثبت نشده است.'
                : 'مرکز هزینه‌ای پیدا نشد.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),

          if (_search.isEmpty) ...[
            const SizedBox(height: 14),

            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ثبت مرکز هزینه'),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// FORM
// ================================================================

class _CostCenterFormDialog extends StatefulWidget {
  const _CostCenterFormDialog({required this.companyId, this.item});

  final String companyId;

  final Map<String, dynamic>? item;

  bool get isEdit => item != null;

  @override
  State<_CostCenterFormDialog> createState() => _CostCenterFormDialogState();
}

class _CostCenterFormDialogState extends State<_CostCenterFormDialog> {
  late final TextEditingController _nameController;

  late final TextEditingController _codeController;

  late final TextEditingController _descriptionController;

  bool _isActive = true;

  bool _saving = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.item?['name']?.toString() ?? '',
    );

    _codeController = TextEditingController(
      text: widget.item?['code']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.item?['description']?.toString() ?? '',
    );

    _isActive = widget.item?['is_active'] != false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('نام مرکز هزینه الزامی است.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final data = <String, dynamic>{
        'name': name,
        'code': _nullable(_codeController.text),
        'description': _nullable(_descriptionController.text),
        'is_active': _isActive,
      };

      if (widget.isEdit) {
        await _client
            .from('cost_centers')
            .update(data)
            .eq('id', widget.item!['id']);
      } else {
        await _client.from('cost_centers').insert({
          ...data,
          'company_id': widget.companyId,
        });
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // NULLABLE
  // ============================================================

  String? _nullable(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // BUILD FORM
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.isEdit ? 'ویرایش مرکز هزینه' : 'ثبت مرکز هزینه',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),

        content: SizedBox(
          width: 500,

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'نام مرکز هزینه *',
                    hintText: 'مثلاً اداری، فروش، تولید',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _codeController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'کد مرکز هزینه',
                    hintText: 'مثلاً ADMIN',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,

                  value: _isActive,

                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },

                  title: const Text('مرکز هزینه فعال است'),
                ),
              ],
            ),
          ),
        ),

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

          FilledButton(
            onPressed: _saving ? null : _save,

            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت مرکز هزینه'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PERSIAN NUMBER
// ================================================================

String _toPersian(int value) {
  const english = '0123456789';

  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value.toString();

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }

  return result;
}
