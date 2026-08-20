import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/consultant_company.dart';

class ConsultantCompaniesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ConsultantCompany>> fetchMyCompanies() async {

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد نشده است',
      );
    }


    final result = await _client
        .from('consultant_company_assignments')
        .select('''
        company_id,
        companies(
          id,
          name,
          city,
          is_active
        )
      ''')
        .eq(
      'consultant_user_id',
      user.id,
    )
        .eq(
      'is_active',
      true,
    );


    return result.map((item) {

      return ConsultantCompany.fromMap(
        item['companies'],
      );

    }).toList();
  }
}
