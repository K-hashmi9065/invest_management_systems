// Fix C: Widget Smoke Test with proper FFI database & DeviceLockService initialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invest_management_systems/app/app.dart';
import 'package:invest_management_systems/core/database/database_helper.dart';
import 'package:invest_management_systems/core/security/device_lock_service.dart';

void main() {
  setUpAll(() async {
    // Initialize FFI for SQLite in desktop test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialize Device Lock service
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

  testWidgets('App renders correctly on launch', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: InvestManagementApp(),
      ),
    );

    // Allow async providers (isFirstTimeSetupNeeded, GoRouter redirect) to settle
    await tester.pumpAndSettle();

    // Verification: Fresh DB has no super admin, so FirstTimeSetupScreen renders
    expect(find.text('System Initial Setup'), findsOneWidget);
  });
}
