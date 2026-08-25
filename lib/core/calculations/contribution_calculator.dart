class ContributionCalculator {
  ContributionCalculator._();

  /// Calculates percentage of member contribution relative to total group contribution.
  /// Returns 0.0 if total group contribution is 0 or negative to prevent divide-by-zero.
  static double percentageOf(int memberPaise, int totalPaise) {
    if (totalPaise <= 0) return 0.0;
    return (memberPaise / totalPaise) * 100;
  }
}
