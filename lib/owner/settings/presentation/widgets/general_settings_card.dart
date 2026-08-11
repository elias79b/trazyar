import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/controllers/settings_controller.dart';

import '../../application/settings_provider.dart';

class GeneralSettingsCard extends ConsumerStatefulWidget {
  const GeneralSettingsCard({super.key});

  @override
  ConsumerState<GeneralSettingsCard> createState() =>
      _GeneralSettingsCardState();
}

class _GeneralSettingsCardState
    extends ConsumerState<GeneralSettingsCard> {

  bool loaded = false;

  String language = "fa";
  String currency = "IRR";
  String timezone = "Asia/Tehran";
  String calendar = "jalali";

  @override
  Widget build(BuildContext context) {

    final settings = ref.watch(settingsProvider);
    final loading = ref.watch(settingsControllerProvider);

    return settings.when(

      loading: () => const Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      error: (e, _) => Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: Text(e.toString()),
          ),
        ),
      ),

      data: (data) {

        if (!loaded) {
          language = data["language"] ?? "fa";
          currency = data["currency"] ?? "IRR";
          timezone = data["timezone"] ?? "Asia/Tehran";
          calendar = data["calendar"] ?? "jalali";
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
                  "تنظیمات عمومی",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  value: language,
                  decoration: const InputDecoration(
                    labelText: "زبان",
                    border: OutlineInputBorder(),
                  ),
                  items: const [

                    DropdownMenuItem(
                      value: "fa",
                      child: Text("فارسی"),
                    ),

                    DropdownMenuItem(
                      value: "en",
                      child: Text("English"),
                    ),

                  ],
                  onChanged: (v) {
                    setState(() {
                      language = v!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: currency,
                  decoration: const InputDecoration(
                    labelText: "واحد پول",
                    border: OutlineInputBorder(),
                  ),
                  items: const [

                    DropdownMenuItem(
                      value: "IRR",
                      child: Text("ریال"),
                    ),

                    DropdownMenuItem(
                      value: "TOMAN",
                      child: Text("تومان"),
                    ),

                  ],
                  onChanged: (v) {
                    setState(() {
                      currency = v!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: calendar,
                  decoration: const InputDecoration(
                    labelText: "تقویم",
                    border: OutlineInputBorder(),
                  ),
                  items: const [

                    DropdownMenuItem(
                      value: "jalali",
                      child: Text("شمسی"),
                    ),

                    DropdownMenuItem(
                      value: "gregorian",
                      child: Text("میلادی"),
                    ),

                  ],
                  onChanged: (v) {
                    setState(() {
                      calendar = v!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: timezone,
                  decoration: const InputDecoration(
                    labelText: "منطقه زمانی",
                    border: OutlineInputBorder(),
                  ),
                  items: const [

                    DropdownMenuItem(
                      value: "Asia/Tehran",
                      child: Text("Asia/Tehran"),
                    ),

                  ],
                  onChanged: (v) {
                    setState(() {
                      timezone = v!;
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
                          .saveGeneralSettings(

                        context: context,

                        language: language,

                        currency: currency,

                        timezone: timezone,

                        calendar: calendar,

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