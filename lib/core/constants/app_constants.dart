class AppConstants {
  AppConstants._();

  static const String appName = 'Group Investment Management';
  static const String appVersion = '1.0.0';
  static const String currencySymbol = '₹';

  // Role Constants
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleAdmin = 'ADMIN';
  static const String roleMember = 'MEMBER';

  // Financial Transaction Types
  static const String txContribution = 'CONTRIBUTION';
  static const String txWithdrawal = 'WITHDRAWAL';
  static const String txInvestment = 'INVESTMENT';
  static const String txReturn = 'INVESTMENT_RETURN';
  static const String txProfit = 'PROFIT';
  static const String txLoss = 'LOSS';
  static const String txAdjustment = 'ADJUSTMENT';

  // Status Constants
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusActive = 'ACTIVE';
  static const String statusInactive = 'INACTIVE';
  static const String statusCompleted = 'COMPLETED';
}
