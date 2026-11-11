-- Opt-in company / partner ledger. Personal account balances are untouched.
-- Ledger totals move only inside these triggers.

ALTER TABLE public.profiles
  ADD COLUMN company_mode_enabled boolean NOT NULL DEFAULT false;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE public.company_ledgers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  company_name text NOT NULL,
  partner_name text NOT NULL,
  my_share_percent numeric(5,2) NOT NULL DEFAULT 50.00
    CHECK (my_share_percent > 0 AND my_share_percent < 100),
  partner_share_percent numeric(5,2) NOT NULL DEFAULT 50.00,
  total_balance numeric(14,2) NOT NULL DEFAULT 0,
  my_share_balance numeric(14,2) NOT NULL DEFAULT 0,
  partner_share_balance numeric(14,2) NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT company_ledgers_shares_sum
    CHECK (my_share_percent + partner_share_percent = 100)
);

CREATE TABLE public.company_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ledger_id uuid NOT NULL REFERENCES public.company_ledgers (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN (
    'income',
    'shared_expense',
    'my_withdrawal',
    'partner_withdrawal',
    'my_contribution',
    'partner_contribution'
  )),
  amount numeric(14,2) NOT NULL CHECK (amount > 0),
  my_split_amount numeric(14,2) NOT NULL CHECK (my_split_amount >= 0),
  partner_split_amount numeric(14,2) NOT NULL CHECK (partner_split_amount >= 0),
  category text NOT NULL DEFAULT 'Other',
  description text,
  date date NOT NULL DEFAULT CURRENT_DATE,
  linked_personal_tx_id uuid REFERENCES public.transactions (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT company_tx_splits_sum
    CHECK (my_split_amount + partner_split_amount = amount)
);

CREATE INDEX idx_company_ledgers_user_id ON public.company_ledgers (user_id);
CREATE INDEX idx_company_transactions_user_id ON public.company_transactions (user_id);
CREATE INDEX idx_company_transactions_ledger_id ON public.company_transactions (ledger_id);
CREATE INDEX idx_company_transactions_user_date
  ON public.company_transactions (user_id, date DESC);

CREATE TRIGGER company_ledgers_set_updated_at
  BEFORE UPDATE ON public.company_ledgers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER company_transactions_set_updated_at
  BEFORE UPDATE ON public.company_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Splits: the app sends them. The trigger fills them when they do not add up
-- to the amount, and forces the fixed splits for withdrawals / contributions.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fill_company_tx_splits()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  my_pct numeric;
BEGIN
  IF NEW.type IN ('my_withdrawal', 'my_contribution') THEN
    NEW.my_split_amount := NEW.amount;
    NEW.partner_split_amount := 0;
    RETURN NEW;
  END IF;

  IF NEW.type IN ('partner_withdrawal', 'partner_contribution') THEN
    NEW.my_split_amount := 0;
    NEW.partner_split_amount := NEW.amount;
    RETURN NEW;
  END IF;

  IF NEW.my_split_amount + NEW.partner_split_amount IS DISTINCT FROM NEW.amount
      OR NEW.my_split_amount < 0
      OR NEW.partner_split_amount < 0 THEN
    SELECT my_share_percent INTO my_pct
    FROM public.company_ledgers
    WHERE id = NEW.ledger_id;

    IF my_pct IS NULL THEN
      RAISE EXCEPTION 'Company ledger not found';
    END IF;

    NEW.my_split_amount := round(NEW.amount * (my_pct / 100.0), 2);
    NEW.partner_split_amount := NEW.amount - NEW.my_split_amount;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER company_tx_fill_splits
  BEFORE INSERT OR UPDATE ON public.company_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.fill_company_tx_splits();

-- ---------------------------------------------------------------------------
-- Ledger balances. UPDATE reverses the old row, then applies the new row.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_company_ledger_delta(
  p_ledger_id uuid,
  p_type text,
  p_amount numeric,
  p_my numeric,
  p_partner numeric,
  p_sign integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_delta numeric := 0;
  my_delta numeric := 0;
  partner_delta numeric := 0;
BEGIN
  IF p_type = 'income' THEN
    total_delta := p_amount;
    my_delta := p_my;
    partner_delta := p_partner;
  ELSIF p_type = 'shared_expense' THEN
    total_delta := -p_amount;
    my_delta := -p_my;
    partner_delta := -p_partner;
  ELSIF p_type = 'my_withdrawal' THEN
    total_delta := -p_amount;
    my_delta := -p_amount;
  ELSIF p_type = 'partner_withdrawal' THEN
    total_delta := -p_amount;
    partner_delta := -p_amount;
  ELSIF p_type = 'my_contribution' THEN
    total_delta := p_amount;
    my_delta := p_amount;
  ELSIF p_type = 'partner_contribution' THEN
    total_delta := p_amount;
    partner_delta := p_amount;
  END IF;

  UPDATE public.company_ledgers
  SET
    total_balance = total_balance + (total_delta * p_sign),
    my_share_balance = my_share_balance + (my_delta * p_sign),
    partner_share_balance = partner_share_balance + (partner_delta * p_sign),
    updated_at = now()
  WHERE id = p_ledger_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.adjust_company_ledger_on_tx()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.apply_company_ledger_delta(
      NEW.ledger_id, NEW.type, NEW.amount,
      NEW.my_split_amount, NEW.partner_split_amount, 1
    );
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM public.apply_company_ledger_delta(
      OLD.ledger_id, OLD.type, OLD.amount,
      OLD.my_split_amount, OLD.partner_split_amount, -1
    );
    PERFORM public.apply_company_ledger_delta(
      NEW.ledger_id, NEW.type, NEW.amount,
      NEW.my_split_amount, NEW.partner_split_amount, 1
    );
    RETURN NEW;
  ELSE
    PERFORM public.apply_company_ledger_delta(
      OLD.ledger_id, OLD.type, OLD.amount,
      OLD.my_split_amount, OLD.partner_split_amount, -1
    );
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER company_tx_adjust_ledger
  AFTER INSERT OR UPDATE OR DELETE ON public.company_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.adjust_company_ledger_on_tx();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE public.company_ledgers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY company_ledgers_all_own ON public.company_ledgers
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY company_transactions_all_own ON public.company_transactions
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
