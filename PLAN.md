# Expense Tracker App — Phase-wise Cursor Prompts

> [!TIP]
> Copy-paste each phase into Cursor **one at a time**. Complete and verify each phase before moving to the next. Each prompt is self-contained but builds on previous work.

---

## Phase 0 — Project Scaffolding & Supabase Schema

```text
Create a Flutter expense tracker app called "Expense Tracker" with Supabase backend.

## Project Setup
- Flutter project with clean architecture (lib/core, lib/features, lib/config)
- Use these packages: supabase_flutter, flutter_riverpod (for state management), go_router (navigation), intl (date/currency formatting), fl_chart (charts later), google_fonts
- Folder structure:
  lib/
    config/        — theme, router, supabase init, constants
    core/          — shared models, enums, utils, extensions, widgets
    features/
      auth/        — screens, providers, services
      dashboard/   — screens, providers, widgets
      transactions/ — screens, providers, services, models
      loans/       — screens, providers, services, models
      accounts/    — screens, providers, services, models
      settings/    — screens, providers

## Supabase SQL Schema (generate a single migration file)
Tables needed:

1. `profiles` — extends Supabase auth.users
   - id (uuid, FK to auth.users, PK)
   - full_name (text)
   - currency (text, default 'PKR')
   - created_at, updated_at

2. `accounts` — represents money sources (cash-in-hand, bank accounts)
   - id (uuid, PK, default gen_random_uuid())
   - user_id (uuid, FK to profiles, NOT NULL)
   - name (text, NOT NULL) — e.g. "Cash", "JazzCash", "HBL"
   - type (text, NOT NULL) — enum: 'cash', 'bank', 'wallet'
   - balance (numeric, default 0)
   - icon (text, nullable)
   - is_default (boolean, default false)
   - created_at, updated_at

3. `categories` — expense/income categories
   - id (uuid, PK)
   - user_id (uuid, FK, nullable — null means system default)
   - name (text, NOT NULL)
   - icon (text)
   - type (text, NOT NULL) — 'expense' or 'income'
   - color (text, nullable)
   - created_at

4. `transactions` — every expense or income entry
   - id (uuid, PK)
   - user_id (uuid, FK, NOT NULL)
   - account_id (uuid, FK to accounts, NOT NULL)
   - category_id (uuid, FK to categories, nullable)
   - type (text, NOT NULL) — 'expense' or 'income'
   - amount (numeric, NOT NULL, CHECK > 0)
   - description (text, nullable)
   - date (date, NOT NULL, default CURRENT_DATE)
   - created_at, updated_at

5. `loans` — money lent or borrowed
   - id (uuid, PK)
   - user_id (uuid, FK, NOT NULL)
   - account_id (uuid, FK to accounts, nullable — which account was used)
   - person_name (text, NOT NULL)
   - phone (text, nullable)
   - type (text, NOT NULL) — 'given' (I lent) or 'taken' (I borrowed)
   - amount (numeric, NOT NULL, CHECK > 0)
   - remaining_amount (numeric, NOT NULL)
   - description (text, nullable)
   - status (text, default 'pending') — 'pending', 'partial', 'settled'
   - due_date (date, nullable)
   - created_at, updated_at

6. `loan_payments` — partial repayments against a loan
   - id (uuid, PK)
   - loan_id (uuid, FK to loans, NOT NULL)
   - user_id (uuid, FK, NOT NULL)
   - amount (numeric, NOT NULL, CHECK > 0)
   - account_id (uuid, FK to accounts, nullable)
   - note (text, nullable)
   - paid_at (date, default CURRENT_DATE)
   - created_at

- Add Row-Level Security (RLS) on ALL tables: users can only read/write their own rows.
- Add indexes on user_id and date columns.
- Create a trigger: after INSERT on `transactions`, auto-update the `accounts.balance` (subtract for expense, add for income).
- Create a trigger: after INSERT on `loan_payments`, update `loans.remaining_amount` and `loans.status`.
- Seed default categories for each new user via a trigger on profiles insert:
  Expenses: Food, Transport, Shopping, Bills, Health, Entertainment, Education, Other
  Income: Salary, Freelance, Business, Gift, Other

## Flutter Setup
- Initialize Supabase in main.dart (read URL and anon key from env or constants)
- Set up Riverpod providers at root
- Set up GoRouter with auth guard (redirect to login if not authenticated)
- Create a dark-only ThemeData (we'll refine it later)
- Build and run to confirm zero errors.

Output the complete migration SQL file and all the Flutter scaffolding files.
```

---

## Phase 1 — Authentication

```text
Implement authentication for the Expense Tracker app using Supabase Auth.

## Screens
1. **Splash Screen** — check if user is logged in, redirect accordingly. Show app logo centered.
2. **Login Screen** — email + password login, "Don't have an account? Sign Up" link
3. **Sign Up Screen** — full name, email, password, confirm password. On signup, create a row in `profiles` table and seed 2 default accounts: "Cash in Hand" (type: cash, is_default: true) and "Bank Account" (type: bank).
4. **Forgot Password Screen** — email input, sends reset link via Supabase

## Requirements
- Use Riverpod for auth state management (create an authProvider, authStateProvider)
- Create an AuthService class that wraps Supabase auth methods
- GoRouter should listen to auth state changes and redirect accordingly
- Show loading indicators during auth operations
- Show snackbar on errors (wrong password, email taken, etc.)
- After login/signup, navigate to Dashboard
- Email validation, password min 6 chars
- All screens should use the dark theme
- Clean, minimal UI with proper spacing and a consistent style

Do NOT modify the database schema. Use the existing tables.
```

---

## Phase 2 — Dashboard & Account Balances

```text
Build the Dashboard and Account management screens for the Expense Tracker app.

## Dashboard Screen (Home)
This is the main screen after login. It should show:

1. **Top greeting** — "Hello, {user name}" with current date
2. **Total Balance Card** — a prominent card showing total balance across all accounts, formatted as PKR with commas (e.g., PKR 12,500)
3. **Account Summary Cards** — horizontal scrollable row showing each account (Cash in Hand, Bank, etc.) with name, type icon, and balance
4. **Quick Stats Row** — this month's total income vs total expense (two cards side by side, income green, expense red)
5. **Recent Transactions List** — last 5 transactions with: category icon, description/category name, amount (colored red/green), date, account name. Tapping "See All" goes to full transaction list.

## Accounts Management Screen
- List all accounts with name, type, balance
- Floating action button to add new account (name, type dropdown: cash/bank/wallet, initial balance)
- Tap an account to edit name or delete it (confirm dialog, block if balance ≠ 0 or has transactions)
- Transfer between accounts: button that opens a modal — select from-account, to-account, amount. This creates 2 transactions (expense from source, income to destination) with description "Transfer to/from {account name}".

## Bottom Navigation Bar
Set up a persistent bottom nav with 4 tabs:
1. Dashboard (home icon)
2. Transactions (list icon)  
3. Loans (handshake icon)
4. Settings (gear icon)

## State Management
- Create providers for: accounts list, total balance, monthly income/expense stats, recent transactions
- All data fetched from Supabase with real-time subscriptions where possible
- Pull-to-refresh on dashboard

Use clean card-based dark theme UI. All amounts formatted as PKR.
```

---

## Phase 3 — Expense & Income Tracking (Transactions)

```text
Build the full Transactions feature for the Expense Tracker app.

## Add Transaction Screen
A bottom sheet or full screen form with:
- **Type toggle** at top: Expense / Income (segmented button, default Expense)
- **Amount input** — large, centered, numeric keyboard, PKR prefix
- **Account selector** — dropdown of user's accounts
- **Category selector** — grid of category chips (filtered by expense/income type), each with icon and name
- **Date picker** — defaults to today, can pick past dates
- **Description** — optional text field
- **Save button** — validates (amount > 0, account selected, category selected), saves to `transactions` table. The account balance is updated by the DB trigger.
- After save, show success snackbar and pop back to previous screen

## Transactions List Screen (Tab 2)
- **Filter bar** at top: 
  - Date range filter (This month / Last month / Custom range)
  - Type filter (All / Expense / Income)
  - Account filter (All / specific account)
- **Transaction list** grouped by date (today, yesterday, or date heading)
  - Each item: category icon + color dot, category name, description (if any), amount (red for expense, green for income), account name badge
  - Swipe left to delete (with confirmation)
  - Tap to view detail → option to edit or delete
- **Summary header** showing filtered totals: total income, total expense, net

## Edit Transaction
- Same form as Add, pre-filled with existing data
- On save, reverse the old transaction's effect on balance and apply new one (handle via Supabase — delete old, insert new, or update + recalculate)

## Categories Management (accessible from Settings)
- List current categories grouped by type
- Add custom category (name, pick icon from predefined list, type)
- Edit/delete custom categories (don't allow deleting system defaults)

## State Management  
- Riverpod providers for transactions list with filters
- Pagination: load 20 at a time, load more on scroll
- Refresh on add/edit/delete

All UI in dark theme. Amounts formatted with PKR and commas.
```

---

## Phase 4 — Loans Management

```text
Build the Loans feature for the Expense Tracker app.

## Loans List Screen (Tab 3)
- **Two tabs** at top: "Given" (I lent money) and "Taken" (I borrowed money)
- **Summary card** at top of each tab:
  - Given tab: "Total lent: PKR X | Outstanding: PKR Y"
  - Taken tab: "Total borrowed: PKR X | Outstanding: PKR Y"
- **Loan list**: each card shows:
  - Person name, phone (if available)
  - Original amount, remaining amount
  - Status badge: Pending (orange), Partial (blue), Settled (green)
  - Due date (if set), highlight in red if overdue
  - Progress bar showing how much is repaid
- Tap a loan card to see detail screen
- FAB to add new loan

## Add Loan Screen
Bottom sheet or full screen:
- Type: Given / Taken (segmented button)
- Person name (required)
- Phone number (optional)
- Amount (required, numeric)
- Account (which account the money went from/to — optional)
- Description (optional)
- Due date (optional date picker)
- Save: creates loan record. If account is selected:
  - For "Given" loan: creates an expense transaction from that account (description: "Loan to {person}")
  - For "Taken" loan: creates an income transaction to that account (description: "Loan from {person}")

## Loan Detail Screen
Shows full loan info plus:
- **Payment history** — list of all partial payments with date, amount, note
- **Record Payment button** — opens a form:
  - Amount (must be ≤ remaining_amount)
  - Account (which account received/paid)
  - Note (optional)
  - Date (default today)
  - On save: creates loan_payment record, trigger updates remaining_amount and status. Also creates a transaction (income if "given" loan repaid to me, expense if I repaid a "taken" loan).
- **Settle button** — mark as fully settled (records remaining as final payment)
- **Edit / Delete** loan options in app bar menu

## State Management
- Providers for loans list filtered by type
- Provider for single loan detail with payments
- Refresh on changes

Dark theme. PKR formatting. Show empty state illustrations when no loans exist.
```

---

## Phase 5 — Reports & Charts

```text
Add a Reports section to the Expense Tracker app Dashboard.

## Reports (accessible from Dashboard via a "View Reports" button or a dedicated section)

### Monthly Overview Card (on Dashboard)
- Bar chart showing daily expenses for the current month (using fl_chart)
- Below it: comparison with last month ("You spent 15% more/less than last month")

### Reports Screen (full page, navigate from Dashboard)

1. **Expense by Category** — Pie/Donut chart showing expense breakdown by category for selected month. Below the chart, list categories sorted by amount with percentage bars.

2. **Income vs Expense** — Bar chart comparing income and expense for last 6 months. Show net savings for each month.

3. **Account-wise Summary** — Table showing each account with: opening balance (start of month), income, expense, closing balance.

4. **Date Range Selector** — at top of reports screen, pick month/year or custom date range. All charts update accordingly.

## Implementation
- Create a ReportsService that runs aggregate queries on Supabase (use .rpc() for complex queries, or fetch and compute client-side for MVP)
- Cache results in Riverpod providers
- Use fl_chart for all charts with dark theme colors (use accent colors that pop on dark background — teal, amber, coral)
- Show loading skeletons while data loads
- Handle empty states gracefully

Keep the dark theme consistent. All amounts in PKR.
```

---

## Phase 6 — Settings & Polish

```text
Build the Settings screen and final polish for the Expense Tracker app.

## Settings Screen (Tab 4)

1. **Profile Section**
   - User name, email display
   - Edit name
   - Change password (via Supabase)

2. **Categories Management** — navigate to categories list (built in Phase 3)

3. **Accounts Management** — navigate to accounts screen (built in Phase 2)

4. **Data & Privacy**
   - Export data as CSV (transactions, loans)
   - Delete all data (with triple confirmation)

5. **About**
   - App version
   - Developer info

6. **Logout** — with confirmation dialog

## Polish & UX Improvements

1. **Empty States** — add friendly illustrations/messages for:
   - No transactions yet
   - No loans yet
   - No accounts
   
2. **Loading States** — shimmer/skeleton loaders on all list screens and dashboard

3. **Error Handling** — global error handler, retry buttons on failed loads, offline detection with banner

4. **Haptic Feedback** — on button taps, swipe actions

5. **Animations**
   - Hero animations on cards where appropriate
   - Smooth page transitions
   - Amount counter animation on dashboard total

6. **Confirmation Dialogs** — for all destructive actions (delete transaction, delete loan, delete account, logout)

7. **Search** — add search to transaction list (search by description, category, amount)

8. **App Icon & Splash** — generate a simple app icon (wallet/rupee symbol) and native splash screen

## Final Checks
- Ensure all Supabase RLS policies are correct
- Test all CRUD operations
- Verify balance calculations are accurate after all operations
- Ensure no console errors or warnings
- Responsive layout (works on different screen sizes)
```

---

## Phase 7 — Urdu Localization (Optional)

```text
Add Urdu language support to the Expense Tracker app.

## Setup
- Add flutter_localizations and intl packages (if not already)
- Set up ARB files: lib/l10n/app_en.arb and lib/l10n/app_ur.arb
- Configure l10n.yaml for code generation

## Translate ALL user-facing strings to Urdu, including:
- Navigation labels (ڈیش بورڈ, لین دین, قرض, ترتیبات)
- Dashboard (کل بیلنس, آمدنی, اخراجات, حالیہ لین دین)
- Transaction labels (اخراجات, آمدنی, رقم, تفصیل, تاریخ, زمرہ)
- Loan labels (دیا گیا, لیا گیا, واپسی, بقایا, ادائیگی)
- Category names (خوراک, نقل و حمل, خریداری, بل, صحت, تفریح, تعلیم, تنخواہ, فری لانس, کاروبار)
- Buttons (محفوظ کریں, حذف کریں, ترمیم, منسوخ)
- Settings labels
- Error messages
- Empty state messages
- Confirmation dialogs

## RTL Support
- Ensure all layouts work correctly in RTL mode for Urdu
- Test text alignment, icon positions, swipe directions
- Number formatting should remain LTR even in Urdu locale

## Language Switcher
- Add a language toggle in Settings (English / اردو)
- Persist selection in local storage (shared_preferences)
- App should restart locale without full app restart

## Font
- Use a font that supports both Urdu Nastaliq and English (e.g., Noto Nastaliq Urdu for Urdu text via google_fonts)
- Ensure Urdu text is legible at all sizes

Test the entire app in Urdu — every screen, every dialog, every error message.
```

---

## Summary Checklist

| Phase | What You Get | Est. Complexity |
|-------|-------------|-----------------|
| 0 | Project structure, DB schema, theming | Medium |
| 1 | Auth (login, signup, forgot password) | Low |
| 2 | Dashboard, accounts, bottom nav | Medium |
| 3 | Full transaction CRUD with filters | High |
| 4 | Loans with partial payments | High |
| 5 | Charts and reports | Medium |
| 6 | Settings, polish, error handling | Medium |
| 7 | Urdu localization + RTL | Medium |

> [!IMPORTANT]
> **After each phase**, tell Cursor: *"Review the code for bugs, fix any compile errors, and make sure the app runs without crashes."* This prevents error accumulation across phases.

> [!TIP]
> If Cursor's context gets too long mid-phase, start a new chat and say: *"Continue building the Expense Tracker app. I've completed Phase X. Now implement Phase Y. Here's the current project structure: [paste tree output]"*
