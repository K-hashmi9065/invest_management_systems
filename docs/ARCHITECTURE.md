# Enterprise Flutter Architecture & Operating Standards

This document serves as the authoritative architectural blueprint for the **Investment Management System**. It codifies best practices, design patterns, state management standards, error handling strategies, and resource lifecycles across the codebase.

---

## 1. Clean Feature-First Architecture

The project follows a **Clean Feature-First Architecture** structure to ensure high testability, modularity, and maintainability.

```
lib/
├── app/                  # App initialization, global providers & state invalidation
├── core/                 # Shared foundation across features
│   ├── calculations/    # Financial algorithms (pro-rata profit, percentages)
│   ├── constants/       # App Constants & Route Names
│   ├── database/        # SQLite DatabaseHelper & AppRepository
│   ├── errors/           # AppFailure classes & FailureMapper
│   ├── security/        # PBKDF2 Hasher, RBAC, Device Authorization
│   ├── theme/           # AppColors, AppTheme, AppSpacing, AppTextStyles
│   ├── utils/           # Formatters (Currency, Date)
│   └── widgets/         # Core reusable UI components (AppShell, AsyncValueWidget, StatCard, StatusBadge)
├── features/             # Business feature modules
│   ├── audit_logs/
│   ├── auth/
│   ├── contribution_requests/
│   ├── contributions/
│   ├── dashboard/
│   ├── investments/
│   ├── ledger/
│   ├── members/
│   ├── notifications/
│   ├── profit_loss/
│   ├── settings/
│   └── withdrawals/
└── routes/               # GoRouter configuration & guards
```

---

## 2. Riverpod State Management Standards

1. **Notifier & Future Providers**:
   - Data fetching is handled via `FutureProvider`s scoped by domain (e.g. `groupSummaryProvider`, `membersProvider`, `investmentsProvider`).
   - Authentication and session states use `StateNotifierProvider` (`currentUserProvider`).
2. **Granular Provider Consumption**:
   - Avoid `ref.watch` on top-level multi-data containers inside monolithic widgets.
   - Separate UI elements into focused `ConsumerWidget` classes so that updating `transactionsProvider` only re-renders the `MonthlyActivityChart` without re-rendering stat cards or member summaries.
3. **No Side Effects in `build()`**:
   - `build()` methods must remain pure.
   - Declarative navigation and title resolution are handled at the `AppShell` level via `GoRouterState` matching rather than executing microtasks during widget rendering.
4. **State Invalidation**:
   - Centralized `refreshAllFinancialProviders(ref)` handles invalidating and re-querying all relevant financial data providers upon transaction completions.

---

## 3. Pro Error Handling (`AppFailure` & `FailureMapper`)

1. **Domain Failure Taxonomy**:
   - Raw exceptions from database or network layers are mapped into strongly-typed `AppFailure` subclasses (`DatabaseFailure`, `ValidationFailure`, `FinancialFailure`, `AuthenticationFailure`, `UnknownFailure`).
2. **Failure Mapping**:
   - `FailureMapper.map(error, stackTrace)` inspects errors (including SQLite unique constraints, overdraft checks) and generates user-friendly messages.
3. **UI Error Boundaries**:
   - `AsyncValueWidget` handles loading and error states uniformly.
   - `AppErrorDisplay` displays clear iconology, user-facing error text, and optional `onRetry` callbacks.
   - Dialog forms display error snackbars using `failure.userMessage` with proper `AppColors.danger` formatting.

---

## 4. Theme Tokens & Constants Consistency

- **Centralized Colors (`AppColors`)**: Hairline borders (`border`), dark layered surface hierarchy (`surfacePage`, `surfaceCard`, `surfaceElevated`), semantic state colors (`positive`, `warning`, `danger`, `info`), and a curated chart palette (`chartPalette`).
- **Typography (`AppTextStyles`)**: Google Fonts Inter text styles with standardized font sizes, line heights, and letter spacing.
- **Spacing & Radii (`AppSpacing`)**: Standardized padding increments (`xs: 8`, `sm: 12`, `md: 16`, `lg: 20`, `xl: 24`) and border radiuses (`radiusMd: 8`, `radiusLg: 12`).

---

## 5. Reusable Components & Small Focused Widgets

- **Decomposed Dashboard Subwidgets**:
  - `AdminStatCardsGrid`
  - `FundAllocationChart`
  - `MemberShareChart`
  - `MonthlyActivityChart`
  - `MemberLeaderboardTable`
  - `MemberPortfolioSummaryWidget`
- **Reusable Modal Dialogs**:
  - `AddMemberDialog`
  - `AddInvestmentDialog`
  - `CollectPaymentDialog`
  - `DistributeProfitDialog`
  - `DistributeLossDialog`
  - `RequestWithdrawalDialog`
  - `ChangePasswordDialog`
  - `CreateUserDialog`
  - `AdminResetPasswordDialog`
  - `EditUserRoleDialog`
  - `AddAdjustmentDialog`
  - `RaiseContributionRequestDialog`

---

## 6. Resource Disposal & Memory Safety

- All text editing controllers, focus nodes, scroll controllers, and form states inside modal dialogs are wrapped inside dedicated `StatefulWidget` / `ConsumerStatefulWidget` classes.
- Every `TextEditingController` created is explicitly cleaned up in `dispose()`, preventing memory leaks and dangling listeners.

---

## 7. Rebuild Performance Optimization

- By utilizing granular `ConsumerWidget` subcomponents, widget rebuild trees are minimized:
  - Pie charts rebuild independently when member percentage data updates.
  - Bar charts rebuild independently when transaction logs update.
  - Sidebar and TopBar remain persistent inside `AppShell` with zero blink on route changes.

---

## 8. Testing Guidelines

- **Unit Testing**:
  - `test/password_hasher_test.dart`
  - `test/financial_calculations_test.dart`
  - `test/provider_state_test.dart`
  - `test/rbac_authorization_test.dart`
  - `test/atomic_member_transaction_test.dart`
  - `test/app_failure_test.dart`
  - `test/device_lock_persistence_test.dart`
- **Widget Testing**:
  - `test/reusable_widgets_test.dart` (`StatCard`, `StatusBadge`, `AppErrorDisplay`, `AsyncValueWidget`)
  - `test/error_handling_widget_test.dart`
  - `test/modular_dialogs_widget_test.dart`
  - `test/dialog_resource_disposal_test.dart`
  - `test/widget_test.dart`
- Run static analysis and tests via `dart-mcp-server` tools before committing changes.
