-- LoveChat — 0001 schema (tables, enums, indexes)
-- Run order: 0001 → 0002 → 0003 → 0004

-- ---- Extensions ----
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- trigram user search

-- =========================================================
-- profiles (1:1 with auth.users)
-- =========================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text not null,
  phone         text unique,
  email         text,
  avatar_url    text,
  status_line   text not null default 'Hey there! I am using LoveChat 💗',
  last_seen     timestamptz,
  is_online     boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint username_len check (char_length(username) between 3 and 30)
);

create index if not exists idx_profiles_username_trgm
  on public.profiles using gin (lower(username) gin_trgm_ops);
create index if not exists idx_profiles_display_trgm
  on public.profiles using gin (lower(display_name) gin_trgm_ops);
create index if not exists idx_profiles_phone_trgm
  on public.profiles using gin (phone gin_trgm_ops);

-- =========================================================
-- conversations
-- =========================================================
create table if not exists public.conversations (
  id                 uuid primary key default gen_random_uuid(),
  is_group           boolean not null default false,
  dm_key             text unique,            -- canonical 1:1 pair key; null for groups
  last_message_id    uuid,                   -- FK wired after messages exists
  last_message_text  text,
  last_message_type  text,
  last_message_at    timestamptz,
  created_by         uuid references public.profiles(id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists idx_conversations_last_message_at
  on public.conversations (last_message_at desc nulls last);

-- =========================================================
-- conversation_participants
-- =========================================================
create table if not exists public.conversation_participants (
  conversation_id  uuid not null references public.conversations(id) on delete cascade,
  user_id          uuid not null references public.profiles(id) on delete cascade,
  unread_count     integer not null default 0,
  last_read_at     timestamptz,
  muted            boolean not null default false,
  joined_at        timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index if not exists idx_participants_user on public.conversation_participants (user_id);
create index if not exists idx_participants_conv on public.conversation_participants (conversation_id);

-- =========================================================
-- messages
-- =========================================================
do $$ begin
  create type message_type_enum as enum
    ('text','emoji','image','video','voice','document','location','gif','sticker');
exception when duplicate_object then null; end $$;

create table if not exists public.messages (
  id                   uuid primary key default gen_random_uuid(),
  conversation_id      uuid not null references public.conversations(id) on delete cascade,
  sender_id            uuid not null references public.profiles(id),
  receiver_id          uuid not null references public.profiles(id),
  message_type         message_type_enum not null default 'text',
  message              text,
  media_url            text,
  media_meta           jsonb,
  reply_message_id     uuid references public.messages(id) on delete set null,
  delivered            boolean not null default false,
  seen                 boolean not null default false,
  seen_at              timestamptz,
  edited_at            timestamptz,
  deleted_for_everyone boolean not null default false,
  deleted_for_me       uuid[] not null default '{}',
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- keyset pagination (newest-first within a conversation)
create index if not exists idx_messages_conv_created
  on public.messages (conversation_id, created_at desc, id desc);

-- fast "unseen messages addressed to me" scans
create index if not exists idx_messages_unseen
  on public.messages (conversation_id, receiver_id)
  where seen = false and deleted_for_everyone = false;

-- wire conversations.last_message_id now that messages exists
do $$ begin
  alter table public.conversations
    add constraint conversations_last_message_fk
    foreign key (last_message_id) references public.messages(id) on delete set null;
exception when duplicate_object then null; end $$;

-- =========================================================
-- message_reactions (one per user per message)
-- =========================================================
create table if not exists public.message_reactions (
  message_id  uuid not null references public.messages(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  emoji       text not null,
  created_at  timestamptz not null default now(),
  primary key (message_id, user_id)
);
create index if not exists idx_reactions_message on public.message_reactions (message_id);

-- =========================================================
-- call_logs (Tier 3 — schema ready now)
-- =========================================================
do $$ begin
  create type call_type_enum as enum ('voice','video');
exception when duplicate_object then null; end $$;
do $$ begin
  create type call_direction_enum as enum ('outgoing','incoming','missed');
exception when duplicate_object then null; end $$;

create table if not exists public.call_logs (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid references public.conversations(id) on delete set null,
  caller_id        uuid not null references public.profiles(id),
  callee_id        uuid not null references public.profiles(id),
  type             call_type_enum not null,
  direction        call_direction_enum not null,
  started_at       timestamptz not null default now(),
  duration_sec     integer not null default 0
);
create index if not exists idx_call_logs_participants
  on public.call_logs (caller_id, callee_id, started_at desc);
