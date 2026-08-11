class ReportSummaryModel {
  final int totalUsers;
  final int activeUsers;
  final int totalCompanies;
  final int activeCompanies;
  final int activeSubscriptions;
  final double monthlyRevenue;
  final double yearlyRevenue;
  final int todayLogins;
  final int onlineUsers;
  final int todayActivities;

  const ReportSummaryModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalCompanies,
    required this.activeCompanies,
    required this.activeSubscriptions,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.todayLogins,
    required this.onlineUsers,
    required this.todayActivities,
  });

  factory ReportSummaryModel.empty() {
    return const ReportSummaryModel(
      totalUsers: 0,
      activeUsers: 0,
      totalCompanies: 0,
      activeCompanies: 0,
      activeSubscriptions: 0,
      monthlyRevenue: 0,
      yearlyRevenue: 0,
      todayLogins: 0,
      onlineUsers: 0,
      todayActivities: 0,
    );
  }

  factory ReportSummaryModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ReportSummaryModel.empty();
    }

    return ReportSummaryModel(
      totalUsers: (map['total_users'] ?? 0) as int,
      activeUsers: (map['active_users'] ?? 0) as int,
      totalCompanies: (map['total_companies'] ?? 0) as int,
      activeCompanies: (map['active_companies'] ?? 0) as int,
      activeSubscriptions: (map['active_subscriptions'] ?? 0) as int,
      monthlyRevenue:
      (map['monthly_revenue'] ?? 0).toDouble(),
      yearlyRevenue:
      (map['yearly_revenue'] ?? 0).toDouble(),
      todayLogins: (map['today_logins'] ?? 0) as int,
      onlineUsers: (map['online_users'] ?? 0) as int,
      todayActivities: (map['today_activities'] ?? 0) as int,
    );
  }
}