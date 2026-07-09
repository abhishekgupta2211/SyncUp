-- SyncUp — 0021 AI Assistant (Groq) conversation history
-- Per-user AI chats + messages. Everything is private to the owner (RLS).

create table if not exists public.ai_conversations (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null default 'New chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_ai_conversations_user
  on public.ai_conversations (user_id, updated_at desc);

create table if not exists public.ai_messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role            text not null check (role in ('user','assistant','system')),
  message         text not null,
  created_at      timestamptz not null default now()
);
create index if not exists idx_ai_messages_conv
  on public.ai_messages (conversation_id, created_at);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;

-- conversations: owner only
drop policy if exists ai_conv_all on public.ai_conversations;
create policy ai_conv_all on public.ai_conversations
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- messages: owner (via the parent conversation) only
drop policy if exists ai_msg_select on public.ai_messages;
create policy ai_msg_select on public.ai_messages
  for select to authenticated
  using (exists (select 1 from public.ai_conversations c
                 where c.id = conversation_id and c.user_id = auth.uid()));
drop policy if exists ai_msg_insert on public.ai_messages;
create policy ai_msg_insert on public.ai_messages
  for insert to authenticated
  with check (exists (select 1 from public.ai_conversations c
                      where c.id = conversation_id and c.user_id = auth.uid()));
drop policy if exists ai_msg_delete on public.ai_messages;
create policy ai_msg_delete on public.ai_messages
  for delete to authenticated
  using (exists (select 1 from public.ai_conversations c
                 where c.id = conversation_id and c.user_id = auth.uid()));

-- bump the conversation's updated_at whenever a message lands
create or replace function public.tg_ai_touch_conversation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.ai_conversations set updated_at = now() where id = new.conversation_id;
  return new;
end; $$;
drop trigger if exists trg_ai_touch_conversation on public.ai_messages;
create trigger trg_ai_touch_conversation after insert on public.ai_messages
  for each row execute function public.tg_ai_touch_conversation();
