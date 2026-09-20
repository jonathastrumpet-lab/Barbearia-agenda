-- Agenda Hub - camada Platform Admin
-- Aplicar no Supabase antes de liberar as funções administrativas em produção.
create table if not exists public.subscription_plans(
 id uuid primary key default gen_random_uuid(), name text not null unique, description text, price numeric(12,2) not null default 0,
 billing_period text not null default 'monthly', active boolean not null default true,
 max_professionals integer, max_admins integer, max_monthly_appointments integer, history_months integer,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.subscriptions(
 id uuid primary key default gen_random_uuid(), barbershop_id uuid not null references public.barbershops(id) on delete cascade,
 plan_id uuid not null references public.subscription_plans(id), status text not null default 'trial'
 check(status in('trial','active','past_due','suspended','canceled','expired')),
 started_at timestamptz not null default now(), trial_ends_at timestamptz,current_period_start timestamptz,current_period_end timestamptz,
 canceled_at timestamptz,suspended_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create unique index if not exists subscriptions_one_current_per_shop on public.subscriptions(barbershop_id) where status in('trial','active','past_due','suspended');
create table if not exists public.establishment_limit_overrides(
 id uuid primary key default gen_random_uuid(),barbershop_id uuid not null references public.barbershops(id) on delete cascade,
 max_professionals integer,max_admins integer,max_monthly_appointments integer,history_months integer,
 reason text,created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),expires_at timestamptz
);
create table if not exists public.platform_audit_logs(
 id bigint generated always as identity primary key,actor_user_id uuid not null references auth.users(id),
 action text not null,target_type text not null,target_id text,barbershop_id uuid references public.barbershops(id),
 old_data jsonb,new_data jsonb,created_at timestamptz not null default now()
);
alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.establishment_limit_overrides enable row level security;
alter table public.platform_audit_logs enable row level security;
revoke all on public.subscription_plans,public.subscriptions,public.establishment_limit_overrides,public.platform_audit_logs from anon,authenticated;
grant all on public.subscription_plans,public.subscriptions,public.establishment_limit_overrides,public.platform_audit_logs to service_role;
-- Segurança: o APK nunca recebe service_role. Leitura/escrita global deve ocorrer por RPC/Edge Function
-- SECURITY DEFINER que valide is_platform_admin() no servidor e registre platform_audit_logs.
