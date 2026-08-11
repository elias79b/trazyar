import 'package:flutter/material.dart';

import 'company_management_page.dart';

/// Backwards-compatible route entry point for Owner > Companies.
///
/// The management UI has a single implementation in [CompanyManagementPage].
class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});

  @override
  Widget build(BuildContext context) => const CompanyManagementPage();
}
