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
- [ ] Implement Argon2id / parameterized PBKDF2 password KDF
- [ ] Remove plain SHA-256 password hashing
- [ ] Implement `device_lock.json` file persistence in `C:\ProgramData\GroupInvestmentManagement\config`
- [ ] Load, save, and update device lock configuration on disk
- [ ] Support wildcard `*` testing mode & exact MachineGuid checking
- [ ] Add unit tests for device lock persistence & authorization

## Phase C — Data Integrity
- [ ] Transactional member creation (`createMember` + `createUser` in single SQLite transaction)
- [ ] Multi-write financial transactions (contributions, withdrawals, profit distribution)
- [ ] Implement Soft Delete (`isDeleted`, `deletedAt`, `deletedBy`, `deleteReason`)
- [ ] Prevent physical deletion of financial records
- [ ] Dedicated loss distribution workflow (`Record Loss`)
- [ ] Input validation (decimal strings to integer paise conversion, no double precision)
- [ ] Fix N+1 database queries using SQL `GROUP BY` / `JOIN` aggregations

## Phase D — Missing Functionality
- [ ] Super Admin user management screen (create admin/member, change role, activate/deactivate)
- [ ] Member data privacy & financial visibility filtering per SRS
- [ ] Member financial summary & dashboard restrictions

## Phase E — Windows Platform & Installer
- [ ] Verify Windows platform files in `windows/`
- [ ] Verify `flutter run -d windows` execution
- [ ] Inno Setup installer configuration script

## Phase F — Quality & Verification
- [ ] Comprehensive unit, widget, and integration tests
- [ ] Run `flutter analyze` with 0 warnings/errors
- [ ] Run `flutter test` with 100% passing tests
- [ ] Build release executable (`flutter build windows --release`)
