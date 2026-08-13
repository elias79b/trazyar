import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';
import '../../application/users_provider.dart';
import '../../data/users_repository.dart';
import '../widgets/user_edit_dialog.dart';
import '../widgets/user_create_dialog.dart';
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'همه';
  String _selectedRole = 'همه';

  final List<String> _statuses = const [
    'همه',
    'فعال',
    'غیرفعال',
  ];

  final List<String> _roles = const [
    'همه',
    'owner',
    'consultant',
    'company_admin',
    'accountant',
    'hr',
    'observer',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _createUser() async {
    final companies = await ref.read(
      ownerCompaniesForUserProvider.future,
    );

    if (!mounted) return;

    final result = await showDialog<UserInvitationResult>(
      context: context,
      builder: (_) => UserCreateDialog(
        companies: companies,
        initialRole: 'consultant',
      ),
    );

    if (result == null || !mounted) return;

    ref.invalidate(ownerUsersProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'دعوت‌نامه برای ${result.email} ارسال شد.',
        ),
      ),
    );
  }
  List<OwnerUser> _filteredUsers(List<OwnerUser> users) {
    final q = _searchController.text.trim().toLowerCase();

    return users.where((u) {
      final matchesSearch = q.isEmpty ||
          u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.roleLabel.toLowerCase().contains(q);

      final matchesStatus =
          _selectedStatus == 'همه' || u.statusLabel == _selectedStatus;
      final matchesRole = _selectedRole == 'همه' || u.role == _selectedRole;

      return matchesSearch && matchesStatus && matchesRole;
    }).toList();
  }

  Future<void> _editUser(OwnerUser user) async {
    final input = await showDialog<OwnerUserUpdateInput>(
      context: context,
      builder: (_) => UserEditDialog(user: user),
    );

    if (input == null) return;

    try {
      await ref.read(usersRepositoryProvider).updateUser(
        id: user.id,
        input: input,
      );

      ref.invalidate(ownerUsersProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کاربر با موفقیت ذخیره شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره کاربر: $e')),
      );
    }
  }

  Future<void> _toggleUserStatus(OwnerUser user) async {
    try {
      await ref.read(usersRepositoryProvider).updateUser(
        id: user.id,
        input: OwnerUserUpdateInput(
          fullName: user.displayName,
          role: user.role,
          isActive: !user.isActive,
        ),
      );

      ref.invalidate(ownerUsersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در تغییر وضعیت: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final usersAsync = ref.watch(ownerUsersProvider);

    return OwnerScaffold(
      currentRoute: '/owner/users',
      title: 'مدیریت کاربران',
      body: usersAsync.when(
        loading: () => const SizedBox(
          height: 500,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => SizedBox(
          height: 500,
          child: Center(
            child: Text('خطا در دریافت کاربران: $error'),
          ),
        ),
        data: (users) {
          final filtered = _filteredUsers(users);

          final total = users.length;
          final active = users.where((e) => e.isActive).length;
          final inactive = users.where((e) => !e.isActive).length;
          final owners = users.where((e) => e.role == 'owner').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                title: 'مدیریت کاربران',
                subtitle: 'مشاهده و مدیریت کاربران و نقش‌ها',
                onRefreshPressed: () =>
                    ref.invalidate(ownerUsersProvider),
                onAddPressed: _createUser,
              ),
              const SizedBox(height: 20),
              _StatsRow(
                total: total,
                active: active,
                inactive: inactive,
                owners: owners,
              ),
              const SizedBox(height: 20),
              _SearchAndFilterRow(
                searchController: _searchController,
                statuses: _statuses,
                roles: _roles,
                selectedStatus: _selectedStatus,
                selectedRole: _selectedRole,
                onStatusChanged: (value) => setState(() => _selectedStatus = value),
                onRoleChanged: (value) => setState(() => _selectedRole = value),
                onSearchChanged: (_) => setState(() {}),
                onRefreshPressed: () => ref.invalidate(ownerUsersProvider),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.68,
                child: filtered.isEmpty
                    ? _EmptyState(
                  onRefreshPressed: () => ref.invalidate(ownerUsersProvider),
                )
                    : isWide
                    ? _UsersDataTable(
                  users: filtered,
                  onEdit: _editUser,
                  onToggleStatus: _toggleUserStatus,
                )
                    : _UsersCardsList(
                  users: filtered,
                  onEdit: _editUser,
                  onToggleStatus: _toggleUserStatus,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onRefreshPressed,
    required this.onAddPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefreshPressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          if (compact) {
            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: .9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(
                    Icons.person_add_alt_1,
                  ),
                  label: const Text(
                    'افزودن کاربر',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRefreshPressed,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'تازه‌سازی',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.people_alt_rounded,
                  color: Color(0xFF1B4332),
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: .9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(
                  Icons.person_add_alt_1,
                ),
                label: const Text(
                  'افزودن کاربر',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'تازه‌سازی',
                onPressed: onRefreshPressed,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.active,
    required this.inactive,
    required this.owners,
  });

  final int total;
  final int active;
  final int inactive;
  final int owners;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1200
            ? 4
            : width >= 800
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.8,
          children: [
            _StatBox(title: 'کل کاربران', value: '$total', icon: Icons.groups),
            _StatBox(title: 'فعال', value: '$active', icon: Icons.check_circle),
            _StatBox(title: 'غیرفعال', value: '$inactive', icon: Icons.block),
            _StatBox(title: 'مدیر کل', value: '$owners', icon: Icons.verified),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4332),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
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

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({
    required this.searchController,
    required this.statuses,
    required this.roles,
    required this.selectedStatus,
    required this.selectedRole,
    required this.onStatusChanged,
    required this.onRoleChanged,
    required this.onSearchChanged,
    required this.onRefreshPressed,
  });

  final TextEditingController searchController;
  final List<String> statuses;
  final List<String> roles;
  final String selectedStatus;
  final String selectedRole;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'جستجوی کاربر، ایمیل، نقش...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );

        final statusDropdown = DropdownButtonFormField<String>(
          value: selectedStatus,
          items: statuses
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );

        final roleDropdown = DropdownButtonFormField<String>(
          value: selectedRole,
          items: roles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value != null) onRoleChanged(value);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );

        final refreshButton = FilledButton.icon(
          onPressed: onRefreshPressed,
          icon: const Icon(Icons.refresh),
          label: const Text('تازه‌سازی'),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 16),
              SizedBox(width: 180, child: statusDropdown),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: roleDropdown),
              const SizedBox(width: 16),
              refreshButton,
            ],
          );
        }

        return Column(
          children: [
            searchField,
            const SizedBox(height: 16),
            statusDropdown,
            const SizedBox(height: 16),
            roleDropdown,
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: refreshButton),
          ],
        );
      },
    );
  }
}

class _UsersDataTable extends StatelessWidget {
  const _UsersDataTable({
    required this.users,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final List<OwnerUser> users;
  final Future<void> Function(OwnerUser user) onEdit;
  final Future<void> Function(OwnerUser user) onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStatePropertyAll(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('نام')),
              DataColumn(label: Text('ایمیل')),
              DataColumn(label: Text('نقش')),
              DataColumn(label: Text('وضعیت')),
              DataColumn(label: Text('تاریخ ایجاد')),
              DataColumn(label: Text('عملیات')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(_UserNameCell(user: user)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.roleLabel)),
                  DataCell(_StatusChip(status: user.statusLabel)),
                  DataCell(Text(
                    '${user.createdAt.year}/${user.createdAt.month}/${user.createdAt.day}',
                  )),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => onEdit(user),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => onToggleStatus(user),
                          icon: Icon(
                            user.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off,
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
    );
  }
}

class _UserNameCell extends StatelessWidget {
  const _UserNameCell({required this.user});

  final OwnerUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
          child: Text(
            user.avatarLetter,
            style: const TextStyle(
              color: Color(0xFF1B4332),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(user.displayName),
      ],
    );
  }
}

class _UsersCardsList extends StatelessWidget {
  const _UsersCardsList({
    required this.users,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final List<OwnerUser> users;
  final Future<void> Function(OwnerUser user) onEdit;
  final Future<void> Function(OwnerUser user) onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
              child: Text(
                user.avatarLetter,
                style: const TextStyle(
                  color: Color(0xFF1B4332),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${user.email} • ${user.roleLabel}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(status: user.statusLabel),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onEdit(user),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => onToggleStatus(user),
                  icon: Icon(
                    user.isActive ? Icons.toggle_on : Icons.toggle_off,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'فعال' => Colors.green,
      'غیرفعال' => Colors.red,
      'در انتظار' => Colors.orange,
      _ => Colors.blue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefreshPressed});

  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'کاربری یافت نشد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text('داده‌ها را تازه‌سازی کنید'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRefreshPressed,
            icon: const Icon(Icons.refresh),
            label: const Text('تازه‌سازی'),
          ),
        ],
      ),
    );
  }
}