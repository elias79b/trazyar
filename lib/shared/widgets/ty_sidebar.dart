// lib/shared/widgets/ty_sidebar.dart
import 'package:flutter/material.dart';

class TySidebarItem {
  const TySidebarItem({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

class TySidebar extends StatelessWidget {
  const TySidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.logoPath = 'assets/images/logo.png',
    this.brandTitle = 'ترازیار',
    this.subtitle = 'داشبورد مدیر سامانه',
    this.footerButtonText = 'ایجاد شرکت',
    this.onFooterButtonPressed,
  });

  final List<TySidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String logoPath;
  final String brandTitle;
  final String subtitle;
  final String footerButtonText;
  final VoidCallback? onFooterButtonPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      logoPath,
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      brandTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = index == selectedIndex;

                    return Material(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onItemSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 22,
                                color: selected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
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
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onFooterButtonPressed,
                icon: const Icon(Icons.add_business_rounded),
                label: Text(footerButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}