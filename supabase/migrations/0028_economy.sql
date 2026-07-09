-- LoveChat — 0028 Economy & Gifts
-- Adds coins to profiles and virtual gift tracking.

alter table public.profiles
add column if not exists coin_balance int default 500; -- New users get 500 free coins

create table if not exists public.gifts (
  id      uuid primary key default gen_random_uuid(),
  name    text not null,
  icon    text not null,
  price   int not null
);

create table if not exists public.sent_gifts (
  id          uuid primary key default gen_random_uuid(),
  sender_id   uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  gift_id     uuid not null references public.gifts(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- RLS
alter table public.gifts enable row level security;
alter table public.sent_gifts enable row level security;

create policy "gifts_select" on public.gifts for select to authenticated using (true);
create policy "sent_gifts_all" on public.sent_gifts for all to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());

-- Initial Gifts
insert into public.gifts (name, icon, price) values
('Red Rose', '🌹', 10),
('Heart', '❤️', 50),
('Diamond', '💎', 200),
('Crown', '👑', 500);
