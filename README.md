# 📈 Group Investment & Contribution Management System

A robust, enterprise-grade desktop, mobile, and web application built with **Flutter**, **Riverpod**, and **Clean Architecture**. Designed for groups, clubs, partnerships, and syndicates that pool funds together to make collective investments and distribute profits/losses transparently.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features in Detail](#-key-features-in-detail)
  - [1. User Roles & Access Control (RBAC)](#1-user-roles--access-control-rbac)
  - [2. Contribution Management & Auto-Calculations](#2-contribution-management--auto-calculations)
  - [3. Payment & Contribution Entry Modes](#3-payment--contribution-entry-modes)
  - [4. Investment Pool Management](#4-investment-pool-management)
  - [5. Profit & Loss Distribution Engine](#5-profit--loss-distribution-engine)
  - [6. Withdrawal Management](#6-withdrawal-management)
  - [7. Financial Ledger & Non-Destructive Accounting](#7-financial-ledger--non-destructive-accounting)
  - [8. Security & Audit Logging](#8-security--audit-logging)
  - [9. Role-Adaptive Dashboards](#9-role-adaptive-dashboards)
- [System Architecture & Tech Stack](#-system-architecture--tech-stack)
- [Installation Guide](#-installation-guide)
  - [Prerequisites](#prerequisites)
  - [Development Setup](#development-setup)
  - [Building Windows Executable (.exe)](#building-windows-executable-exe)
  - [Building for Android & Web](#building-for-android--web)
- [First-Time System Setup Guide](#-first-time-system-setup-guide)
- [Running Automated Tests](#-running-automated-tests)

---

## 🌐 Overview

The **Group Investment & Contribution Management System** solves the financial tracking challenge of pooled group capital. When multiple members contribute varying financial amounts to a central investment pool, calculating proportional ownership, investment shares, profit distributions, and withdrawal caps becomes complex.

This system provides complete transparency by maintaining exact financial precision using integer-based **Paise arithmetic** (`₹1.00 = 100 paise`), enforcing strict role-based access rules, recording immutable financial ledgers, and maintaining an audit log of every system operation.

---

## ⚡ Key Features in Detail

### 1. User Roles & Access Control (RBAC)
The system supports three granular user roles:
* **Super Admin**: Full administrative authority. Can create/edit users, assign roles, manage system settings, perform financial adjustments/reversals, reset passwords, and view audit logs.
* **Admin**: Operational management authority. Can add members, collect member contributions directly, approve or reject contribution & withdrawal requests, and view group reports.
* **Member / Read-Only User**: Individual group investor. Can view personal contribution totals, contribution %, allocated profits, available withdrawable balance, and raise contribution or withdrawal requests.

### 2. Contribution Management & Auto-Calculations
* **Exact Financial Precision**: All transactions are calculated in Paise to avoid floating-point rounding discrepancies.
* **Automated Ownership % Calculation**:
  $$\text{Member Contribution \%} = \left( \frac{\text{Member Total Approved Contribution}}{\text{Total Group Approved Contribution}} \right) \times 100$$
* **Dynamic Recalculation**: Whenever a new contribution is approved, the system dynamically updates every active member's percentage ownership across the group.

### 3. Payment & Contribution Entry Modes
* **Mode 1 – Admin Direct Collection**: Admin receives cash/transfer from a member and records an approved contribution immediately into the group fund.
* **Mode 2 – Member Request & Admin Review**: Members initiate a contribution request in the portal. The request stays in `PENDING` status (without affecting total group contribution) until an Admin or Super Admin reviews and approves it.

### 4. Investment Pool Management
* Track investments made from the pooled capital (e.g., Real Estate, Stocks, Business Ventures, Fixed Deposits).
* Tracks: Investment Name, Category/Type, Amount Invested, Duration, Expected Return, Actual Return, Current Value, and Status (`ACTIVE`, `COMPLETED`, `CLOSED`).
* Computes available uninvested liquidity:
  $$\text{Available Group Balance} = \text{Approved Contributions} - \text{Total Invested} - \text{Approved Withdrawals} + \text{Realized Returns}$$

### 5. Profit & Loss Distribution Engine
* **Proportional Profit Distribution**: When an investment yields returns, profit is distributed to members according to their exact contribution percentage at the time of distribution.
* **Loss Distribution Support**: If an investment incurs a loss, the loss is proportionally allocated across members based on agreed risk rules.
* Automatic ledger entry creation for each member's profit/loss share.

### 6. Withdrawal Management
* Members can submit withdrawal requests for approval.
* **Automatic Validation**: The system ensures a member cannot request more than their individual withdrawable balance:
  $$\text{Withdrawable Balance} = \text{Approved Contributions} + \text{Allocated Profit} - \text{Previous Approved Withdrawals}$$
* Approved withdrawals update member balance and group liquidity instantly.

### 7. Financial Ledger & Non-Destructive Accounting
* **Double-Entry Journaling**: Every financial movement generates a formal transaction record (`CONTRIBUTION`, `WITHDRAWAL`, `INVESTMENT`, `PROFIT`, `LOSS`, `ADJUSTMENT`, `REFUND`).
* **Non-Destructive Adjustments**: In accordance with accounting best practices, financial records are never hard-deleted. Corrections are performed via reversing or adjustment entries.

### 8. Security & Audit Logging
* **Password Security**: Uses **PBKDF2 password hashing** with unique cryptographic salts per user.
* **Device Lock Protection**: Includes a local device lock service to prevent unauthorized physical access.
* **System Audit Trail**: Records user ID, action name, target member, timestamp, and details for every transaction and setup operation.

### 9. Role-Adaptive Dashboards
* Adaptable UI layout customized per user role.
* Summary cards for Total Contributions, Total Invested, Available Balance, Total Profit/Loss, and Pending Requests.

---

## 🏗️ System Architecture & Tech Stack

* **Framework**: Flutter (Desktop, Web, Mobile)
* **Language**: Dart
* **State Management**: Riverpod (`flutter_riverpod`)
* **Routing**: GoRouter (`go_router`) with RBAC redirect guards
* **Database**: SQLite (`sqflite` / `sqflite_common_ffi`)
* **UI Responsiveness**: ScreenUtil (`flutter_screenutil`)
* **Architecture Pattern**: Clean Architecture (Layered: `core`, `features`, `domain`, `data`, `presentation`, `routes`)

---

## 💻 Installation Guide

### Prerequisites

Ensure you have the following installed on your development machine:

1. **Flutter SDK** (v3.19.0 or higher)  
   Check installation via:
   ```bash
   flutter doctor
   ```
2. **Dart SDK** (included with Flutter)
3. **C++ Desktop Development Toolchain** (For Windows Build):
   - Install **Visual Studio 2022** with the **"Desktop development with C++"** workload enabled.
4. **Git** (for version control)

---

### Development Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/K-hashmi9065/invest_management_systems.git
   cd invest_management_systems
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Windows (Development Mode)**:
   ```bash
   flutter run -d windows
   ```

4. **Run on Web / Chrome**:
   ```bash
   flutter run -d chrome
   ```

---

### Building Windows Executable (.exe)

To build a standalone Windows **Executable (.exe)** release package:

1. **Enable Windows Desktop Support** (if not already enabled):
   ```bash
   flutter config --enable-windows-desktop
   ```

2. **Build the Release Executable**:
   ```bash
   flutter build windows --release
   ```

3. **Locate Your `.exe` File**:
   Once compilation completes, your executable and required dynamic link libraries (`.dll` files) will be located in:
   ```text
   <project-root>\build\windows\x64\runner\Release\
   ```

4. **Running the Application**:
   - Open the directory above and double-click `invest_management_systems.exe`.
   - **Distribution Note**: To distribute the app to another PC, copy the entire `Release/` folder (or package it into a setup installer using tools like Inno Setup or NSIS). Do not copy only the `.exe` file without its accompanying `.dll` files and `data/` folder.

---

### Building for Android & Web

* **Android APK**:
  ```bash
  flutter build apk --release
  ```
  Output: `build/app/outputs/flutter-apk/app-release.apk`

* **Web Bundle**:
  ```bash
  flutter build web --release
  ```
  Output: `build/web/`

---

## 🚀 First-Time System Setup Guide

1. **Launch the App**:
   When launching the application for the first time on a fresh database, the system will automatically direct you to the **First-Time Setup Screen**.

2. **Create Super Admin Account**:
   - Provide Full Name, Username, and a Secure Password.
   - Click **Complete Setup**.

3. **Initialize Members & Roles**:
   - Log in as Super Admin.
   - Navigate to **Member Management** to add members.
   - Navigate to **User Management** to create Login Credentials (`Admin` or `Member` accounts) linked to members.

4. **Record Contributions & Start Investing**:
   - Record initial member contributions using Direct Payment Collection or approve pending member contribution requests.
   - Create investments and distribute profits when investment returns are realized.

---

## 🧪 Running Automated Tests

The application includes unit tests for financial calculations, password hashing security, RBAC guards, and router redirects.

To execute all tests:
```bash
flutter test
```

To run a specific test suite:
```bash
flutter test test/financial_calculations_test.dart
flutter test test/password_hasher_test.dart
flutter test test/rbac_authorization_test.dart
```

---

## 📄 License

This software is developed for group investment management. All rights reserved.
