import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_management_systems/core/theme/app_colors.dart';
import 'package:invest_management_systems/core/widgets/async_value_widget.dart';
import 'package:invest_management_systems/core/widgets/stat_card.dart';
import 'package:invest_management_systems/core/widgets/status_badge.dart';

void main() {
  group('Reusable Core Widgets Widget Tests', () {
    testWidgets('StatCard renders title, value, subtitle, and icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total Approved Pool',
              value: '₹1,500,000.00',
              subtitle: '10 Active Members',
              icon: Icons.account_balance,
              iconColor: AppColors.accent,
            ),
          ),
        ),
      );

      expect(find.text('Total Approved Pool'), findsOneWidget);
      expect(find.text('₹1,500,000.00'), findsOneWidget);
      expect(find.text('10 Active Members'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('StatusBadge renders APPROVED status badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'APPROVED'),
          ),
        ),
      );

      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('AppErrorDisplay renders user message and triggers onRetry on button click', (tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorDisplay(
              message: 'Failed to load member records.',
              onRetry: () => retryClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load member records.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryClicked, isTrue);
    });

    testWidgets('AsyncValueWidget displays loading indicator when loading', (tester) async {
      const AsyncValue<String> asyncState = AsyncValue<String>.loading();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncState,
              data: Text.new,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AsyncValueWidget displays data widget when data is present', (tester) async {
      const AsyncValue<String> asyncState = AsyncValue<String>.data('Financial Data Loaded');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncState,
              data: Text.new,
            ),
          ),
        ),
      );

      expect(find.text('Financial Data Loaded'), findsOneWidget);
    });

    testWidgets('AsyncValueWidget displays error widget on error state', (tester) async {
      final asyncState = AsyncValue<String>.error(
        Exception('Network Failure'),
        StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncState,
              data: Text.new,
            ),
          ),
        ),
      );

      expect(find.byType(AppErrorDisplay), findsOneWidget);
    });
  });
}
