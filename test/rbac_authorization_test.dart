import 'package:flutter_test/flutter_test.dart';
import 'package:invest_management_systems/core/constants/app_constants.dart';
import 'package:invest_management_systems/core/constants/route_names.dart';
import 'package:invest_management_systems/core/security/app_permissions.dart';
import 'package:invest_management_systems/features/auth/domain/user_model.dart';

void main() {
  group('RBAC & Route Authorization Tests', () {
    final memberUser = UserModel(
      id: 1,
      fullName: 'John Member',
      username: 'member1',
      role: AppConstants.roleMember,
      createdAt: DateTime.now().toIso8601String(),
    );

    final adminUser = UserModel(
      id: 2,
      fullName: 'Alice Admin',
      username: 'admin1',
      role: AppConstants.roleAdmin,
      createdAt: DateTime.now().toIso8601String(),
    );

    final superAdminUser = UserModel(
      id: 3,
      fullName: 'Super Boss',
      username: 'superadmin',
      role: AppConstants.roleSuperAdmin,
      createdAt: DateTime.now().toIso8601String(),
    );

    test('MEMBER route access rules per matrix', () {
      expect(AuthorizationService.canAccessRoute(RoutePaths.dashboard, memberUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.members, memberUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.contributions, memberUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.withdrawals, memberUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.ledger, memberUser), isTrue);
      
      // DENIED routes for MEMBER
      expect(AuthorizationService.canAccessRoute(RoutePaths.settings, memberUser), isFalse);
      expect(AuthorizationService.canAccessRoute(RoutePaths.auditLogs, memberUser), isFalse);
    });

    test('ADMIN route access rules per matrix', () {
      expect(AuthorizationService.canAccessRoute(RoutePaths.dashboard, adminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.members, adminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.contributions, adminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.auditLogs, adminUser), isTrue);

      // DENIED routes for ADMIN
      expect(AuthorizationService.canAccessRoute(RoutePaths.settings, adminUser), isFalse);
    });

    test('SUPER_ADMIN full route access', () {
      expect(AuthorizationService.canAccessRoute(RoutePaths.dashboard, superAdminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.settings, superAdminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.auditLogs, superAdminUser), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.members, superAdminUser), isTrue);
    });

    test('Unauthenticated user cannot access protected routes', () {
      expect(AuthorizationService.canAccessRoute(RoutePaths.dashboard, null), isFalse);
      expect(AuthorizationService.canAccessRoute(RoutePaths.settings, null), isFalse);
      expect(AuthorizationService.canAccessRoute(RoutePaths.login, null), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.setup, null), isTrue);
      expect(AuthorizationService.canAccessRoute(RoutePaths.deviceUnauthorized, null), isTrue);
    });

    test('Fine-grained permissions checking', () {
      expect(RolePermissions.hasPermission(AppConstants.roleMember, AppPermission.manageSettings), isFalse);
      expect(RolePermissions.hasPermission(AppConstants.roleSuperAdmin, AppPermission.manageSettings), isTrue);
      expect(RolePermissions.hasPermission(AppConstants.roleAdmin, AppPermission.manageMembers), isTrue);
    });
  });
}
