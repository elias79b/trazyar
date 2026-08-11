import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/settings/application/settings_provider.dart';

final settingsControllerProvider =
StateNotifierProvider<SettingsController, bool>(
      (ref) => SettingsController(ref),
);

class SettingsController extends StateNotifier<bool> {
  SettingsController(this.ref) : super(false);

  final Ref ref;

  //==============================
  // Profile
  //==============================

  Future<void> updateProfile({
    required BuildContext context,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).updateOwnerProfile(
        fullName: fullName,
        email: email,
        phone: phone,
      );

      ref.invalidate(ownerProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اطلاعات پروفایل ذخیره شد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }

  //==============================
  // Company
  //==============================

  Future<void> updateCompany({
    required BuildContext context,
    required String name,
    required String phone,
    required String email,
    required String website,
    required String address,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).updateCompany(
        name: name,
        phone: phone,
        email: email,
        website: website,
        address: address,
      );

      ref.invalidate(companyInfoProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اطلاعات شرکت ذخیره شد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }

  //==============================
  // Password
  //==============================

  Future<void> changePassword({
    required BuildContext context,
    required String password,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).changePassword(password);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("رمز عبور تغییر کرد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }

  //==============================
  // General Settings
  //==============================

  Future<void> saveGeneralSettings({
    required BuildContext context,
    required String language,
    required String currency,
    required String timezone,
    required String calendar,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).updateGeneralSettings(
        language: language,
        currency: currency,
        timezone: timezone,
        calendar: calendar,
      );

      ref.invalidate(settingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تنظیمات ذخیره شد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }

  //==============================
  // Notifications
  //==============================

  Future<void> saveNotificationSettings({
    required BuildContext context,
    required bool email,
    required bool sms,
    required bool push,
    required bool login,
    required bool backup,
    required bool update,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).updateNotificationSettings(
        email: email,
        sms: sms,
        push: push,
        login: login,
        backup: backup,
        update: update,
      );

      ref.invalidate(settingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اعلان‌ها ذخیره شد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }

  //==============================
  // Backup
  //==============================

  Future<void> saveBackupSettings({
    required BuildContext context,
    required bool autoBackup,
    required bool cloudBackup,
    required String period,
    required String time,
  }) async {
    state = true;

    try {
      await ref.read(settingsRepositoryProvider).updateBackupSettings(
        autoBackup: autoBackup,
        cloudBackup: cloudBackup,
        period: period,
        time: time,
      );

      ref.invalidate(settingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تنظیمات بکاپ ذخیره شد")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    state = false;
  }
}