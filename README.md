# Expense Tracker

A cross-platform personal finance app built with Flutter. Track income and expenses across multiple accounts, manage loans (given and taken), view charts and reports, and sync everything to a [Supabase](https://supabase.com/) backend with email/password auth.

Default currency is **PKR**; profile settings store per-user currency and display name.

## Features

- **Authentication** — Sign up, sign in, forgot password, and secure session handling via Supabase Auth
- **Dashboard** — Total balance, account carousel, monthly stats, daily expense chart, and recent transactions
- **Transactions** — Create, edit, and delete income/expense entries with categories, accounts, dates, and search/filtering
- **Accounts** — Cash, bank, and wallet accounts; balances update with transactions; transfers between accounts
- **Categories** — Custom expense and income categories with icons and colors
- **Loans** — Track money given to or taken from others, record payments, and settlement status
- **Reports** — Category breakdown, income vs expense trends, account summaries, and period navigation
- **Settings** — Profile name, password change, CSV export (transactions and loans), delete-all-data, and sign out
- **Offline awareness** — Banner when the device has no connectivity

## Tech stack

| Layer | Choice |
|--------|--------|
| UI | Flutter (Material 3, dark theme) |
| State | [Riverpod](https://riverpod.dev/) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Backend | [Supabase](https://supabase.com/) (`supabase_flutter`) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Config | `flutter_dotenv` (`.env` bundled as an asset) |

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) **3.47.5** (this repo pins that version via [FVM](https://fvm.app/); run `fvm use` or use your own matching SDK)
- Dart **^3.13.4** (see `pubspec.yaml`)
- A Supabase project with the schema from `supabase/migrations/`

## Setup

### 1. Clone and install dependencies

```bash
cd expense_tracker
fvm flutter pub get   # or: flutter pub get
```

### 2. Environment variables

Create a `.env` file in the project root (it is listed in `pubspec.yaml` assets and must not be committed with real secrets):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

The app fails fast on startup if either value is missing (`lib/config/supabase/supabase_bootstrap.dart`).

### 3. Supabase database

Apply the SQL migrations in order:

1. `supabase/migrations/20251110000000_initial_schema.sql` — profiles, accounts, categories, transactions, loans, RLS, and triggers
2. `supabase/migrations/20251110120000_transaction_balance_update_delete.sql` — balance updates on transaction changes
3. `supabase/migrations/20251111100000_account_opening_balance_reconcile.sql` — opening balance + **Fix account balances** in Settings

You can run these in the Supabase SQL editor or with the [Supabase CLI](https://supabase.com/docs/guides/cli) linked to your project.

Enable **Email** auth in the Supabase dashboard for sign-up and login flows used by the app.

### 4. Run the app

```bash
fvm flutter run
```

**Android package:** `com.expensetracker.app`

**Splash:** Native splash color `#0D1117` (see `flutter_native_splash` in `pubspec.yaml`).

## Project structure

```
lib/
├── main.dart                 # dotenv + Supabase init, ProviderScope
├── app.dart                  # MaterialApp.router, theme, offline banner
├── config/                   # Router, theme, env, Supabase bootstrap
├── core/                     # Models, shared widgets, utilities
└── features/
    ├── auth/
    ├── dashboard/
    ├── transactions/
    ├── accounts/
    ├── categories/
    ├── loans/
    ├── reports/
    ├── settings/
    └── shell/                # Bottom navigation shell
supabase/migrations/          # Database schema
test/                         # Unit and widget tests
```

Navigation uses a four-tab shell: **Dashboard**, **Transactions**, **Loans**, and **Settings**. Accounts, categories, reports, and form/detail screens are pushed on top via `go_router`.

## Tests

```bash
fvm flutter test
```

Coverage includes validators, auth error mapping, transaction logic, loan math, and selected widgets (e.g. loan payment sheet).

## Platforms

Configured for **Android**, **iOS**, and desktop targets supported by your Flutter install. Primary development and builds are oriented toward mobile.

## License

Private project (`publish_to: 'none'`). Not published to pub.dev.

---

App display name: **Expense Tracker**
