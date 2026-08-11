import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';

class NotificationSettingsCard extends ConsumerStatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  ConsumerState<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState
    extends ConsumerState<NotificationSettingsCard> {

  bool loaded = false;

  bool email = true;
  bool sms = false;
  bool push = true;
  bool login = true;
  bool backup = true;
  bool update = true;

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

          email = data["email_notifications"] ?? true;
          sms = data["sms_notifications"] ?? false;
          push = data["push_notifications"] ?? true;
          login = data["login_notifications"] ?? true;
          backup = data["backup_notifications"] ?? true;
          update = data["update_notifications"] ?? true;

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
                  "تنظیمات اعلان ها",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                SwitchListTile(
                  value: email,
                  title: const Text("اعلان ایمیل"),
                  onChanged: (v) => setState(() => email = v),
                ),

                SwitchListTile(
                  value: sms,
                  title: const Text("اعلان پیامکی"),
                  onChanged: (v) => setState(() => sms = v),
                ),

                SwitchListTile(
                  value: push,
                  title: const Text("Push Notification"),
                  onChanged: (v) => setState(() => push = v),
                ),

                SwitchListTile(
                  value: login,
                  title: const Text("اعلان ورود"),
                  onChanged: (v) => setState(() => login = v),
                ),

                SwitchListTile(
                  value: backup,
                  title: const Text("اعلان نسخه پشتیبان"),
                  onChanged: (v) => setState(() => backup = v),
                ),

                SwitchListTile(
                  value: update,
                  title: const Text("اعلان بروزرسانی"),
                  onChanged: (v) => setState(() => update = v),
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
                          .saveNotificationSettings(

                        context: context,

                        email: email,

                        sms: sms,

                        push: push,

                        login: login,

                        backup: backup,

                        update: update,

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