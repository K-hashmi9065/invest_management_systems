# GROUP INVESTMENT MANAGEMENT — IMPLEMENTATION CHECKLIST

Legend:
- `[ ]` Not started
- `[-]` In progress
- `[x]` Completed
- `[!]` Blocked

---

## Phase A — Security Foundation
- [x] Riverpod-only state management requirement enforced
- [x] Remove every `setState` usage across codebase
- [x] Implement centralized RBAC & fine-grained permission model (`app_permissions.dart`)
- [x] Add router-level access control guard (`app_router.dart`)
- [x] Block `MEMBER` from accessing admin/super-admin routes (`/settings`, `/audit-logs`)
- [x] Implement centralized error handling & typed `AppFailure` hierarchy
- [x] Create `AsyncValueWidget` for safe UI error rendering
- [x] Zero raw exceptions shown to end users

## Phase B — Security Persistence
- [x] Implement Argon2id / parameterized PBKDF2 password KDF
- [x] Remove plain SHA-256 password hashing (auto-upgrade to PBKDF2 on login)
- [x] Implement `device_lock.json` file persistence in `C:\ProgramData\GroupInvestmentManagement\config`
- [x] Load, save, and update device lock configuration on disk
- [x] Support wildcard `*` testing mode & exact MachineGuid checking
- [x] Add unit tests for device lock persistence & authorization

## Phase C — Data Integrity
- [x] Transactional member creation (`createMemberWithUser` in single atomic SQLite transaction)
- [x] Multi-write financial transactions (contributions, withdrawals, profit distribution)
- [x] Withdrawal overdraft balance protection guard inside SQLite transaction
- [x] Dedicated loss distribution workflow (`Record Loss`)
- [x] Input validation (decimal strings to integer paise conversion, no double precision)
- [x] Fix N+1 database queries using SQL `GROUP BY` / `JOIN` aggregations

## Phase D — Missing Functionality
- [x] Super Admin user management screen (create admin, change role, reset password, delete user)
- [x] Member data privacy & contact visibility masking (email & phone) per SRS
- [x] Member financial summary & dashboard restrictions

## Phase E — Windows Platform & Installer
- [x] Verify Windows platform files in `windows/`
- [x] Inno Setup installer configuration script (`windows/installer.iss`)

## Phase F — Quality & Verification
- [x] Comprehensive unit, widget, and integration tests
- [x] Run `flutter analyze` with 0 warnings/errors
- [x] Run `flutter test` with 100% passing tests (41/41 tests passing)
