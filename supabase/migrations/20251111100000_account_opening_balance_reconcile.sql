-- Track opening balance separately so balances can be repaired from transactions.

ALTER TABLE public.accounts
  ADD COLUMN IF NOT EXISTS opening_balance numeric NOT NULL DEFAULT 0;

-- Do not backfill opening_balance from (balance - transactions): a wrong balance
-- would permanently lock in the error. New accounts set opening_balance on insert.

CREATE OR REPLACE FUNCTION public.reconcile_user_account_balances()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.accounts a
  SET
    balance = a.opening_balance + COALESCE((
      SELECT SUM(
        CASE
          WHEN t.type = 'income' THEN t.amount
          WHEN t.type = 'expense' THEN -t.amount
          ELSE 0
        END
      )
      FROM public.transactions t
      WHERE t.account_id = a.id
    ), 0),
    updated_at = now()
  WHERE a.user_id = uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reconcile_user_account_balances() TO authenticated;
