import 'package:flutter/material.dart';
import 'package:tarazyar/owner/companies/domain/models/company_model.dart';

/// Displays the complete, read-only information for an owner company.
class CompanyDetailsDialog {
  const CompanyDetailsDialog._();

  static Future<void> show(BuildContext context, CompanyModel company) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _CompanyDetailsDialog(company: company),
    );
  }
}

class _CompanyDetailsDialog extends StatelessWidget {
  final CompanyModel company;

  const _CompanyDetailsDialog({required this.company});

  @override
  Widget build(BuildContext context) {
    final statusColor = company.isActive ? Colors.green : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildAvatar(statusColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name.isEmpty ? 'بدون نام' : company.name,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'شناسه: ${company.id}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'بستن',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _StatusChip(isActive: company.isActive, color: statusColor),
                const SizedBox(height: 20),
                const Text(
                  'اطلاعات شرکت',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _DetailsSection(
                  children: [
                    _DetailRow(
                      label: 'ایمیل',
                      value: company.email,
                      icon: Icons.email_outlined,
                    ),
                    _DetailRow(
                      label: 'تلفن',
                      value: company.phone,
                      icon: Icons.phone_outlined,
                    ),
                    _DetailRow(
                      label: 'وب‌سایت',
                      value: company.website,
                      icon: Icons.language,
                    ),
                    _DetailRow(
                      label: 'آدرس',
                      value: company.address,
                      icon: Icons.location_on_outlined,
                      multiLine: true,
                    ),
                  ],
                ),
                if (company.createdAt != null || company.updatedAt != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'زمان‌بندی',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _DetailsSection(
                    children: [
                      _DetailRow(
                        label: 'تاریخ ایجاد',
                        value: _formatDate(company.createdAt),
                        icon: Icons.calendar_today_outlined,
                      ),
                      _DetailRow(
                        label: 'آخرین ویرایش',
                        value: _formatDate(company.updatedAt),
                        icon: Icons.update_outlined,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('بستن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color statusColor) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Icon(Icons.business_outlined, color: statusColor, size: 32),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    final localDate = date.toLocal();
    return '${localDate.year.toString().padLeft(4, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.day.toString().padLeft(2, '0')} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _StatusChip({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              isActive ? 'فعال' : 'غیرفعال',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final List<Widget> children;

  const _DetailsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final bool multiLine;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              displayValue == null || displayValue.isEmpty
                  ? 'ثبت نشده'
                  : displayValue,
              maxLines: multiLine ? null : 1,
              overflow: multiLine ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
