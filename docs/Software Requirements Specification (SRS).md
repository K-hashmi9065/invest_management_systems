# Software Requirements Specification (SRS)
## Group Investment & Contribution Management System

### 1. Introduction

The **Group Investment & Contribution Management System** is a web-based application designed to manage a group of people who contribute different amounts of money into a common investment pool.

For example, a group of 10 members may contribute different amounts:

| Member | Contribution | Contribution % |
|---|---:|---:|
| Member 1 | ₹1,00,000 | 20% |
| Member 2 | ₹75,000 | 15% |
| Member 3 | ₹50,000 | 10% |
| Member 4 | ₹50,000 | 10% |
| Member 5 | ₹40,000 | 8% |
| Member 6 | ₹40,000 | 8% |
| Member 7 | ₹35,000 | 7% |
| Member 8 | ₹30,000 | 6% |
| Member 9 | ₹40,000 | 8% |
| Member 10 | ₹40,000 | 8% |
| **Total** | **₹5,00,000** | **100%** |

The collected amount can then be invested in one or more investments. When profit is generated, the profit will be distributed among members based on their **percentage of contribution**, subject to the group's agreed rules.

The system will maintain complete records of:

- Members
- Contributions
- Investment amounts
- Investment returns
- Profit/loss
- Withdrawals
- Contribution percentages
- Profit distribution
- Approval requests
- Financial transactions
- User roles and permissions

---

# 2. Objectives

The primary objectives of the system are:

1. Maintain a centralized record of all group members.
2. Track each member's contribution.
3. Automatically calculate each member's contribution percentage.
4. Track the total available investment pool.
5. Maintain investment records.
6. Record investment profit or loss.
7. Automatically calculate each member's share of profit/loss.
8. Manage deposits and withdrawals.
9. Allow members to raise contribution requests.
10. Allow administrators to approve/reject financial requests.
11. Provide different access levels based on user roles.
12. Maintain a complete financial transaction history.
13. Provide transparency to all group members.
14. Prevent unauthorized modification of financial information.

---

# 3. User Roles

The system will have three primary user roles:

### 3.1 Read-Only User / Member

A normal member can:

- Login to the system.
- View his/her profile.
- View personal contribution.
- View contribution percentage.
- View total group investment.
- View his/her investment share.
- View allocated profit/loss.
- View approved deposits.
- View approved withdrawals.
- Raise a request to add money.
- Raise a withdrawal request.
- View transaction history.
- View investment information permitted by the system.

A read-only user **cannot directly modify financial records**.

---

### 3.2 Admin

An Admin will have all capabilities of a normal member plus additional administrative functionality.

Admin can:

- Add new members.
- View member information.
- View member contributions.
- View group financial information.
- Collect money from members.
- Record collected payments.
- Approve member contribution requests.
- Approve/reject withdrawal requests, based on configured permissions.
- View investment information.
- View financial reports.
- View transaction history.

Admin should not have unrestricted access to critical system configuration unless explicitly granted by the Super Admin.

---

### 3.3 Super Admin

The Super Admin has complete control over the system.

Super Admin can:

- Create users.
- Edit users.
- Delete/deactivate users.
- Assign roles.
- Change user roles.
- Create Admin users.
- Manage members.
- Manage contributions.
- Manage investments.
- Manage profit/loss.
- Manage withdrawals.
- Approve/reject financial transactions.
- Modify financial records where permitted.
- View all transactions.
- Generate reports.
- Manage system settings.
- View audit logs.
- Correct erroneous transactions.
- Manage investment records.
- Configure profit distribution rules.

Super Admin should have access to a complete system dashboard.

---

# 4. Contribution Management

The system should maintain individual contribution records for every member.

Each contribution should contain:

- Member
- Contribution amount
- Contribution date
- Payment mode
- Transaction/reference number
- Added by
- Approval status
- Approved by
- Approval date
- Remarks
- Created date
- Updated date

### Example

```text
Member: Rahul
Contribution: ₹50,000
Contribution Date: 10-Aug-2026
Status: Approved
Contribution Percentage: 10%
```

---

# 5. Contribution Percentage Calculation

The system should automatically calculate the contribution percentage.

### Formula

```text
Member Contribution %
=
(Member Total Contribution / Total Group Contribution) × 100
```

For example:

```text
Total Group Contribution = ₹10,00,000

Member A Contribution = ₹2,00,000

Contribution %
= ₹2,00,000 / ₹10,00,000 × 100
= 20%
```

The percentage should be recalculated whenever an approved contribution changes the total contribution pool.

---

# 6. Investment Management

The system should allow authorized users to record investments made using the group fund.

Each investment should contain:

- Investment ID
- Investment name
- Investment type
- Investment amount
- Investment date
- Investment period
- Expected return
- Actual return
- Current value
- Profit/loss
- Status
- Remarks
- Created by
- Updated by

### Example

```text
Total Group Fund: ₹10,00,000

Investment A: ₹6,00,000
Investment B: ₹3,00,000

Uninvested Balance: ₹1,00,000
```

The system should ensure:

```text
Available Balance
=
Total Approved Contributions
- Total Invested Amount
- Approved Withdrawals
+ Realized Returns
```

The exact accounting formula should be finalized based on the group's financial rules.

---

# 7. Profit Distribution

When an investment generates profit, the system should calculate each member's share according to the configured contribution percentage.

### Example

Total contribution:

```text
₹10,00,000
```

Member A:

```text
Contribution = ₹2,00,000
Percentage = 20%
```

Investment profit:

```text
₹1,00,000
```

Member A's profit:

```text
₹1,00,000 × 20%
= ₹20,000
```

The system should generate a profit-distribution record for each member.

### Profit Distribution Table

| Member | Contribution % | Profit | Member Share |
|---|---:|---:|---:|
| A | 20% | ₹1,00,000 | ₹20,000 |
| B | 15% | ₹1,00,000 | ₹15,000 |
| C | 10% | ₹1,00,000 | ₹10,000 |
| Others | 55% | ₹1,00,000 | ₹55,000 |
| **Total** | **100%** | **₹1,00,000** | **₹1,00,000** |

The system should support both **profit and loss distribution** according to the configured business rules.

---

# 8. Payment / Contribution Entry Modes

The system should support two methods for adding money.

## 8.1 Mode 1 – Admin Collects Money

In this mode:

```text
Member gives money to Admin
          ↓
Admin receives money
          ↓
Admin enters contribution
          ↓
System records transaction
          ↓
Contribution becomes approved
          ↓
Member balance is updated
```

Example:

```text
Member: Amit
Amount: ₹25,000
Collected By: Admin
Payment Mode: Cash
Status: Approved
```

The Admin should provide the payment reference/remarks where applicable.

---

# 9. Mode 2 – Member Raises Contribution Request

In this mode, the member initiates the transaction.

```text
Member
   ↓
Raise Contribution Request
   ↓
Enter Amount
   ↓
Select Payment Method
   ↓
Submit Request
   ↓
Admin Reviews
   ↓
Approve / Reject
   ↓
If Approved
   ↓
Amount added to member contribution
```

Until approval:

```text
Requested Amount ≠ Approved Contribution
```

This is important because the member's contribution should only increase after the Admin/Super Admin approves the request.

### Request Status

```text
PENDING
APPROVED
REJECTED
CANCELLED
```

---

# 10. Withdrawal Management

The system should support withdrawal requests.

A member can raise a withdrawal request:

```text
Member
   ↓
Enter withdrawal amount
   ↓
Submit request
   ↓
Admin/Super Admin review
   ↓
Approve / Reject
   ↓
If approved
   ↓
Financial balance updated
```

The system should validate:

```text
Requested Withdrawal
<=
Member's Available Withdrawable Balance
```

The system should maintain a complete withdrawal history.

---

# 11. Withdrawal Status

Each withdrawal request should have one of the following statuses:

- Pending
- Approved
- Rejected
- Processing
- Completed
- Cancelled

Example:

```text
Withdrawal Request

Member: Rahul
Amount: ₹20,000
Requested Date: 12-Aug-2026
Status: Pending
```

After approval:

```text
Status: Approved
Approved By: Admin
Approved Date: 12-Aug-2026
```

---

# 12. Member Dashboard

Each member should have a personalized dashboard.

### Dashboard should display:

```text
My Contribution
₹2,00,000

My Contribution %
20%

Total Group Contribution
₹10,00,000

Total Invested
₹8,00,000

My Investment Share
₹1,60,000

My Profit/Loss
₹20,000

Available Balance
₹1,80,000
```

Members should only see financial information they are authorized to access.

---

# 13. Admin Dashboard

Admin dashboard should display:

- Total members
- Total contributions
- Total invested amount
- Available balance
- Total profit/loss
- Pending contribution requests
- Pending withdrawal requests
- Recent transactions
- Member-wise contribution
- Investment summary

---

# 14. Super Admin Dashboard

Super Admin dashboard should provide complete visibility.

### Summary cards:

- Total Members
- Total Contributions
- Total Investments
- Total Withdrawals
- Available Balance
- Total Profit
- Total Loss
- Pending Requests
- Active Investments
- Completed Investments

### Charts

The system may provide:

- Contribution by member
- Investment allocation
- Profit/loss trend
- Monthly contribution
- Monthly withdrawal
- Investment performance

---

# 15. Transaction Management

Every financial movement should generate a transaction record.

Transaction types:

```text
CONTRIBUTION
WITHDRAWAL
INVESTMENT
INVESTMENT_RETURN
PROFIT
LOSS
ADJUSTMENT
REFUND
```

Each transaction should contain:

- Transaction ID
- User/member
- Transaction type
- Amount
- Date
- Status
- Reference number
- Payment mode
- Created by
- Approved by
- Remarks
- Created timestamp
- Updated timestamp

---

# 16. Financial Ledger

The system should maintain a financial ledger to provide transparency.

Example:

| Date | Type | Member | Amount | Status |
|---|---|---|---:|---|
| 01-Aug | Contribution | Rahul | ₹50,000 | Approved |
| 02-Aug | Contribution | Amit | ₹30,000 | Approved |
| 05-Aug | Investment | Group | ₹70,000 | Completed |
| 10-Aug | Profit | Group | ₹10,000 | Distributed |
| 11-Aug | Withdrawal | Rahul | ₹5,000 | Approved |

The ledger should not allow unauthorized deletion of financial records.

Where correction is required, the system should preferably create an **adjustment/reversal transaction** rather than permanently deleting the original financial transaction.

---

# 17. User Management

Super Admin should be able to:

- Add user
- Edit user
- View user
- Activate/deactivate user
- Assign role
- Change role
- Reset password
- View member financial summary
- View transaction history

Admin should be able to add users according to the permissions granted by Super Admin.

---

# 18. Role & Permission Matrix

| Feature | Read-Only User | Admin | Super Admin |
|---|:---:|:---:|:---:|
| Login | ✓ | ✓ | ✓ |
| View own contribution | ✓ | ✓ | ✓ |
| View own transactions | ✓ | ✓ | ✓ |
| Raise contribution request | ✓ | ✓ | ✓ |
| Raise withdrawal request | ✓ | ✓ | ✓ |
| Add user | ✗ | ✓ | ✓ |
| View all members | Limited | ✓ | ✓ |
| Collect payment | ✗ | ✓ | ✓ |
| Approve contribution | ✗ | ✓ | ✓ |
| Approve withdrawal | ✗ | ✓ | ✓ |
| Manage investments | ✗ | Limited | ✓ |
| Manage profit/loss | ✗ | Limited | ✓ |
| Create user | ✗ | ✓ | ✓ |
| Edit user | ✗ | Limited | ✓ |
| Delete/deactivate user | ✗ | Limited | ✓ |
| Financial CRUD | ✗ | Limited | ✓ |
| Reports | Own | Group | Complete |
| Audit Logs | ✗ | Limited | ✓ |
| System Settings | ✗ | ✗ | ✓ |

---

# 19. Notifications

The system should notify users when important financial events occur.

Notifications may be sent through:

- In-app notification
- Email
- SMS
- WhatsApp, if required

Important events:

- Contribution request submitted
- Contribution approved
- Contribution rejected
- Withdrawal request submitted
- Withdrawal approved
- Withdrawal rejected
- Investment created
- Investment completed
- Profit distributed
- Important system announcements

---

# 20. Audit Trail

Because this application manages financial information, an audit trail is highly recommended.

The system should record:

```text
Who performed the action?
What action was performed?
Which record was changed?
Previous value
New value
Date/time
IP address
```

Example:

```text
User: Admin Rahul
Action: APPROVED CONTRIBUTION
Member: Amit
Amount: ₹50,000
Date: 12-Aug-2026 10:30 AM
```

Financial records should not be silently modified without an audit history.

---

# 21. Authentication & Security

The system should provide:

- Secure login
- Password hashing
- JWT/session-based authentication
- Role-based authorization
- Secure API endpoints
- HTTPS
- Session timeout
- Password reset
- Account activation/deactivation
- Login activity monitoring

All financial APIs must verify the user's role and permissions on the backend.

---

# 22. Important Business Rules

### Rule 1 – Pending contribution

A contribution request should not increase the member's approved balance until approved.

### Rule 2 – Contribution percentage

Only approved contributions should be considered when calculating contribution percentage.

### Rule 3 – Withdrawal

A member should not be able to withdraw more than the amount available under the group's withdrawal rules.

### Rule 4 – Profit

Profit should be distributed according to the configured contribution/profit-sharing percentage.

### Rule 5 – Loss

Loss should also be calculated according to the configured business rules.

### Rule 6 – Financial deletion

Financial transactions should generally not be physically deleted. Use reversal/adjustment transactions.

### Rule 7 – Role security

Frontend role restrictions must be backed by server-side authorization.

---

# 23. Suggested Main Modules

The application can be divided into the following modules:

```text
Authentication
    ↓
User & Role Management
    ↓
Member Management
    ↓
Contribution Management
    ↓
Payment Requests
    ↓
Withdrawal Management
    ↓
Investment Management
    ↓
Profit/Loss Management
    ↓
Financial Ledger
    ↓
Reports & Analytics
    ↓
Notifications
    ↓
Audit Logs
    ↓
System Settings
```

---

# 24. Suggested Screens

### Authentication

- Login
- Forgot Password
- Reset Password
- Change Password

### Member

- My Dashboard
- My Profile
- My Contributions
- My Investments
- My Profit/Loss
- My Transactions
- Add Money Request
- Withdrawal Request
- Notifications

### Admin

- Admin Dashboard
- Member Management
- Add Member
- Contribution Management
- Contribution Requests
- Withdrawal Requests
- Payment Collection
- Investment View
- Financial Reports

### Super Admin

- Super Admin Dashboard
- User Management
- Role Management
- Contribution Management
- Investment Management
- Profit/Loss Management
- Withdrawal Management
- Financial Ledger
- Reports
- Audit Logs
- System Settings

---

# 25. Example End-to-End Scenario

Assume there are 10 members.

Total contribution:

```text
₹10,00,000
```

Member A contributes:

```text
₹2,00,000
```

Therefore:

```text
Member A Contribution %
= 20%
```

The group invests:

```text
₹8,00,000
```

The investment generates:

```text
₹1,00,000 profit
```

Member A's profit:

```text
₹1,00,000 × 20%
= ₹20,000
```

The system automatically records:

```text
Member A
Contribution: ₹2,00,000
Contribution %: 20%
Profit Share: ₹20,000
```

This provides a transparent view of how the member's money participates in the group investment.

---

# 26. Future Enhancements

The following features can be considered for future versions:

- Multiple investment groups
- Multiple currencies
- Bank account integration
- UPI payment integration
- Payment gateway integration
- Automated payment reconciliation
- Advanced financial reports
- Tax/reporting support
- Export to Excel/PDF
- WhatsApp notifications
- Mobile application
- Investment performance tracking
- Digital agreement/document management
- E-signature
- Multi-level approval workflow
- Automated profit distribution
- Automated recurring contributions

---

# 27. Key Recommendation

Because this system handles **pooled money, investments, profit sharing and withdrawals**, the final business rules should be approved by the client's legal/financial advisor before development.

In particular, the following must be explicitly defined before implementation:

1. Whether members can withdraw their original contribution at any time.
2. Whether profit is distributed periodically or only when an investment is closed.
3. How losses are handled.
4. Whether contribution percentages change after withdrawals.
5. Whether new members can join an existing investment.
6. How a member exits the group.
7. Whether profit is reinvested or paid out.
8. Whether investments can be made only by the Super Admin or also by Admin.
9. Whether one group or multiple independent groups will be supported.
10. How disputes/corrections in financial transactions will be handled.

These rules should be finalized before the database and financial calculation logic are implemented.