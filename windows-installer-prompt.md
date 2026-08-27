# Task: Production Windows Installer for Invest Management (Inno Setup)

You are a senior Windows deployment engineer working inside my existing Flutter Windows
desktop project (Invest Management). Implement — don't just explain — a working Inno Setup
installer. Verify it compiles before you're done.

## 0. Inspect first, don't assume

Before writing any config, inspect the project and report what you find for each of these.
Use the actual values — do not invent or template-fill any of them:

- Flutter version (`flutter --version`)
- App name, version, and company/publisher — from `pubspec.yaml` and
  `windows/runner/Runner.rc`
- Executable name in `build/windows/x64/runner/Release/`
- Existing app icon (path, format) — from `windows/runner/resources/app_icon.ico`
- **Local data layer: Drift (SQLite)** — find the DB file path/name and confirm whether it's
  written under `%APPDATA%`, `%LOCALAPPDATA%`, or the exe's own directory
- **Device-lock config** (hardware machine ID whitelist) — find the file/mechanism that
  stores it and confirm it is NOT inside the Flutter build output that gets overwritten on
  reinstall
- Any other persisted files (logs, session/auth tokens, settings)

Stop and ask me only if something here is genuinely ambiguous (e.g. two candidate publisher
names) — otherwise proceed with what you find.

## 1. Deliverable

A single file the client double-clicks: `Invest-Management-Setup-<version>.exe`, producing a
standard Windows install wizard (welcome → install location → install → desktop shortcut →
start menu shortcut → optional auto-launch).

## 2. Installer structure to create

```
installer/
├── invest-management.iss
├── assets/
│   └── invest-management.ico   (reuse existing app icon if present, else generate proper
│                                 multi-res ICO: 16/24/32/48/64/128/256)
└── Output/
    └── Invest-Management-Setup-<version>.exe
```

Do not place output inside the Flutter build directory.

## 3. Required `.iss` behavior

- Copy the **entire** `build/windows/x64/runner/Release/` tree (exe, all DLLs, `icudtl.dat`,
  `data/` incl. `data/flutter_assets/`) — never just the `.exe`.
- Install to `{autopf}\Invest Management` (resolves correctly regardless of username or
  Program Files path).
- Desktop shortcut + Start Menu shortcut, both pointing at the installed exe with correct
  working directory, both quoted paths.
- "Launch Invest Management" checkbox on the finish page (checked by default).
- 64-bit only: `ArchitecturesAllowed=x64compatible`,
  `ArchitecturesInstallIn64BitMode=x64compatible`.
- LZMA compression, modern wizard UI, admin privileges only as required for Program Files.
- `AppId` fixed GUID (generate once, keep stable across versions) so upgrades detect the
  existing install, replace files, and do NOT create duplicate shortcuts or registry entries.
- **Never touch the Drift SQLite DB file or the device-lock config** during install, upgrade,
  or uninstall — explicitly exclude them from any cleanup step. Confirm in the summary where
  each of these lives and why it's safe from the installer's file operations.
- Standard uninstaller entry in Add/Remove Programs with correct version + publisher, removing
  only Program Files contents, shortcuts, and the uninstaller itself.
- No disabling of Defender/SmartScreen/UAC. If unsigned, say so plainly in your summary and
  note that production should use a code-signing cert — one line, not a lecture.

## 4. Build flow to document (not automate beyond a script)

```powershell
flutter clean
flutter pub get
flutter build windows --release
iscc installer\invest-management.iss
```

## 5. After implementing, compile it

Run `iscc` against the `.iss` file if Inno Setup is available in this environment or via the
project's tooling. If it can't actually be compiled here, say so explicitly rather than
claiming success, and give me the exact command to run locally.

## 6. Report back

A short table, not prose:

| Check | Result |
|---|---|
| Inspected values (app name, version, publisher, exe name) | |
| Icon source used | |
| Drift DB path (excluded from install/uninstall ops) | |
| Device-lock config path (excluded from install/uninstall ops) | |
| `.iss` compiles cleanly | |
| Upgrade scenario (same AppId → no duplicate shortcuts) reasoned through | |
| Files changed outside `installer/` (should be none unless required for icon/identity) | |

Do not modify application logic, auth, RBAC, API, database, or state management code. Only
touch Windows runner/icon/identity files if strictly required for packaging.
