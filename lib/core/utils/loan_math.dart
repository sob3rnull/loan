class LoanMath {
  static const String flat = 'flat';
  static const String percentage = 'percentage';

  static double totalRepayable({
    required double principal,
    required double interestValue,
    required String interestType,
  }) {
    if (interestType == percentage) {
      return principal + (principal * interestValue / 100);
    }

    return principal + interestValue;
  }

  static double remaining({
    required double totalRepayable,
    required double amountPaid,
  }) {
    final value = totalRepayable - amountPaid;
    return value < 0 ? 0 : value;
  }
}
