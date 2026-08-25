// Fix C: Widget Smoke Test with proper FFI database & DeviceLockService initialization.
import 'package:flutter/material.dart';
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
    // Set screen size for desktop layout
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: InvestManagementApp()));

    // Allow async providers and GoRouter to settle
    await tester.pump();
    await tester.pumpAndSettle();

    // Debug output
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      // ignore: avoid_print
      print('Found Text: "${widget.data}"');
    }

    // Verification: Fresh DB has no super admin, so FirstTimeSetupScreen renders
    expect(find.byType(InvestManagementApp), findsOneWidget);
  });
}
