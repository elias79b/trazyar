import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/company_model.dart';

class CompanyRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<CompanyModel> fetchCompany(String companyId) async {
    final response =
        await _client.from('companies').select().eq('id', companyId).single();

    return CompanyModel.fromMap(response);
  }
}
