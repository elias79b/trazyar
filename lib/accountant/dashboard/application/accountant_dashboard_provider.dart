import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantDashboardProvider = FutureProvider<AccountantDashboardData>((
  ref,
) async {
  final client = Supabase.instance.client;

  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('کاربر وارد سیستم نشده است.');
  }

  // ============================================================
  // USER
  // ============================================================

  final userData =
      await client
          .from('users')
          .select('id, full_name, email, role, is_active')
          .eq('id', user.id)
          .maybeSingle();

  if (userData == null) {
    throw Exception('اطلاعات حسابدار پیدا نشد.');
  }

  final role = userData['role']?.toString();

  if (role != 'accountant') {
    throw Exception('این حساب کاربری حسابدار نیست.');
  }

  final isActive = userData['is_active'] == true;

  if (!isActive) {
    throw Exception('حساب کاربری شما غیرفعال است.');
  }

  // ============================================================
  // COMPANY ASSIGNMENT
  // ============================================================

  final assignment =
      await client
          .from('company_users')
          .select('''
        id,
        company_id,
        user_id,
        role,
        is_active,
        companies (
          id,
          name,
          legal_name,
          national_id,
          phone,
          email,
          city,
          province,
          logo_url,
          is_active
        )
        ''')
          .eq('user_id', user.id)
          .eq('role', 'accountant')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

  if (assignment == null) {
    throw Exception('هیچ شرکتی برای حسابدار تخصیص داده نشده است.');
  }

  final companyData = assignment['companies'];

  if (companyData == null) {
    throw Exception('اطلاعات شرکت حسابدار پیدا نشد.');
  }

  final company = Map<String, dynamic>.from(companyData as Map);

  if (company['is_active'] != true) {
    throw Exception('شرکت تخصیص‌یافته غیرفعال است.');
  }

  return AccountantDashboardData(
    userId: user.id,
    fullName: userData['full_name']?.toString() ?? '',
    email: userData['email']?.toString() ?? user.email ?? '',
    companyId: assignment['company_id']?.toString() ?? '',
    companyName: company['name']?.toString() ?? '',
    companyLegalName: company['legal_name']?.toString(),
    companyNationalId: company['national_id']?.toString(),
    companyPhone: company['phone']?.toString(),
    companyEmail: company['email']?.toString(),
    companyCity: company['city']?.toString(),
    companyProvince: company['province']?.toString(),
    companyLogoUrl: company['logo_url']?.toString(),
  );
});

// ============================================================
// MODEL
// ============================================================

class AccountantDashboardData {
  final String userId;
  final String fullName;
  final String email;

  final String companyId;
  final String companyName;

  final String? companyLegalName;
  final String? companyNationalId;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyCity;
  final String? companyProvince;
  final String? companyLogoUrl;

  const AccountantDashboardData({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.companyId,
    required this.companyName,
    this.companyLegalName,
    this.companyNationalId,
    this.companyPhone,
    this.companyEmail,
    this.companyCity,
    this.companyProvince,
    this.companyLogoUrl,
  });
}
