-- Reverse / re-apply account balances when transactions are updated or deleted.

CREATE OR REPLACE FUNCTION public.apply_transaction_balance_delta(
  p_account_id uuid,
  p_type text,
  p_amount numeric,
  p_multiplier integer DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_type = 'expense' THEN
    UPDATE public.accounts
    SET balance = balance - (p_amount * p_multiplier),
        updated_at = now()
    WHERE id = p_account_id;
  ELSIF p_type = 'income' THEN
    UPDATE public.accounts
    SET balance = balance + (p_amount * p_multiplier),
        updated_at = now()
    WHERE id = p_account_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.revert_account_balance_on_transaction_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.apply_transaction_balance_delta(
    OLD.account_id,
    OLD.type,
    OLD.amount,
    -1
  );
  RETURN OLD;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_account_balance_on_transaction_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.account_id IS DISTINCT FROM NEW.account_id
      OR OLD.type IS DISTINCT FROM NEW.type
      OR OLD.amount IS DISTINCT FROM NEW.amount THEN
    PERFORM public.apply_transaction_balance_delta(
      OLD.account_id,
      OLD.type,
      OLD.amount,
      -1
    );
    PERFORM public.apply_transaction_balance_delta(
      NEW.account_id,
      NEW.type,
      NEW.amount,
      1
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_transaction_insert_update_balance ON public.transactions;

CREATE TRIGGER on_transaction_insert_update_balance
  AFTER INSERT ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_account_balance_on_transaction();

CREATE TRIGGER on_transaction_delete_revert_balance
  AFTER DELETE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.revert_account_balance_on_transaction_delete();

CREATE TRIGGER on_transaction_update_adjust_balance
  AFTER UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_account_balance_on_transaction_update();
