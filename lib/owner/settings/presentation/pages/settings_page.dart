import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';

import '../../application/settings_provider.dart';
import '../widgets/settings_header.dart';
import '../widgets/profile_settings_card.dart';
import '../widgets/company_settings_card.dart';
import '../widgets/general_settings_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/backup_settings_card.dart';
import '../widgets/security_settings_card.dart';
import '../widgets/subscription_settings_card.dart';
import '../widgets/system_info_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: OwnerScaffold(
        currentRoute: '/settings',
        title: 'پنل مدیریت ترازیار',
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(settingsProvider);
              ref.invalidate(ownerProfileProvider);
              ref.invalidate(companyInfoProvider);
              ref.invalidate(subscriptionProvider);
              ref.invalidate(systemInfoProvider);

              await ref.read(settingsProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsHeader(
                    onRefresh: () {
                      ref.invalidate(settingsProvider);
                      ref.invalidate(ownerProfileProvider);
                      ref.invalidate(companyInfoProvider);
                      ref.invalidate(subscriptionProvider);
                      ref.invalidate(systemInfoProvider);
                    },
                  ),

                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1100;

                      if (wide) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ProfileSettingsCard(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: CompanySettingsCard(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: GeneralSettingsCard(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: NotificationSettingsCard(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: BackupSettingsCard(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: SecuritySettingsCard(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SubscriptionSettingsCard(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: SystemInfoCard(),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          ProfileSettingsCard(),

                          const SizedBox(height: 20),

                          CompanySettingsCard(),

                          const SizedBox(height: 20),

                          GeneralSettingsCard(),

                          const SizedBox(height: 20),

                          NotificationSettingsCard(),

                          const SizedBox(height: 20),

                          BackupSettingsCard(),

                          const SizedBox(height: 20),

                          SecuritySettingsCard(),

                          const SizedBox(height: 20),

                          SubscriptionSettingsCard(),

                          const SizedBox(height: 20),

                          SystemInfoCard(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}