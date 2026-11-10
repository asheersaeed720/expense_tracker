-- Expense Tracker — initial schema

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text,
  currency text NOT NULL DEFAULT 'PKR',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('cash', 'bank', 'wallet')),
  balance numeric NOT NULL DEFAULT 0,
  icon text,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles (id) ON DELETE CASCADE,
  name text NOT NULL,
  icon text,
  type text NOT NULL CHECK (type IN ('expense', 'income')),
  color text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES public.accounts (id) ON DELETE RESTRICT,
  category_id uuid REFERENCES public.categories (id) ON DELETE SET NULL,
  type text NOT NULL CHECK (type IN ('expense', 'income')),
  amount numeric NOT NULL CHECK (amount > 0),
  description text,
  date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.loans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  account_id uuid REFERENCES public.accounts (id) ON DELETE SET NULL,
  person_name text NOT NULL,
  phone text,
  type text NOT NULL CHECK (type IN ('given', 'taken')),
  amount numeric NOT NULL CHECK (amount > 0),
  remaining_amount numeric NOT NULL CHECK (remaining_amount >= 0),
  description text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'settled')),
  due_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.loan_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id uuid NOT NULL REFERENCES public.loans (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  amount numeric NOT NULL CHECK (amount > 0),
  account_id uuid REFERENCES public.accounts (id) ON DELETE SET NULL,
  note text,
  paid_at date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_accounts_user_id ON public.accounts (user_id);

CREATE INDEX idx_categories_user_id ON public.categories (user_id);

CREATE INDEX idx_transactions_user_id ON public.transactions (user_id);
CREATE INDEX idx_transactions_date ON public.transactions (date);
CREATE INDEX idx_transactions_user_date ON public.transactions (user_id, date DESC);

CREATE INDEX idx_loans_user_id ON public.loans (user_id);

CREATE INDEX idx_loan_payments_loan_id ON public.loan_payments (loan_id);
CREATE INDEX idx_loan_payments_user_id ON public.loan_payments (user_id);
CREATE INDEX idx_loan_payments_paid_at ON public.loan_payments (paid_at);

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER accounts_set_updated_at
  BEFORE UPDATE ON public.accounts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER transactions_set_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER loans_set_updated_at
  BEFORE UPDATE ON public.loans
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Seed default categories when a profile is created
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.seed_user_categories()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.categories (user_id, name, icon, type, color) VALUES
    (NEW.id, 'Food', 'restaurant', 'expense', '#FF6B6B'),
    (NEW.id, 'Transport', 'directions_car', 'expense', '#4ECDC4'),
    (NEW.id, 'Shopping', 'shopping_bag', 'expense', '#FFE66D'),
    (NEW.id, 'Bills', 'receipt_long', 'expense', '#95E1D3'),
    (NEW.id, 'Health', 'local_hospital', 'expense', '#F38181'),
    (NEW.id, 'Entertainment', 'movie', 'expense', '#AA96DA'),
    (NEW.id, 'Education', 'school', 'expense', '#6C5CE7'),
    (NEW.id, 'Other', 'more_horiz', 'expense', '#A0A0A0'),
    (NEW.id, 'Salary', 'payments', 'income', '#00B894'),
    (NEW.id, 'Freelance', 'laptop', 'income', '#0984E3'),
    (NEW.id, 'Business', 'store', 'income', '#FDCB6E'),
    (NEW.id, 'Gift', 'card_giftcard', 'income', '#E17055'),
    (NEW.id, 'Other', 'more_horiz', 'income', '#A0A0A0');

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_profile_created_seed_categories
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.seed_user_categories();

-- ---------------------------------------------------------------------------
-- Account balance on new transaction
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_account_balance_on_transaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.type = 'expense' THEN
    UPDATE public.accounts
    SET balance = balance - NEW.amount,
        updated_at = now()
    WHERE id = NEW.account_id;
  ELSIF NEW.type = 'income' THEN
    UPDATE public.accounts
    SET balance = balance + NEW.amount,
        updated_at = now()
    WHERE id = NEW.account_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_transaction_insert_update_balance
  AFTER INSERT ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_account_balance_on_transaction();

-- ---------------------------------------------------------------------------
-- Loan payment → remaining amount & status
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_loan_after_payment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  loan_row public.loans%ROWTYPE;
  new_remaining numeric;
BEGIN
  SELECT * INTO loan_row FROM public.loans WHERE id = NEW.loan_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan not found';
  END IF;

  new_remaining := loan_row.remaining_amount - NEW.amount;
  IF new_remaining < 0 THEN
    new_remaining := 0;
  END IF;

  UPDATE public.loans
  SET
    remaining_amount = new_remaining,
    status = CASE
      WHEN new_remaining <= 0 THEN 'settled'
      WHEN new_remaining < loan_row.amount THEN 'partial'
      ELSE 'pending'
    END,
    updated_at = now()
  WHERE id = NEW.loan_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_loan_payment_insert
  AFTER INSERT ON public.loan_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_loan_after_payment();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_payments ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- accounts
CREATE POLICY accounts_all_own ON public.accounts
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- categories: own rows + optional system defaults (user_id IS NULL)
CREATE POLICY categories_select ON public.categories
  FOR SELECT TO authenticated
  USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY categories_insert_own ON public.categories
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY categories_update_own ON public.categories
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY categories_delete_own ON public.categories
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- transactions
CREATE POLICY transactions_all_own ON public.transactions
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- loans
CREATE POLICY loans_all_own ON public.loans
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- loan_payments
CREATE POLICY loan_payments_all_own ON public.loan_payments
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
