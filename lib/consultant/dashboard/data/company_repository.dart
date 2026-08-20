import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/company_model.dart';

class CompanyRepository {
  final client = Supabase.instance.client;

  Future<CompanyModel> fetchCompany(String companyId) async {
    final data =
        await client.from('companies').select().eq('id', companyId).single();

    return CompanyModel.fromMap(data);
  }
}
