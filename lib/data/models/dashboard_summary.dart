class DashboardSummary {
  const DashboardSummary({
    required this.activeLoansCount,
    required this.totalPrincipal,
    required this.totalCollected,
    required this.totalRemaining,
    required this.overdueLoansCount,
  });

  final int activeLoansCount;
  final double totalPrincipal;
  final double totalCollected;
  final double totalRemaining;
  final int overdueLoansCount;

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      activeLoansCount: 0,
      totalPrincipal: 0,
      totalCollected: 0,
      totalRemaining: 0,
      overdueLoansCount: 0,
    );
  }
}

