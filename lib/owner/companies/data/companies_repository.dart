import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/company_model.dart';

class CompanyRepository {
  CompanyRepository()
      : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CompanyModel>> getCompanies() async {
    final response = await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => CompanyModel.fromMap(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  Future<CompanyModel> updateCompany({
    required String companyId,
    required String name,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? logo,
  }) async {
    final response = await _client
        .from('companies')
        .update({
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'logo': logo,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', companyId)
        .select()
        .single();

    return CompanyModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<CompanyModel> updateCompanyStatus({
    required String companyId,
    required bool isActive,
  }) async {
    final response = await _client
        .from('companies')
        .update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', companyId)
        .select()
        .single();

    return CompanyModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> deleteCompany(String companyId) async {
    await _client
        .from('companies')
        .delete()
        .eq('id', companyId);
  }

  Future<CompanyModel?> getCompanyById(
      String companyId,
      ) async {
    final response = await _client
        .from('companies')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    if (response == null) return null;

    return CompanyModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
  Future<void> createCompany({
    required String name,
    String? legalName,
    String? nationalId,
    String? economicCode,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    String? logo,
    bool isActive = true,
  }) async {
    await Supabase.instance.client
        .from('companies')
        .insert({
      'name': name,
      'legal_name': legalName,
      'national_id': nationalId,
      'economic_code': economicCode,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'logo': logo,
      'is_active': isActive,
    });
  }
}