# Expense Tracker — context for Gemini

You are helping with **Expense Tracker**, a private personal-finance Flutter app. Use this document as the source of truth for what the app is, who it is for, how money moves, and what it does **not** do. Prefer this document over guesses. If something is not described here, say you do not know rather than inventing a feature.

App display name: **Expense Tracker**  
Package: `expense_tracker`  
Version: `1.0.0+1`  
Android application id: `com.expensetracker.app`  
Default currency code: **PKR** (Pakistani Rupee)  
Not published to pub.dev (`publish_to: none`).

---

## 1. Purpose

Expense Tracker is a **single-user personal finance app**. One person signs in and tracks their own money. It is built for someone who:

- holds money in more than one place (cash, a bank account, a mobile wallet such as JazzCash)
- wants every rupee of income and spending recorded against an account and a category
- lends money to people or borrows from people and needs to see what is still owed
- wants a monthly picture of spending, not a full accounting system

It answers four questions:

1. How much money do I have right now, and in which account?
2. What did I earn and spend, when, and on what?
3. Who owes me, and who do I owe?
4. How does this month compare with recent months?

It is **not** a bank, a budgeting app, or a multi-user household app. There are no budgets, bill reminders, receipt photos, recurring transactions, or investments. Personal accounts are never shared. An opt-in company workspace (off by default) records one partnership pool for the signed-in user only. See section 11.

---

## 2. Who uses it and how they start

Audience: one person managing personal cash flow, with PKR as the assumed currency.

First-run flow:

1. Splash screen checks the Supabase session.
2. If there is no session, the user sees Login. They can sign up or request a password reset email.
3. Sign up collects full name, email, and password (minimum 6 characters; confirm password must match). Email must look like a valid address.
4. On a successful sign-up that returns a session, the app inserts a `profiles` row (`currency` = `PKR`, `full_name` from the form) and seeds two accounts:
   - **Cash in Hand** — type `cash`, `is_default` true, balance 0
   - **Bank Account** — type `bank`, not default, balance 0
5. A database trigger on profile insert seeds default categories (listed below).
6. If email confirmation is required by Supabase, sign-up returns “confirmation email sent” and does **not** create the profile until the user later signs in. On sign-in, if the profile or accounts are missing, the app creates them then.
7. After sign-in the user lands on the Dashboard.

Auth is email and password only (Supabase Auth). There is no Google, phone, or guest login.

---

## 3. Product map

After login, a bottom navigation bar has four tabs. Each tab keeps its own scroll state.

| Tab | Route | What the user does |
|-----|--------|--------------------|
| Dashboard | `/dashboard` | See greeting, total balance, accounts, this month’s income vs expense, a daily expense chart, and the latest transactions |
| Transactions | `/transactions` | Search, filter, add, open, edit, and delete income and expenses |
| Loans | `/loans` | Switch between money borrowed (Taken) and money lent (Given); add a loan, open it, record a payment, settle it |
| Settings | `/settings` | Edit display name, change password, open categories and accounts, export CSV, delete all data, sign out |

Screens pushed on top of the tabs (they are not tabs):

| Screen | Route |
|--------|--------|
| Accounts | `/accounts` |
| Categories | `/categories` |
| Reports | `/reports` |
| Add / edit transaction | `/transaction/form` and `/transaction/form?id={id}` |
| Transaction detail | `/transaction/{id}` |
| Add / edit loan | `/loan/form` and `/loan/form?id={id}` |
| Loan detail | `/loan/{id}` |
| Login / sign up / forgot password | `/login`, `/sign-up`, `/forgot-password` |

Dashboard links: wallet icon opens Accounts. “See all” on recent transactions opens the Transactions tab. A control on the monthly expense card opens Reports.

---

## 4. Domain vocabulary

Use these words exactly. Do not invent synonyms that change meaning.

**Profile.** The signed-in person. Fields: id (same as Supabase `auth.users.id`), `full_name`, `currency` (default `PKR`). Greeting uses the trimmed full name, or the word “there” if the name is empty. The currency code is a **display prefix only**. There is no currency picker in Settings and no FX conversion. Some form labels still say “Amount (PKR)” even though lists format with the profile currency code. Amounts display as `{CODE} 12,500` or `{CODE} 12,500.5` (thousands separators, up to 2 decimal places, trailing zeros dropped by the format).

**Account.** A place money sits. Types: `cash`, `bank`, `wallet`. Fields: name, type, balance, optional icon, `is_default`. Total balance on the dashboard is the sum of account balances. Default sort: the default account first, then name.

**Transaction.** One income or expense movement on one account. Types: `expense`, `income`. Amount must be greater than 0. Optional description and category. Date is a calendar date (defaults to today; past dates are allowed). Display title is the description if present, otherwise the category name, otherwise “Expense” or “Income”.

**Category.** A label for income or expense. Each category belongs to one user and one type (`expense` or `income`). It has a Material icon name and a hex color. Categories are not shared between users. A category whose name matches a seeded default for that type is **protected** and cannot be deleted, even if the user created a second category with the same name.

**Loan.** Money between the user and another person. Types:

- `given` — the user lent money. The other person owes the user.
- `taken` — the user borrowed money. The user owes the other person.

Fields: person name (required), optional phone, original `amount`, `remaining_amount`, optional description, optional due date, optional linked account, status.

**Loan status:**

- `pending` — nothing repaid (`remaining_amount` equals `amount`)
- `partial` — some repaid, some still outstanding
- `settled` — `remaining_amount` is 0

**Overdue.** A loan with a due date before today and status not `settled`. Due date is compared as a calendar day, not a time of day.

**Repaid amount** = original amount − remaining amount. Progress fraction is repaid / original, clamped between 0 and 1.

**Loan payment.** A partial or full repayment. Amount must be > 0 and must not exceed remaining amount. Recording a payment also writes a normal transaction (see section 6). The database then reduces `remaining_amount` and updates status. Remaining amount never goes below 0.

**Transfer.** Moving money from one of the user’s accounts to another. It is **not** its own table. It is two transactions created together (see section 6).

**Net** = income − expense for the set of transactions being summarized. Because transfers and some loan movements are stored as income and expense, net and category totals include those rows.

---

## 5. What the user sees

### Dashboard

- “Hello, {name}” and today’s date as “Weekday, d Month yyyy”.
- Total balance card (sum of accounts).
- Horizontal account carousel: name, type, balance.
- This month: income (treated as positive / green) and expense (red), plus net.
- Monthly expense overview: daily expense bars for the current month and a sentence comparing this month’s expenses with last month:
  - no expenses this month → “No expenses recorded this month yet.”
  - expenses this month but none last month → “No expenses last month to compare.”
  - otherwise “You spent N% more/less than last month.” or “You spent the same as last month.”
- Recent transactions (latest few) with a way to open the full list.
- Pull to refresh. Loading uses a shimmer list. An error state offers retry.
- If the device has no network, an offline banner appears. The app does **not** queue writes offline. Saving still needs Supabase.

### Transactions

Filters (client-side on the loaded set, default date range is this month):

- Date: This month, Last month, or a custom start/end
- Type: All, Expense, or Income
- Account: All or one account
- Text search

The list is grouped under Today, Yesterday, or “d MMM yyyy”. Each row shows category icon and color, title, amount (expense red, income green), and account name. A header shows filtered income, expense, and net.

Add/edit form:

- Segmented Expense / Income (default Expense)
- Amount, numeric, up to 2 decimal places, must be > 0
- Account (required)
- Category chips for the selected type (required)
- Date picker, default today
- Optional description
- Save writes the row. **The app does not update `accounts.balance` in Dart.** Postgres triggers do that on insert, update, and delete.

Tap a row for detail, then edit or delete. Swipe to delete asks for confirmation.

### Accounts

- List name, type, and balance.
- Add: name, type (`cash` / `bank` / `wallet`), optional initial balance. New accounts are never the default. **Initial balance is written straight onto `accounts.balance`. It does not create a transaction**, so it will not show up in transaction history or in report income/expense, but it does change total balance.
- Edit: rename only. Type and balance are not edited on this form.
- Delete is refused when any of these is true:
  - balance is not exactly 0
  - the account has any transaction
  - the account is the default account
- Transfer sheet: from account, to account, amount. Rules: the two accounts must differ, amount > 0, source balance must be at least the amount. Success creates two transactions dated today (see section 6). There is no separate transfer category.

### Categories

- Two groups: expense and income.
- Create: name, type, icon, color (default `#A0A0A0` if none).
- Update: name and icon.
- Delete is refused for protected default names and for any category that is still referenced by a transaction. Deleting a category that is allowed does not delete transactions; the schema sets `transactions.category_id` to null if a category row is removed.

Seeded expense categories (icon, color):

| Name | Icon | Color |
|------|------|--------|
| Food | restaurant | #FF6B6B |
| Transport | directions_car | #4ECDC4 |
| Shopping | shopping_bag | #FFE66D |
| Bills | receipt_long | #95E1D3 |
| Health | local_hospital | #F38181 |
| Entertainment | movie | #AA96DA |
| Education | school | #6C5CE7 |
| Other | more_horiz | #A0A0A0 |

Seeded income categories:

| Name | Icon | Color |
|------|------|--------|
| Salary | payments | #00B894 |
| Freelance | laptop | #0984E3 |
| Business | store | #FDCB6E |
| Gift | card_giftcard | #E17055 |
| Other | more_horiz | #A0A0A0 |

Extra icons the picker offers beyond the seeds: fitness_center, pets, home, flight.

### Loans

Two tabs: **Taken** (I borrowed) and **Given** (I lent). Each tab has a summary of total original amount and outstanding (sum of remaining), then cards. Cards show person, status, remaining, progress, and overdue when applicable.

Add loan:

- Type Given or Taken (only when creating; edit cannot change type or amount)
- Person name (required), optional phone
- Amount > 0 (only when creating)
- **Existing loan** switch. On: “Money already moved — track what is owed without changing account balance.” No account is stored and no opening transaction is created. Off: an optional account. If an account is chosen, an opening transaction is created today (see section 6). If no account is chosen, the loan is tracked and balances do not change.
- Optional description and optional due date

Edit loan: person name, phone, description, due date only.

Loan detail: original amount, remaining, status, due date, payment history (newest first). Actions:

- Record payment: amount, account (required), optional date (default today), optional note. Amount cannot exceed remaining.
- Settle: records one payment for the full remaining amount, note defaults to “Full settlement”.
- Delete loan: deletes the loan and its payment rows (cascade). **It does not delete the opening transaction or the repayment transactions.** Those stay in the transaction list and keep their effect on account balances.

### Reports

Opened from the dashboard, not a tab. Period defaults to the current calendar month. The user can pick another month (from 2020 through today) or a custom date range (through today). Pull to refresh.

Three blocks:

1. **Category donut** — expenses in the period, grouped by category. Missing category is labeled “Uncategorized”. Sorted by amount descending. Shows each slice’s share of total expenses and the period total.
2. **Income vs expense bars** — the six calendar months ending on the selected period’s month (not the custom range). Each month has income, expense, and net = income − expense.
3. **Account summary table** for the selected period, per account:
   - income and expense inside the period
   - closing balance at period end = current account balance minus the net of all transactions **after** the period end
   - opening balance = closing − income + expense

Reports read transactions. They do not have a separate data store.

### Settings

- Profile: display name (editable) and email (from auth, not edited here). Name update writes `profiles.full_name`.
- Change password (Supabase update user).
- Shortcuts to Categories and Accounts.
- Export CSV: builds one file with a transactions section (`date, type, amount, account, category, description`) and a loans section (`person_name, type, amount, remaining_amount, status, due_date, description`), then opens the system share sheet. Loan payments are not a separate CSV section.
- Delete all data: three confirmation steps, then the user must confirm the word DELETE. Deletion order: loan_payments, loans, transactions, categories, accounts. Then the two default accounts and the default categories are created again. The auth user and profile row stay. Balances return to 0.
- About: app name and version.
- Log out, with a confirm dialog.

---

## 6. How money actually moves

This is the most important section. Account balances are maintained by **Postgres triggers**, not by the Flutter UI, except the initial balance typed when an account is created.

### Transaction insert

- `expense`: account balance decreases by amount
- `income`: account balance increases by amount

### Transaction update

If account, type, or amount changed: the old effect is reversed, then the new effect is applied. Changing only description, category, or date does **not** move the balance.

### Transaction delete

The original effect is reversed (an expense delete adds the amount back; an income delete subtracts it).

Balances may go negative. The app does not block an expense larger than the account balance. Transfers are the exception: the transfer function checks source balance before inserting.

### Transfer of amount A from account X to account Y, today

Two transaction rows, no category:

1. On X: type `expense`, description `Transfer to {Y name}`
2. On Y: type `income`, description `Transfer from {X name}`

Net worth (sum of balances) stays the same. Monthly income and monthly expense both increase by A. Reports will show the transfer inside income, expense, and (if uncategorized) the Uncategorized slice only when the row is an expense — the expense side has no category, so it counts as Uncategorized expense. The income side is not in the expense donut.

### New loan that affects a balance

Only when “Existing loan” is off **and** an account is selected:

| Loan type | Opening transaction | Balance effect | Description |
|-----------|---------------------|----------------|-------------|
| given (I lent) | expense | account down | `Loan to {person}` |
| taken (I borrowed) | income | account up | `Loan from {person}` |

No category is set on these rows. Date is today. `remaining_amount` starts equal to `amount`, status `pending`.

Existing-loan mode, or no linked account: loan row only. Balances unchanged.

### Recording a loan payment of amount P on account Z

1. Insert `loan_payments` (loan, user, amount, account, note, paid_at).
2. Trigger sets `remaining_amount = max(0, remaining − P)` and status:
   - 0 → `settled`
   - less than original amount → `partial`
   - otherwise `pending`
3. The app then inserts a transaction (no category):

| Loan type | Payment transaction | Balance effect | Description |
|-----------|---------------------|----------------|-------------|
| given (they pay me back) | income | account up | `Loan repayment from {person}` |
| taken (I pay them back) | expense | account down | `Loan repayment to {person}` |

The payment account can differ from the account used when the loan was opened. The payment does not update the loan’s `account_id`.

Settle is the same path with P = remaining and note `Full settlement` unless the user passed another note.

### What delete does to money

- Delete transaction: balance reversed by trigger.
- Delete loan: loan and payment history gone; related transactions remain and balances stay as those transactions left them.
- Delete account: blocked if balance ≠ 0, if any transaction exists, or if it is the default. Database also restricts deleting an account that transactions still reference (`ON DELETE RESTRICT`).
- Delete all data: wipes financial rows and reseeds empty defaults. Profile remains.

---

## 7. Data model (Supabase / Postgres)

All tables are in `public`. Row Level Security is on. A signed-in user can only read and write rows they own (`user_id = auth.uid()`, or `profiles.id = auth.uid()`). Categories SELECT also allows `user_id IS NULL` (system rows), but the app seeds categories with the user’s id, so in practice categories are per user.

| Table | Important columns |
|-------|-------------------|
| `profiles` | id PK → auth.users, full_name, currency default `PKR`, created_at, updated_at. Delete user cascades. |
| `accounts` | id, user_id → profiles, name, type in (`cash`,`bank`,`wallet`), balance default 0, icon, is_default, timestamps |
| `categories` | id, user_id nullable, name, icon, type in (`expense`,`income`), color, created_at |
| `transactions` | id, user_id, account_id (restrict on account delete), category_id (set null on category delete), type in (`expense`,`income`), amount > 0, description, date default today, timestamps |
| `loans` | id, user_id, account_id nullable (set null if account deleted), person_name, phone, type in (`given`,`taken`), amount > 0, remaining_amount ≥ 0, description, status in (`pending`,`partial`,`settled`) default pending, due_date, timestamps |
| `loan_payments` | id, loan_id (cascade), user_id, amount > 0, account_id nullable (set null), note, paid_at default today, created_at |

Indexes exist on user ids, transaction `(user_id, date desc)`, and loan payment loan id / paid_at.

`updated_at` is maintained by a trigger on profiles, accounts, transactions, and loans.

Migrations, in order:

1. `supabase/migrations/20251110000000_initial_schema.sql` — tables, RLS, category seed trigger, balance-on-insert trigger, loan-payment trigger
2. `supabase/migrations/20251110120000_transaction_balance_update_delete.sql` — balance adjust on transaction update and delete
3. `supabase/migrations/20261111000000_company_workspace.sql` — opt-in company ledger, company transactions, and their balance triggers

There is no budgets table, no attachments table, and no transfer table. `profiles.company_mode_enabled` defaults to false.

Realtime: accounts, loans, and categories are watched with Supabase streams filtered by user id. Reports and some transaction lists are fetched on demand and refreshed by invalidating Riverpod providers.

---

## 8. Engineering map

```
lib/
  main.dart                         dotenv + Supabase init + ProviderScope
  app.dart                          MaterialApp.router, theme, offline banner
  config/
    constants/app_constants.dart    app name, PKR, developer name
    router/                         go_router paths, auth redirect
    supabase/supabase_bootstrap.dart
    theme/app_theme.dart
  core/
    models/                         Account, Category, TransactionItem, Loan, UserProfile, MonthlyStats
    enums/                          account type, category type, transaction type, loan type, loan status
    constants/default_categories.dart
    utils/                          validators, currency formatter, date formatter, auth errors
  features/
    auth/         splash, login, sign up, forgot password, AuthService
    shell/        bottom navigation
    dashboard/
    transactions/
    accounts/
    categories/
    loans/
    reports/
    company/      opt-in partnership ledger, separate from personal money
    settings/     profile, CSV export, delete-all, sign out
supabase/migrations/
test/             validators, auth errors, transaction logic, loan math, loan payment sheet widget
```

Stack:

| Concern | Choice |
|---------|--------|
| UI | Flutter, Material 3, dark theme, Google Fonts |
| State | flutter_riverpod |
| Navigation | go_router. Auth stream refreshes redirects. Unauthenticated users cannot stay on app routes. |
| Backend | supabase_flutter. URL and anon key from `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), bundled as an asset. Startup fails if either is missing. |
| Charts | fl_chart |
| Dates and numbers | intl |
| Share export | share_plus + path_provider |
| Connectivity | connectivity_plus (banner only) |
| App version label | package_info_plus |
| SDK | Dart ^3.13.4. Repo expects Flutter 3.47.5 via FVM. |
| Splash color | #0D1117 |
| Tests | `flutter test` (or `fvm flutter test`) |

Feature code is split into screens, widgets, providers, and services. Services talk to Supabase. Providers expose streams and async values to widgets. Do not describe a repository layer; there isn’t a separate one.

Theme is dark. Income is shown in green, expense in red. Empty states, shimmer loading, and snackbars are used for feedback. Haptics exist as a small helper.

---

## 9. Explicit non-goals (do not invent these)

- No budgets, savings goals, or spending limits
- No recurring or scheduled transactions
- No receipt photos, notes attachments, or OCR
- No multiple currencies with conversion; one display code per profile, default PKR, no settings screen to change it
- No shared personal wallets, family accounts, or a second login for a business partner. The company workspace in section 11 is a private ledger owned by the signed-in user
- No social login
- No offline write queue or local database cache as the source of truth
- No bank sync, SMS parsing, or imports except that the user types data (CSV is export only)
- No tax reports, invoices, or double-entry journal beyond the transaction and loan tables described above
- No editing of a loan’s original amount or type after creation
- No reversal of loan-linked transactions when a loan is deleted

---

## 10. How to answer questions about this app

- Talk about behavior the user sees first, then the table or trigger if the question is technical.
- When asked “what happens to my balance”, trace the transaction rows and the triggers in section 6. Do not say the Flutter screen updates the balance itself, except for an account’s initial balance.
- When asked about monthly income or expense, remember transfers and loan opening/repayment rows are ordinary transactions and are included.
- When a feature is in section 9, say the app does not do that.
- Code lives under `D:\Flutter\expense_tracker` (or the repo root `expense_tracker`). Schema lives in `supabase/migrations/`.
- The product name is Expense Tracker.

---

## 11. Opt-in company / partner workspace

Off unless `profiles.company_mode_enabled` is true. Settings shows a Workspace switch, **Company / Partner Ledger**. Turning it on the first time asks for a company name, a partner name, and the user's share percent. The partner does not get an account. Turning it off hides the workspace and keeps the rows.

Company money is not part of personal accounts, the dashboard total, or reports. The only bridge is optional: a **my withdrawal** can also write a personal `income` transaction (`Payout from {company}`), and a **my contribution** can write a personal `expense` (`Contribution to {company}`). Deleting that company row deletes the linked personal row.

Tables: `company_ledgers` (one combined pool plus my share and partner share) and `company_transactions`. Types: `income`, `shared_expense`, `my_withdrawal`, `partner_withdrawal`, `my_contribution`, `partner_contribution`. Income and shared expenses split by the current percents, with the partner getting the remainder after rounding. Withdrawals and contributions assign the full amount to one side. Postgres triggers maintain the three ledger balances on insert, update, and delete. The Flutter code does not write those balances.

Routes, only reached from the dashboard switcher or company screens: `/company`, `/company/transactions`, `/company/tx/form`. The dashboard shows **Personal | {company name}** only while company mode is on. CSV export adds a `[COMPANY TRANSACTIONS]` section when a ledger exists. Delete all data removes company rows first and sets company mode back to false.

Changing the split percent does not rewrite old transactions or the balances already stored.
