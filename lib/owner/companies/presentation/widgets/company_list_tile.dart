import 'package:flutter/material.dart';
import 'package:tarazyar/owner/companies/domain/models/company_model.dart';



class CompanyListTile extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const CompanyListTile({
    super.key,
    required this.company,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
    company.isActive ? Colors.green : Colors.grey;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 650) {
              return _buildMobile(
                context,
                statusColor,
              );
            }

            return _buildDesktop(
              context,
              statusColor,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktop(
      BuildContext context,
      Color statusColor,
      ) {
    return Row(
      children: [
        _buildAvatar(statusColor),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildMainInfo(),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _buildContactInfo(),
        ),
        const SizedBox(width: 16),
        _buildStatus(statusColor),
        const SizedBox(width: 12),
        _buildActions(context),
      ],
    );
  }

  Widget _buildMobile(
      BuildContext context,
      Color statusColor,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildAvatar(statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainInfo(),
            ),
            const SizedBox(width: 8),
            _buildStatus(statusColor),
          ],
        ),
        const SizedBox(height: 16),
        _buildContactInfo(),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildActions(context),
        ),
      ],
    );
  }

  Widget _buildAvatar(Color statusColor) {
    final logo = company.logo?.trim();

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(15),
        child: logo != null &&
            logo.isNotEmpty
            ? Image.network(
          logo,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) {
            return Icon(
              Icons
                  .business_outlined,
              color: statusColor,
              size: 29,
            );
          },
        )
            : Icon(
          Icons.business_outlined,
          color: statusColor,
          size: 29,
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          company.name.isEmpty
              ? 'بدون نام'
              : company.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight.bold,
          ),
          overflow:
          TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          'شناسه: ${company.id}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
          overflow:
          TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    final email =
    company.email?.trim();

    final phone =
    company.phone?.trim();

    final hasEmail =
        email != null &&
            email.isNotEmpty;

    final hasPhone =
        phone != null &&
            phone.isNotEmpty;

    if (!hasEmail && !hasPhone) {
      return const Text(
        'اطلاعات تماس ثبت نشده',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        if (hasEmail)
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 17,
                color: Colors.grey,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  email!,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        if (hasEmail && hasPhone)
          const SizedBox(height: 8),
        if (hasPhone)
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 17,
                color: Colors.grey,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  phone!,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatus(
      Color statusColor,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        statusColor.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
            BoxDecoration(
              color: statusColor,
              shape:
              BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            company.isActive
                ? 'فعال'
                : 'غیرفعال',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context,
      ) {
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          tooltip:
          'مشاهده جزئیات',
          onPressed: () {
            CompanyDetailsDialog.show(
              context,
              company,
            );
          },
          icon: const Icon(
            Icons.visibility_outlined,
          ),
        ),
        IconButton(
          tooltip: 'ویرایش',
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit_outlined,
          ),
        ),
        IconButton(
          tooltip: company.isActive
              ? 'غیرفعال کردن'
              : 'فعال کردن',
          onPressed: onToggle,
          icon: Icon(
            company.isActive
                ? Icons
                .pause_circle_outline
                : Icons
                .play_circle_outline,
            color: company.isActive
                ? Colors.orange
                : Colors.green,
          ),
        ),
        IconButton(
          tooltip: 'حذف',
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}