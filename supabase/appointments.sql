-- Estrutura inicial da agenda compartilhada.
-- Execute no SQL Editor do Supabase quando o projeto de nuvem for criado.

create table if not exists public.appointments (
  id text primary key,
  shop_id text not null,
  service text not null,
  duration text not null,
  price text not null,
  barber text not null,
  date_iso text not null,
  time text not null,
  created_at_iso timestamptz not null,
  status text not null default 'active'
    check (status in ('active', 'cancelled'))
);

-- Impede dois clientes de reservarem o mesmo barbeiro no mesmo dia/horário.
create unique index if not exists appointments_active_slot_unique
  on public.appointments (shop_id, barber, date_iso, time)
  where status = 'active';

create index if not exists appointments_shop_schedule_idx
  on public.appointments (shop_id, date_iso, time);

-- IMPORTANTE:
-- Não habilitamos políticas públicas automaticamente neste arquivo.
-- Antes de ativar o APK com SUPABASE_URL/SUPABASE_ANON_KEY, vamos configurar
-- autenticação e Row Level Security (RLS) para não deixar a agenda exposta.
