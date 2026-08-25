class ProfitCalculator {
  ProfitCalculator._();

  /// Calculates member share of total profit in paise based on member's contribution percentage.
  /// Supports positive profits and negative values (losses).
  static int memberShare(int totalProfitPaise, double memberPercentage) {
    return (totalProfitPaise * (memberPercentage / 100)).round();
  }
}
