class BankingDashboardModel {
  final String companyName;

  final double bankBalance;
  final double cashBalance;
  final double receivedChecks;
  final double paidChecks;

  const BankingDashboardModel({
    required this.companyName,
    required this.bankBalance,
    required this.cashBalance,
    required this.receivedChecks,
    required this.paidChecks,
  });
}