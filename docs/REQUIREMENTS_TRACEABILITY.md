# GROUP INVESTMENT MANAGEMENT — REQUIREMENTS TRACEABILITY MATRIX

This document establishes full bidirectional traceability between the Software Requirements Specification (SRS), system architecture, code implementation, and test suites.

---

## Traceability Matrix

| Requirement ID | Requirement | Role | Feature | Screen | Provider / Controller | Repository | Database Table | Tests | Status |
|---|---|---|---|---|---|---|---|---|:---:|
| **REQ-AUTH-01** | User authentication via username & password | ALL | Authentication | `login_screen.dart` | `loginControllerProvider` | `AppRepository` | `users` | `financial_calculations_test.dart` | Completed |
| **REQ-AUTH-02** | Super Admin first-time setup wizard | SUPER_ADMIN | Setup | `first_time_setup_screen.dart` | `setupControllerProvider` | `AppRepository` | `users` | `financial_calculations_test.dart` | Completed |
| **REQ-SEC-01** | Hardware MachineGuid device authorization lock | ALL | Security | `device_unauthorized_screen.dart` | `machineGuidProvider` | `DeviceLockService` | `config/device_lock.json` | `rbac_authorization_test.dart` | Completed |
| **REQ-SEC-02** | Route-level Role-Based Access Control (RBAC) | ALL | Security & Router | `app_router.dart` | `routerProvider` | `AuthorizationService` | N/A | `rbac_authorization_test.dart` | Completed |
| **REQ-SEC-03** | Riverpod-only state management (No setState) | N/A | Architecture | All Screens | All Notifiers | N/A | N/A | Static Analysis Grep | Completed |
| **REQ-SEC-04** | Typed exception masking (AppFailure) | ALL | Error Handling | `AsyncValueWidget` | `FailureMapper` | All Repositories | N/A | `app_failure_test.dart` | Completed |
| **REQ-MEM-01** | Member directory viewing & search | MEMBER / ADMIN / SUPER_ADMIN | Members | `members_screen.dart` | `membersProvider`, `memberSearchQueryProvider` | `AppRepository` | `members` | Unit/Widget | Completed |
| **REQ-MEM-02** | Transactional member & user creation | ADMIN / SUPER_ADMIN | Members | `members_screen.dart` | `membersProvider` | `AppRepository` | `members`, `users` | Integration | Phase C |
| **REQ-CON-01** | Record member contributions & approval flow | ADMIN / SUPER_ADMIN | Contributions | `contributions_screen.dart` | `contributionsProvider` | `AppRepository` | `contributions` | Financial calc | In Progress |
| **REQ-CON-02** | Contribution percentage calculation formula | ALL | Contributions | `dashboard_screen.dart` | `groupSummaryProvider` | `AppRepository` | `contributions` | `financial_calculations_test.dart` | Completed |
| **REQ-INV-01** | Track group investments & returns | ADMIN / SUPER_ADMIN | Investments | `investments_screen.dart` | `investmentsProvider` | `AppRepository` | `investments` | Financial calc | In Progress |
| **REQ-PROF-01** | Calculate pro-rata profit/loss distribution | ALL | Profit & Loss | `profit_loss_screen.dart` | `profitDistributionsProvider` | `AppRepository` | `profit_distributions` | `financial_calculations_test.dart` | Completed |
| **REQ-LOSS-01** | Dedicated loss distribution workflow | ADMIN / SUPER_ADMIN | Profit & Loss | `profit_loss_screen.dart` | `profitDistributionsProvider` | `AppRepository` | `profit_distributions` | Dedicated loss test | Phase C |
| **REQ-WTH-01** | Member withdrawal requests & approval | MEMBER / ADMIN / SUPER_ADMIN | Withdrawals | `withdrawals_screen.dart` | `withdrawalsProvider` | `AppRepository` | `withdrawals` | Financial calc | In Progress |
| **REQ-LED-01** | Master financial transaction ledger | ALL | Ledger | `ledger_screen.dart` | `transactionsProvider`, `ledgerFilterProvider` | `AppRepository` | `transactions` | Financial calc | Completed |
| **REQ-SET-01** | System settings & device lock management | SUPER_ADMIN ONLY | Settings | `settings_screen.dart` | `deviceLockStateProvider` | `DeviceLockService` | `config/device_lock.json` | `rbac_authorization_test.dart` | Completed |
| **REQ-AUD-01** | Audit log tracking for critical operations | SUPER_ADMIN / ADMIN | Audit Logs | `audit_logs_screen.dart` | `auditLogsProvider` | `AppRepository` | `audit_logs` | Audit trail test | In Progress |
