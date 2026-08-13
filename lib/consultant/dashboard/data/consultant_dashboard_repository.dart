import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultantCompany {
  const ConsultantCompany({
    required this.id,
    required this.name,
    this.legalName,
    this.city,
    this.province,
    this.phone,
    this.email,
    this.logoUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? legalName;
  final String? city;
  final String? province;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final bool isActive;

  factory ConsultantCompany.fromMap(
      Map<String, dynamic> map,
      ) {
    return ConsultantCompany(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'بدون نام').toString(),
      legalName: map['legal_name']?.toString(),
      city: map['city']?.toString(),
      province: map['province']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      logoUrl: map['logo_url']?.toString(),
      isActive: map['is_active'] == true,
    );
  }

  String get location {
    final parts = <String>[];

    if (province != null &&
        province!.trim().isNotEmpty) {
      parts.add(province!.trim());
    }

    if (city != null &&
        city!.trim().isNotEmpty) {
      parts.add(city!.trim());
    }

    if (parts.isEmpty) {
      return 'موقعیت ثبت نشده';
    }

    return parts.join('، ');
  }

  String get contact {
    if (phone != null &&
        phone!.trim().isNotEmpty) {
      return phone!.trim();
    }

    if (email != null &&
        email!.trim().isNotEmpty) {
      return email!.trim();
    }

    return 'اطلاعات تماس ثبت نشده';
  }
}

class ConsultantDashboardRepository {
  ConsultantDashboardRepository()
      : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ConsultantCompany>>
  fetchMyCompanies() async {
    final user =
        _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    final data = await _client
        .from('companies')
        .select(
      'id, name, legal_name, city, province, '
          'phone, email, logo_url, is_active',
    )
        .order(
      'name',
      ascending: true,
    );

    return (data as List)
        .map(
          (row) =>
          ConsultantCompany.fromMap(
            Map<String, dynamic>.from(row),
          ),
    )
        .toList();
  }

  Future<Map<String, dynamic>?>
  fetchMyProfile() async {
    final user =
        _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await _client
        .from('users')
        .select(
      'id, full_name, email, role, is_active, avatar_url',
    )
        .eq(
      'id',
      user.id,
    )
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      data,
    );
  }
}