import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  //==========================
  // Owner Profile
  //==========================

  Future<Map<String, dynamic>> getOwnerProfile() async {
    final user = _client.auth.currentUser!;

    final data =
        await _client.from('users').select().eq('id', user.id).single();

    return Map<String, dynamic>.from(data);
  }

  Future<void> updateOwnerProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final user = _client.auth.currentUser!;

    await _client
        .from('users')
        .update({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  //==========================
  // Company
  //==========================

  Future<Map<String, dynamic>> getCompanyInfo() async {
    final company =
        await _client.from('companies').select().limit(1).maybeSingle();

    if (company == null) {
      return {};
    }

    return Map<String, dynamic>.from(company);
  }

  Future<void> updateCompany({
    required String name,
    required String phone,
    required String email,
    required String website,
    required String address,
  }) async {
    final company =
        await _client.from('companies').select('id').limit(1).single();

    await _client
        .from('companies')
        .update({
          'name': name,
          'phone': phone,
          'email': email,
          'website': website,
          'address': address,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', company['id']);
  }

  Future<String> uploadCompanyLogo(XFile image) async {
    final bytes = await image.readAsBytes();

    final user = _client.auth.currentUser!;

    final path = "${user.id}/logo_${DateTime.now().millisecondsSinceEpoch}.png";

    await _client.storage
        .from("company-logos")
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from("company-logos").getPublicUrl(path);

    return url;
  }
  //==========================
  // Settings
  //==========================

  Future<Map<String, dynamic>> getSettings() async {
    final user = _client.auth.currentUser!;

    final data =
        await _client
            .from('settings')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();

    if (data != null) {
      return Map<String, dynamic>.from(data);
    }

    await _client.from('settings').insert({'owner_id': user.id});

    final created =
        await _client
            .from('settings')
            .select()
            .eq('owner_id', user.id)
            .single();

    return Map<String, dynamic>.from(created);
  }

  Future<void> updateGeneralSettings({
    required String language,
    required String currency,
    required String timezone,
    required String calendar,
  }) async {
    final user = _client.auth.currentUser!;

    await _client
        .from('settings')
        .update({
          'language': language,
          'currency': currency,
          'timezone': timezone,
          'calendar': calendar,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('owner_id', user.id);
  }

  Future<void> updateNotificationSettings({
    required bool email,
    required bool sms,
    required bool push,
    required bool login,
    required bool backup,
    required bool update,
  }) async {
    final user = _client.auth.currentUser!;

    await _client
        .from('settings')
        .update({
          'email_notifications': email,
          'sms_notifications': sms,
          'push_notifications': push,
          'login_notifications': login,
          'backup_notifications': backup,
          'update_notifications': update,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('owner_id', user.id);
  }

  Future<void> updateBackupSettings({
    required bool autoBackup,
    required bool cloudBackup,
    required String period,
    required String time,
  }) async {
    final user = _client.auth.currentUser!;

    await _client
        .from('settings')
        .update({
          'auto_backup': autoBackup,
          'cloud_backup': cloudBackup,
          'backup_period': period,
          'backup_time': time,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('owner_id', user.id);
  }

  //==========================
  // Subscription
  //==========================

  Future<Map<String, dynamic>> getSubscription() async {
    final subscription =
        await _client
            .from('subscriptions')
            .select('*,plans(*)')
            .limit(1)
            .maybeSingle();

    if (subscription == null) {
      return {};
    }

    return Map<String, dynamic>.from(subscription);
  }
  //==========================
  // Password
  //==========================

  Future<void> changePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  //==========================
  // System Info
  //==========================

  Future<Map<String, dynamic>> getSystemInfo() async {
    return {
      "app_name": "ترازیار",
      "version": "1.0.0",
      "database": "Supabase",
      "flutter": "3.29.3",
      "dart": "3.7.2",
    };
  }

  //==========================
  // Refresh Helpers
  //==========================

  Future<void> refreshSettings() async {
    await getSettings();
  }

  Future<void> refreshCompany() async {
    await getCompanyInfo();
  }

  Future<void> refreshProfile() async {
    await getOwnerProfile();
  }

  Future<void> refreshSubscription() async {
    await getSubscription();
  }

  //==========================
  // Sign Out
  //==========================

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
