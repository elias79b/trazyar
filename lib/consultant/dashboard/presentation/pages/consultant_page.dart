import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';

import '../../application/consultant_dashboard_provider.dart';
import '../../data/consultant_dashboard_repository.dart';

class ConsultantPage extends ConsumerWidget {
  const ConsultantPage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final profileAsync =
    ref.watch(
      consultantProfileProvider,
    );

    final companiesAsync =
    ref.watch(
      consultantCompaniesProvider,
    );

    return OwnerScaffold(
      currentRoute: '/consultant',
      title: 'داشبورد مشاور',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            consultantProfileProvider,
          );

          ref.invalidate(
            consultantCompaniesProvider,
          );

          await ref.read(
            consultantCompaniesProvider.future,
          );
        },
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.only(
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                loading: () =>
                const _WelcomeSkeleton(),
                error: (
                    error,
                    stack,
                    ) =>
                    _WelcomeCard(
                      fullName:
                      'مشاور ترازیار',
                      email:
                      '',
                    ),
                data: (profile) {
                  final fullName =
                  (profile?['full_name'] ??
                      'مشاور ترازیار')
                      .toString();

                  final email =
                  (profile?['email'] ??
                      '')
                      .toString();

                  return _WelcomeCard(
                    fullName:
                    fullName,
                    email:
                    email,
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              companiesAsync.when(
                loading: () =>
                const _DashboardLoading(),
                error: (
                    error,
                    stack,
                    ) =>
                    _ErrorCard(
                      error:
                      error.toString(),
                      onRetry: () {
                        ref.invalidate(
                          consultantCompaniesProvider,
                        );
                      },
                    ),
                data: (companies) {
                  return _DashboardContent(
                    companies:
                    companies,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WELCOME
// ============================================================

class _WelcomeCard
    extends StatelessWidget {
  const _WelcomeCard({
    required this.fullName,
    required this.email,
  });

  final String fullName;
  final String email;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
          ],
          begin:
          Alignment.topRight,
          end:
          Alignment.bottomLeft,
        ),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),
            child: const Icon(
              Icons
                  .support_agent_rounded,
              color:
              Color(0xFF1B4332),
              size: 34,
            ),
          ),
          const SizedBox(
            width: 18,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'خوش آمدید',
                  style: TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 24,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color:
                      Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTENT
// ============================================================

class _DashboardContent
    extends StatelessWidget {
  const _DashboardContent({
    required this.companies,
  });

  final List<ConsultantCompany>
  companies;

  @override
  Widget build(
      BuildContext context,
      ) {
    final activeCompanies =
        companies
            .where(
              (company) =>
          company.isActive,
        )
            .length;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title:
          'نمای کلی',
          subtitle:
          'خلاصه وضعیت فعالیت‌های مشاوره‌ای شما',
        ),

        const SizedBox(
          height: 16,
        ),

        LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            final width =
                constraints.maxWidth;

            final count =
            width >= 1200
                ? 4
                : width >= 700
                ? 2
                : 1;

            return GridView.count(
              crossAxisCount:
              count,
              shrinkWrap:
              true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing:
              16,
              mainAxisSpacing:
              16,
              childAspectRatio:
              2.5,
              children: [
                _StatCard(
                  title:
                  'شرکت‌های من',
                  value:
                  '${companies.length}',
                  icon:
                  Icons.business_rounded,
                ),
                _StatCard(
                  title:
                  'شرکت‌های فعال',
                  value:
                  '$activeCompanies',
                  icon:
                  Icons.check_circle_outline,
                ),
                _StatCard(
                  title:
                  'گزارش‌های در انتظار',
                  value:
                  '۰',
                  icon:
                  Icons
                      .description_outlined,
                ),
                _StatCard(
                  title:
                  'اقدامات باز',
                  value:
                  '۰',
                  icon:
                  Icons
                      .task_alt_outlined,
                ),
              ],
            );
          },
        ),

        const SizedBox(
          height: 28,
        ),

        _SectionTitle(
          title:
          'شرکت‌های تحت پوشش',
          subtitle:
          'شرکت‌هایی که برای شما اختصاص داده شده‌اند',
        ),

        const SizedBox(
          height: 16,
        ),

        if (companies.isEmpty)
          const _EmptyCompanies()
        else
          LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              final isWide =
                  constraints.maxWidth >=
                      850;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap:
                  true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                    500,
                    crossAxisSpacing:
                    16,
                    mainAxisSpacing:
                    16,
                    mainAxisExtent:
                    170,
                  ),
                  itemCount:
                  companies.length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    return _CompanyCard(
                      company:
                      companies[index],
                    );
                  },
                );
              }

              return Column(
                children:
                companies
                    .map(
                      (
                      company,
                      ) =>
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child:
                        _CompanyCard(
                          company:
                          company,
                        ),
                      ),
                )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          subtitle,
          style:
          TextStyle(
            fontSize: 13,
            color:
            Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard
    extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        side:
        BorderSide(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFF1B4332,
                ).withOpacity(.10),
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                icon,
                color:
                const Color(
                  0xFF1B4332,
                ),
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                    const TextStyle(
                      fontSize: 23,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    title,
                    style:
                    TextStyle(
                      fontSize: 12,
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPANY CARD
// ============================================================

class _CompanyCard
    extends StatelessWidget {
  const _CompanyCard({
    required this.company,
  });

  final ConsultantCompany
  company;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        side:
        BorderSide(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            _CompanyLogo(
              company:
              company,
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons
                            .location_on_outlined,
                        size: 15,
                        color:
                        Colors.grey.shade600,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          company.location,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons
                            .phone_outlined,
                        size: 15,
                        color:
                        Colors.grey.shade600,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          company.contact,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                company.isActive
                    ? Colors.green
                    .withOpacity(.10)
                    : Colors.grey
                    .withOpacity(.10),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                company.isActive
                    ? 'فعال'
                    : 'غیرفعال',
                style:
                TextStyle(
                  color:
                  company.isActive
                      ? Colors.green
                      : Colors.grey,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPANY LOGO
// ============================================================

class _CompanyLogo
    extends StatelessWidget {
  const _CompanyLogo({
    required this.company,
  });

  final ConsultantCompany
  company;

  @override
  Widget build(
      BuildContext context,
      ) {
    final logo =
    company.logoUrl?.trim();

    return Container(
      width: 58,
      height: 58,
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF1B4332,
        ).withOpacity(.08),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child:
        logo != null &&
            logo.isNotEmpty
            ? Image.network(
          logo,
          fit:
          BoxFit.cover,
          errorBuilder:
              (
              context,
              error,
              stack,
              ) {
            return const Icon(
              Icons
                  .business_outlined,
              color:
              Color(
                0xFF1B4332,
              ),
              size: 28,
            );
          },
        )
            : const Icon(
          Icons
              .business_outlined,
          color:
          Color(
            0xFF1B4332,
          ),
          size: 28,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyCompanies
    extends StatelessWidget {
  const _EmptyCompanies();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(40),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .business_center_outlined,
            size: 52,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'هنوز شرکتی به شما اختصاص داده نشده است.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontWeight:
              FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'برای دسترسی به اطلاعات شرکت‌ها، مالک سیستم باید شرکت موردنظر را به حساب شما اختصاص دهد.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration:
      BoxDecoration(
        color:
        Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color:
            Colors.red.shade700,
            size: 42,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'خطا در دریافت اطلاعات شرکت‌ها',
            style:
            TextStyle(
              color:
              Colors.red.shade700,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            error,
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.red.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon:
            const Icon(
              Icons.refresh,
            ),
            label:
            const Text(
              'تلاش مجدد',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOADING
// ============================================================

class _DashboardLoading
    extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const SizedBox(
      height: 350,
      child: Center(
        child:
        CircularProgressIndicator(),
      ),
    );
  }
}

class _WelcomeSkeleton
    extends StatelessWidget {
  const _WelcomeSkeleton();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      height: 115,
      width: double.infinity,
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFF1B4332,
        ),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: const Center(
        child:
        CircularProgressIndicator(
          color:
          Colors.white,
        ),
      ),
    );
  }
}