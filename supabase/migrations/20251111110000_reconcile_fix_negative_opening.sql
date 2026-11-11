-- The first reconcile migration set opening_balance = balance - net_transactions.
-- If balance was already wrong (e.g. -80 after a mis-assigned expense), that drift
-- was baked into opening_balance and "Fix account balances" could not recover.
-- Negative opening_balance is not a valid user intent; clamp to zero when repairing.

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
    opening_balance = GREATEST(a.opening_balance, 0),
    balance = GREATEST(a.opening_balance, 0) + COALESCE((
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
