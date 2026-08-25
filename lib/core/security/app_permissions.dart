import '../constants/app_constants.dart';
import '../constants/route_names.dart';
import '../../features/auth/domain/user_model.dart';

/// Fine-grained permissions used throughout the system.
enum AppPermission {
  viewDashboard,
  viewOwnProfile,
  viewMembers,
  manageMembers,
  viewContributions,
  manageContributions,
  viewContributionRequests,
  manageContributionRequests,
  viewInvestments,
  manageInvestments,
  viewProfitLoss,
  manageProfitLoss,
  viewWithdrawals,
  manageWithdrawals,
  viewLedger,
  manageUsers,
  viewAuditLogs,
  manageSettings,
  manageDeviceLock,
}

/// Centralized role-to-permissions mapping matrix.
class RolePermissions {
  RolePermissions._();

  static final Map<String, Set<AppPermission>> _roleMap = {
    AppConstants.roleSuperAdmin: AppPermission.values.toSet(),
    AppConstants.roleAdmin: {
      AppPermission.viewDashboard,
      AppPermission.viewOwnProfile,
      AppPermission.viewMembers,
      AppPermission.manageMembers,
      AppPermission.viewContributions,
      AppPermission.manageContributions,
      AppPermission.viewContributionRequests,
      AppPermission.manageContributionRequests,
      AppPermission.viewInvestments,
      AppPermission.manageInvestments,
      AppPermission.viewProfitLoss,
      AppPermission.manageProfitLoss,
      AppPermission.viewWithdrawals,
      AppPermission.manageWithdrawals,
      AppPermission.viewLedger,
      AppPermission.manageUsers,
      AppPermission.viewAuditLogs,
    },
    AppConstants.roleMember: {
      AppPermission.viewDashboard,
      AppPermission.viewOwnProfile,
      AppPermission.viewMembers,
      AppPermission.viewContributions,
      AppPermission.viewContributionRequests,
      AppPermission.viewInvestments,
      AppPermission.viewProfitLoss,
      AppPermission.viewWithdrawals,
      AppPermission.viewLedger,
    },
  };

  /// Check if a given role string possesses a specific permission.
  static bool hasPermission(String? role, AppPermission permission) {
    if (role == null) return false;
    final permissions = _roleMap[role];
    return permissions?.contains(permission) ?? false;
  }

  /// Get all permissions for a given role.
  static Set<AppPermission> getPermissionsForRole(String? role) {
    if (role == null) return {};
    return _roleMap[role] ?? {};
  }
}

/// Service providing security authorization checks for UI routes and actions.
class AuthorizationService {
  AuthorizationService._();

  /// Check if user has access to perform an action requiring a specific permission.
  static bool canPerform(UserModel? user, AppPermission permission) {
    if (user == null) return false;
    return RolePermissions.hasPermission(user.role, permission);
  }

  /// Centralized Route Access Control matrix per SRS & Security rules.
  static bool canAccessRoute(String location, UserModel? user) {
    // Unrestricted / System routes
    if (location == RoutePaths.login ||
        location == RoutePaths.setup ||
        location == RoutePaths.deviceUnauthorized) {
      return true;
    }

    if (user == null) return false;

    // Route-level permission mappings
    switch (location) {
      case RoutePaths.dashboard:
        return canPerform(user, AppPermission.viewDashboard);

      case RoutePaths.members:
        return canPerform(user, AppPermission.viewMembers);

      case RoutePaths.contributions:
        return canPerform(user, AppPermission.viewContributions);

      case RoutePaths.contributionRequests:
        return canPerform(user, AppPermission.viewContributionRequests);

      case RoutePaths.investments:
        return canPerform(user, AppPermission.viewInvestments);

      case RoutePaths.profitLoss:
        return canPerform(user, AppPermission.viewProfitLoss);

      case RoutePaths.withdrawals:
        return canPerform(user, AppPermission.viewWithdrawals);

      case RoutePaths.ledger:
        return canPerform(user, AppPermission.viewLedger);

      case RoutePaths.auditLogs:
        return canPerform(user, AppPermission.viewAuditLogs);

      case RoutePaths.settings:
        return canPerform(user, AppPermission.manageSettings);

      default:
        // Handle parameterized routes like /members/:id
        if (location.startsWith('/members/')) {
          return canPerform(user, AppPermission.viewMembers);
        }
        // Deny unknown protected routes by default
        return false;
    }
  }
}
