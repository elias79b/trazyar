import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(settingsRepositoryProvider).getSettings();
});

final ownerProfileProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(settingsRepositoryProvider).getOwnerProfile();
});

final companyInfoProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(settingsRepositoryProvider).getCompanyInfo();
});

final subscriptionProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(settingsRepositoryProvider).getSubscription();
});

final systemInfoProvider =
FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(settingsRepositoryProvider).getSystemInfo();
});