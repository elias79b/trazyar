import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/companies/application/companies_provider.dart';

final companyControllerProvider =
    StateNotifierProvider<CompanyController, bool>(
      (ref) => CompanyController(ref),
    );

class CompanyController extends StateNotifier<bool> {
  CompanyController(this.ref) : super(false);

  final Ref ref;

  Future<void> createCompany({
    required BuildContext context,
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
    bool isActive = true,
  }) async {
    if (state) return;

    state = true;

    try {
      await ref
          .read(companyRepositoryProvider)
          .createCompany(
            name: name,
            legalName: _nullable(legalName),
            nationalId: _nullable(nationalId),
            economicCode: _nullable(economicCode),
            phone: _nullable(phone),
            email: _nullable(email),
            website: _nullable(website),
            address: _nullable(address),
            city: _nullable(city),
            province: _nullable(province),
            postalCode: _nullable(postalCode),
            isActive: isActive,
          );

      ref.invalidate(companiesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شرکت با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت شرکت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = false;
    }
  }

  Future<void> updateCompany({
    required BuildContext context,
    required String companyId,
    required String name,
    String? email,
    String? phone,
    String? website,
    String? address,
  }) async {
    if (state) return;

    state = true;

    try {
      await ref
          .read(companyRepositoryProvider)
          .updateCompany(
            companyId: companyId,
            name: name,
            email: _nullable(email),
            phone: _nullable(phone),
            website: _nullable(website),
            address: _nullable(address),
          );

      ref.invalidate(companiesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اطلاعات شرکت با موفقیت ویرایش شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ویرایش شرکت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = false;
    }
  }

  Future<void> toggleCompanyStatus({
    required BuildContext context,
    required String companyId,
    required bool isActive,
  }) async {
    if (state) return;

    state = true;

    try {
      await ref
          .read(companyRepositoryProvider)
          .updateCompanyStatus(companyId: companyId, isActive: isActive);

      ref.invalidate(companiesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'شرکت فعال شد' : 'شرکت غیرفعال شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تغییر وضعیت شرکت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = false;
    }
  }

  Future<void> deleteCompany({
    required BuildContext context,
    required String companyId,
  }) async {
    if (state) return;

    state = true;

    try {
      await ref.read(companyRepositoryProvider).deleteCompany(companyId);

      ref.invalidate(companiesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شرکت با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف شرکت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidate(companiesProvider);

    await ref.read(companiesProvider.future);
  }

  String? _nullable(String? value) {
    if (value == null) {
      return null;
    }

    final result = value.trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }
}
