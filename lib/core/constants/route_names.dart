class RouteNames {
  RouteNames._();

  static const String login = 'login';
  static const String setup = 'setup';
  static const String deviceUnauthorized = 'device-unauthorized';

  static const String dashboard = 'dashboard';
  static const String members = 'members';
  static const String memberDetail = 'member-detail';
  static const String contributions = 'contributions';
  static const String contributionRequests = 'contribution-requests';
  static const String investments = 'investments';
  static const String profitLoss = 'profit-loss';
  static const String withdrawals = 'withdrawals';
  static const String ledger = 'ledger';
  static const String auditLogs = 'audit-logs';
  static const String settings = 'settings';
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String setup = '/setup';
  static const String deviceUnauthorized = '/unauthorized';

  static const String dashboard = '/dashboard';
  static const String members = '/members';
  static const String memberDetail = '/members/:id';
  static const String contributions = '/contributions';
  static const String contributionRequests = '/contribution-requests';
  static const String investments = '/investments';
  static const String profitLoss = '/profit-loss';
  static const String withdrawals = '/withdrawals';
  static const String ledger = '/ledger';
  static const String auditLogs = '/audit-logs';
  static const String settings = '/settings';
}
