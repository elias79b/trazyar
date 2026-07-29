// lib/shared/presentation/widgets/dashboard_shell_widget.dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:tarazyar/core/constants/app_assets.dart';

class DashboardShellWidget extends StatelessWidget {
  const DashboardShellWidget({
    required this.title,
    required this.onSignOut,
    super.key,
  });

  final String title;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.spacing8,
            centerTitle: false,
            title: const _TopBarLogoWidget(),
            actions: [
              IconButton(
                tooltip: 'خروج',
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_outlined),
              ),
              const SizedBox(width: AppSpacing.spacing8),
            ],
          ),
          drawer: isWide ? null : _SidebarWidget(title: title),
          body: Row(
            children: [
              if (isWide) _SidebarWidget(title: title),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeaderCard(title: title),
                          const SizedBox(height: AppSpacing.spacing24),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                BorderRadius.circular(AppRadius.radius16),
                                border: Border.all(
                                  color:
                                  Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.spacing24),
                              child: const Center(
                                child: Text(
                                  'محتوای داشبورد',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBarLogoWidget extends StatelessWidget {
  const _TopBarLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.logo,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.spacing8),
        Text(
          'ترازیار',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  const _SidebarWidget({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: 280,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      AppAssets.logo,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: Text(
                        'ترازیار',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                _SidebarTile(
                  icon: Icons.dashboard_outlined,
                  title: 'داشبورد',
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.business_outlined,
                  title: 'شرکت‌ها',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.people_alt_outlined,
                  title: 'مشاوران',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'اشتراک‌ها',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.groups_outlined,
                  title: 'کاربران',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'گزارش فعالیت',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.spacing4),
                _SidebarTile(
                  icon: Icons.settings_outlined,
                  title: 'تنظیمات',
                  onTap: () {},
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('ایجاد شرکت'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color:
      selected ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: AppSpacing.spacing12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing16),
          Text(
            'داشبورد',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}