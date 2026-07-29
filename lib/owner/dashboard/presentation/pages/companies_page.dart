import 'package:flutter/material.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'همه';
  final List<String> _filters = const [
    'همه',
    'فعال',
    'غیرفعال',
    'در انتظار تأیید',
  ];

  final List<_CompanyItem> _companies = const [
    _CompanyItem(
      name: 'شرکت آریا',
      owner: 'علی محمدی',
      status: 'فعال',
      usersCount: 12,
      subscription: 'حرفه‌ای',
      lastActivity: '2 ساعت پیش',
      logoLetter: 'آ',
    ),
    _CompanyItem(
      name: 'مجموعه مهر',
      owner: 'رضا احمدی',
      status: 'در انتظار تأیید',
      usersCount: 5,
      subscription: 'آزمایشی',
      lastActivity: 'امروز',
      logoLetter: 'م',
    ),
    _CompanyItem(
      name: 'فروشگاه امید',
      owner: 'سارا حسینی',
      status: 'فعال',
      usersCount: 8,
      subscription: 'سازمانی',
      lastActivity: 'دیشب',
      logoLetter: 'ف',
    ),
    _CompanyItem(
      name: 'کلینیک بهار',
      owner: 'محمد کریمی',
      status: 'غیرفعال',
      usersCount: 3,
      subscription: 'پایه',
      lastActivity: '3 روز پیش',
      logoLetter: 'ک',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CompanyItem> get _filteredCompanies {
    final query = _searchController.text.trim();
    return _companies.where((company) {
      final matchesSearch = query.isEmpty ||
          company.name.contains(query) ||
          company.owner.contains(query);

      final matchesFilter =
          _selectedFilter == 'همه' || company.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final items = _filteredCompanies;

    return OwnerScaffold(
      currentRoute: '/owner/companies',
      title: 'مدیریت شرکت‌ها',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'مدیریت شرکت‌ها',
            subtitle: 'ایجاد، بررسی و مدیریت تمام شرکت‌های ثبت شده در ترازیار',
            onAddPressed: () {},
          ),
          const SizedBox(height: 20),
          _StatsRow(items: items),
          const SizedBox(height: 20),
          _SearchAndFilterRow(
            searchController: _searchController,
            filters: _filters,
            selectedFilter: _selectedFilter,
            onFilterChanged: (value) {
              setState(() => _selectedFilter = value);
            },
            onSearchChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: items.isEmpty
                ? _EmptyState(
              onCreatePressed: () {},
            )
                : isWide
                ? _CompaniesDataTable(companies: items)
                : _CompaniesCardsList(companies: items),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onAddPressed,
  });

  final String title;
  final String subtitle;
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.business_rounded,
              color: Color(0xFF1B4332),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('ایجاد شرکت'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_CompanyItem> items;

  @override
  Widget build(BuildContext context) {
    final active = items.where((e) => e.status == 'فعال').length;
    final pending = items.where((e) => e.status == 'در انتظار تأیید').length;
    final inactive = items.where((e) => e.status == 'غیرفعال').length;
    final total = items.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1200
            ? 4
            : width >= 800
            ? 2
            : 1;

        final cards = [
          _StatBox(title: 'کل شرکت‌ها', value: '$total', icon: Icons.apartment),
          _StatBox(title: 'فعال', value: '$active', icon: Icons.check_circle),
          _StatBox(
              title: 'در انتظار تأیید',
              value: '$pending',
              icon: Icons.hourglass_top),
          _StatBox(title: 'غیرفعال', value: '$inactive', icon: Icons.block),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.8,
          children: cards,
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
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'جستجوی شرکت یا مدیر...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );

        final dropdown = DropdownButtonFormField<String>(
          value: selectedFilter,
          items: filters
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) onFilterChanged(value);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: dropdown),
            ],
          );
        }

        return Column(
          children: [
            searchField,
            const SizedBox(height: 16),
            dropdown,
          ],
        );
      },
    );
  }
}

class _CompaniesDataTable extends StatelessWidget {
  const _CompaniesDataTable({required this.companies});

  final List<_CompanyItem> companies;

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
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              Colors.grey.shade100,
            ),
            columns: const [
              DataColumn(label: Text('نام شرکت')),
              DataColumn(label: Text('مدیر')),
              DataColumn(label: Text('وضعیت')),
              DataColumn(label: Text('کاربران')),
              DataColumn(label: Text('اشتراک')),
              DataColumn(label: Text('آخرین فعالیت')),
              DataColumn(label: Text('عملیات')),
            ],
            rows: companies.map((company) {
              return DataRow(
                cells: [
                  DataCell(_CompanyNameCell(company: company)),
                  DataCell(Text(company.owner)),
                  DataCell(_StatusChip(status: company.status)),
                  DataCell(Text('${company.usersCount}')),
                  DataCell(Text(company.subscription)),
                  DataCell(Text(company.lastActivity)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined),
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

class _CompanyNameCell extends StatelessWidget {
  const _CompanyNameCell({required this.company});

  final _CompanyItem company;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
          child: Text(
            company.logoLetter,
            style: const TextStyle(
              color: Color(0xFF1B4332),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(company.name),
      ],
    );
  }
}

class _CompaniesCardsList extends StatelessWidget {
  const _CompaniesCardsList({required this.companies});

  final List<_CompanyItem> companies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final company = companies[index];
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
                company.logoLetter,
                style: const TextStyle(
                  color: Color(0xFF1B4332),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              company.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${company.owner} • ${company.subscription}'),
            trailing: _StatusChip(status: company.status),
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
      'در انتظار تأیید' => Colors.orange,
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
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business_outlined,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'شرکتی یافت نشد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text('برای شروع یک شرکت جدید ایجاد کنید'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add),
            label: const Text('ایجاد شرکت'),
          ),
        ],
      ),
    );
  }
}

class _CompanyItem {
  final String name;
  final String owner;
  final String status;
  final int usersCount;
  final String subscription;
  final String lastActivity;
  final String logoLetter;

  const _CompanyItem({
    required this.name,
    required this.owner,
    required this.status,
    required this.usersCount,
    required this.subscription,
    required this.lastActivity,
    required this.logoLetter,
  });
}