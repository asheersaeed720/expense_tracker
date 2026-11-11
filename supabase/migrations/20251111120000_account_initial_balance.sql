-- opening_balance from (balance - net) backfill can add phantom amounts (e.g. +200 on bank).
-- initial_balance is set only at account creation and never derived from drift.

ALTER TABLE public.accounts
  ADD COLUMN IF NOT EXISTS initial_balance numeric NOT NULL DEFAULT 0;

-- Accounts with transactions: starting amount is unknown after bad backfill — trust txs only.
UPDATE public.accounts a
SET initial_balance = 0
WHERE EXISTS (
  SELECT 1 FROM public.transactions t WHERE t.account_id = a.id
);

-- Accounts with no transactions: keep whatever balance they have now as their starting amount.
UPDATE public.accounts a
SET initial_balance = a.balance
WHERE NOT EXISTS (
  SELECT 1 FROM public.transactions t WHERE t.account_id = a.id
);

UPDATE public.accounts SET opening_balance = 0
WHERE EXISTS (
  SELECT 1 FROM public.transactions t WHERE t.account_id = a.id
);
