import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';

class BackupSettingsCard extends ConsumerStatefulWidget {
  const BackupSettingsCard({super.key});

  @override
  ConsumerState<BackupSettingsCard> createState() =>
      _BackupSettingsCardState();
}

class _BackupSettingsCardState
    extends ConsumerState<BackupSettingsCard> {

  bool loaded = false;

  bool autoBackup = true;
  bool cloudBackup = true;

  String backupPeriod = "روزانه";
  String backupTime = "02:00";

  @override
  Widget build(BuildContext context) {

    final settings = ref.watch(settingsProvider);
    final loading = ref.watch(settingsControllerProvider);

    return settings.when(

      loading: () => const Card(
        child: SizedBox(
          height: 420,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      error: (e, _) => Card(
        child: SizedBox(
          height: 420,
          child: Center(
            child: Text(e.toString()),
          ),
        ),
      ),

      data: (data) {

        if (!loaded) {

          autoBackup = data["auto_backup"] ?? true;
          cloudBackup = data["cloud_backup"] ?? true;
          backupPeriod = data["backup_period"] ?? "روزانه";
          backupTime = data["backup_time"] ?? "02:00";

          loaded = true;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "تنظیمات نسخه پشتیبان",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  value: backupPeriod,
                  decoration: const InputDecoration(
                    labelText: "دوره پشتیبان گیری",
                    border: OutlineInputBorder(),
                  ),
                  items: const [

                    DropdownMenuItem(
                      value: "روزانه",
                      child: Text("روزانه"),
                    ),

                    DropdownMenuItem(
                      value: "هفتگی",
                      child: Text("هفتگی"),
                    ),

                    DropdownMenuItem(
                      value: "ماهانه",
                      child: Text("ماهانه"),
                    ),

                  ],
                  onChanged: (v) {

                    setState(() {
                      backupPeriod = v!;
                    });

                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  initialValue: backupTime,
                  decoration: const InputDecoration(
                    labelText: "ساعت پشتیبان گیری",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    backupTime = v;
                  },
                ),

                const SizedBox(height: 16),

                SwitchListTile(
                  value: autoBackup,
                  title: const Text("پشتیبان گیری خودکار"),
                  onChanged: (v) {

                    setState(() {
                      autoBackup = v;
                    });

                  },
                ),

                SwitchListTile(
                  value: cloudBackup,
                  title: const Text("ذخیره در فضای ابری"),
                  onChanged: (v) {

                    setState(() {
                      cloudBackup = v;
                    });

                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(

                    onPressed: loading
                        ? null
                        : () {

                      ref
                          .read(settingsControllerProvider.notifier)
                          .saveBackupSettings(

                        context: context,

                        autoBackup: autoBackup,

                        cloudBackup: cloudBackup,

                        period: backupPeriod,

                        time: backupTime,

                      );

                    },

                    child: loading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text("ذخیره تنظیمات"),

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