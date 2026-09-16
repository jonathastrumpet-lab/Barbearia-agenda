-- Agenda Hub - agenda compartilhada no Supabase
-- Execute este arquivo no SQL Editor do projeto Supabase.

create table if not exists public.appointments (
  id text primary key,
  shop_id text not null,
  client_id uuid not null references auth.users(id) on delete cascade,
  service text not null,
  duration text not null,
  price text not null,
  barber text not null,
  date_iso text not null,
  time text not null,
  created_at_iso timestamptz not null default now(),
  status text not null default 'active'
    check (status in ('active', 'cancelled'))
);

-- Um profissional não pode ter dois atendimentos ativos no mesmo horário.
create unique index if not exists appointments_active_slot_unique
  on public.appointments (shop_id, barber, date_iso, time)
  where status = 'active';

create index if not exists appointments_shop_schedule_idx
  on public.appointments (shop_id, date_iso, time);

create index if not exists appointments_client_idx
  on public.appointments (client_id);

alter table public.appointments enable row level security;

-- Somente usuários autenticados (inclusive login anônimo do app) usam a tabela.
revoke all on table public.appointments from anon;
grant select, insert, update on table public.appointments to authenticated;
grant all on table public.appointments to service_role;

-- Para montar a agenda compartilhada, usuários autenticados podem consultar
-- horários do estabelecimento. A tabela não guarda nome, telefone ou e-mail.
drop policy if exists "authenticated can view schedule" on public.appointments;
create policy "authenticated can view schedule"
  on public.appointments
  for select
  to authenticated
  using (true);

-- Cada instalação só pode criar agendamentos vinculados ao próprio usuário.
drop policy if exists "client can create own appointment" on public.appointments;
create policy "client can create own appointment"
  on public.appointments
  for insert
  to authenticated
  with check (client_id = (select auth.uid()));

-- Neste estágio o cliente só pode alterar o próprio agendamento.
drop policy if exists "client can update own appointment" on public.appointments;
create policy "client can update own appointment"
  on public.appointments
  for update
  to authenticated
  using (client_id = (select auth.uid()))
  with check (client_id = (select auth.uid()));

-- Não concedemos DELETE ao aplicativo. Cancelamento muda status para cancelled,
-- preservando histórico e auditoria.
