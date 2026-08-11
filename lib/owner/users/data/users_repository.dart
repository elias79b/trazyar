import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerUser {
  const OwnerUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? avatarUrl;

  factory OwnerUser.fromMap(Map<String, dynamic> map) {
    return OwnerUser(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'company_user').toString(),
      isActive: map['is_active'] == true,
      createdAt:
      DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  String get statusLabel => isActive ? 'فعال' : 'غیرفعال';

  String get roleLabel {
    return switch (role) {
      'owner' => 'مدیر کل سیستم',
      'consultant' => 'مشاور',
      'company_admin' => 'مدیر شرکت',
      'accountant' => 'حسابدار',
      'hr' => 'منابع انسانی',
      'observer' => 'ناظر',
      _ => 'کاربر',
    };
  }

  String get displayName {
    final value = fullName.trim();
    return value.isEmpty ? email : value;
  }

  String get avatarLetter {
    final value = displayName.trim();
    return value.isEmpty ? 'ک' : value[0];
  }
}

class OwnerUserUpdateInput {
  const OwnerUserUpdateInput({
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  final String fullName;
  final String role;
  final bool isActive;
}

class UsersRepository {
  UsersRepository() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<OwnerUser>> fetchUsers() async {
    final data = await _client
        .from('users')
        .select('id, full_name, email, role, is_active, avatar_url, created_at')
        .order('created_at', ascending: false);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(OwnerUser.fromMap)
        .toList();
  }

  Future<void> updateUser({
    required String id,
    required OwnerUserUpdateInput input,
  }) async {
    await _client.from('users').update({
      'full_name': input.fullName.trim(),
      'role': input.role,
      'is_active': input.isActive,
    }).eq('id', id);
  }
}