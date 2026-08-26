// Fix B: Router redirect integration test.
//
// Approach used: ProviderContainer with fakes for appRepositoryProvider and
// currentUserProvider, then GoRouter is created directly from routerProvider
// driven by those overrides. We drive router.redirect() directly instead of
// pumping a full widget tree — this avoids the overhead of rendering screens
// while still exercising the real redirect() callback inside app_router.dart.
//
// Why not widget-level? GoRouter's redirect() in this project is async and
// reads Riverpod providers. Constructing a GoRouter via the real routerProvider
// and supplying a ProviderContainer lets us call router.redirect() in isolation
// without a BuildContext. The trade-off is that we cannot drive actual
// navigation events (like GoRouter.of(context).go), but we CAN confirm the
// redirect() return value for any arbitrary location — which is exactly what
// the RBAC check guards.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invest_management_systems/app/app_providers.dart';
import 'package:invest_management_systems/core/constants/app_constants.dart';
import 'package:invest_management_systems/core/constants/route_names.dart';
import 'package:invest_management_systems/core/database/app_repository.dart';
import 'package:invest_management_systems/core/database/database_helper.dart';
import 'package:invest_management_systems/core/security/device_lock_service.dart';
import 'package:invest_management_systems/features/auth/domain/user_model.dart';
import 'package:invest_management_systems/routes/app_router.dart';

/// Minimal fake repository that controls isFirstTimeSetupNeeded.
class _FakeRepository extends AppRepository {
  final bool setupNeeded;
  _FakeRepository({this.setupNeeded = false});

  @override
  Future<bool> isFirstTimeSetupNeeded() async => setupNeeded;
}

/// Helper: build a GoRouter from routerProvider with the given provider overrides
/// and return it. The container keeps providers alive for the duration of the test.
(ProviderContainer, GoRouter) _buildRouter({
  UserModel? currentUser,
  bool setupNeeded = false,
}) {
  final container = ProviderContainer(
    overrides: [
      appRepositoryProvider.overrideWithValue(_FakeRepository(setupNeeded: setupNeeded)),
      currentUserProvider.overrideWith(
        (ref) {
          final notifier = CurrentUserNotifier();
          if (currentUser != null) notifier.setUser(currentUser);
          return notifier;
        },
      ),
    ],
  );
  final router = container.read(routerProvider);
  return (container, router);
}

/// Dummy BuildContext for signature compatibility — the redirect() callback
/// in app_router.dart reads from Riverpod ref, not BuildContext, so this is safe.
class _DummyBuildContext extends Fake implements BuildContext {}

/// GoRouter extension for testability: calls appRedirect directly using the container.
extension _GoRouterTestExt on GoRouter {
  Future<String?> redirect(ProviderContainer container, String location) async {
    final state = GoRouterState(
      configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      name: null,
      path: location,
      fullPath: location,
      pathParameters: const {},
      extra: null,
      error: null,
      pageKey: ValueKey(location),
    );
    return appRedirect(
      read: container.read,
      context: _DummyBuildContext(),
      state: state,
    );
  }
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DeviceLockService.initialize();
  });

  setUp(() async {
    DatabaseHelper.testDbPath = inMemoryDatabasePath;
    await DatabaseHelper.resetForTest();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTest();
    DatabaseHelper.testDbPath = null;
  });

  final memberUser = UserModel(
    id: 1,
    fullName: 'Test Member',
    username: 'member1',
    role: AppConstants.roleMember,
    createdAt: DateTime.now().toIso8601String(),
  );
  final adminUser = UserModel(
    id: 2,
    fullName: 'Test Admin',
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

  group('router redirect() – Fix B: RBAC enforced by real redirect callback', () {
    test('MEMBER navigating to /settings → redirected to /dashboard', () async {
      final (container, router) = _buildRouter(currentUser: memberUser);
      addTearDown(container.dispose);
      final result = await router.redirect(container, RoutePaths.settings);
      expect(result, equals(RoutePaths.dashboard));
    });

    test('MEMBER navigating to /audit-logs → redirected to /dashboard', () async {
      final (container, router) = _buildRouter(currentUser: memberUser);
      addTearDown(container.dispose);
      final result = await router.redirect(container, RoutePaths.auditLogs);
      expect(result, equals(RoutePaths.dashboard));
    });

    test('ADMIN navigating to /settings → allowed (redirect returns null)', () async {
      final (container, router) = _buildRouter(currentUser: adminUser);
      addTearDown(container.dispose);
      final result = await router.redirect(container, RoutePaths.settings);
      expect(result, isNull);
    });

    test('SUPER_ADMIN navigating to /settings → allowed (redirect returns null)',
        () async {
      final (container, router) = _buildRouter(currentUser: superAdminUser);
      addTearDown(container.dispose);
      final result = await router.redirect(container, RoutePaths.settings);
      expect(result, isNull,
          reason: 'SUPER_ADMIN should be allowed; redirect must return null');
    });

    test('Unauthenticated user navigating to /dashboard → redirected to /login',
        () async {
      final (container, router) = _buildRouter(currentUser: null);
      addTearDown(container.dispose);
      final result = await router.redirect(container, RoutePaths.dashboard);
      expect(result, equals(RoutePaths.login));
    });
  });
}
