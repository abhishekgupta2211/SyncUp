-- SyncUp — 0018 device push tokens (FCM)
-- Stores each device's FCM registration token so the `push` Edge Function can
-- deliver background/terminated notifications. A token maps to exactly ONE user
-- (the most recent login on that device) — enforced by register_device_token.

create table if not exists public.device_tokens (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  token      text not null,
  platform   text not null default 'android' check (platform in ('android','ios','web')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);
create index if not exists idx_device_tokens_user on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- Clients only ever touch their own rows; the Edge Function reads via service role.
drop policy if exists device_tokens_select on public.device_tokens;
create policy device_tokens_select on public.device_tokens
  for select to authenticated using (user_id = auth.uid());
drop policy if exists device_tokens_insert on public.device_tokens;
create policy device_tokens_insert on public.device_tokens
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists device_tokens_update on public.device_tokens;
create policy device_tokens_update on public.device_tokens
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists device_tokens_delete on public.device_tokens;
create policy device_tokens_delete on public.device_tokens
  for delete to authenticated using (user_id = auth.uid());

-- Register (or move) a device token to the current user. Deleting any prior
-- owner of the same token prevents pushes leaking to a previously-signed-in user.
create or replace function public.register_device_token(p_token text, p_platform text default 'android')
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  delete from public.device_tokens where token = p_token and user_id <> auth.uid();
  insert into public.device_tokens (user_id, token, platform)
    values (auth.uid(), p_token, p_platform)
    on conflict (user_id, token)
      do update set updated_at = now(), platform = excluded.platform;
end; $$;
grant execute on function public.register_device_token(text, text) to authenticated;

create or replace function public.unregister_device_token(p_token text)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
end; $$;
grant execute on function public.unregister_device_token(text) to authenticated;
