-- LoveChat — 0002 RLS (recursion-safe helper + policies + column-rules trigger)

-- ---- Membership helper (SECURITY DEFINER breaks the classic RLS recursion) ----
create or replace function public.is_conversation_participant(
  p_conversation_id uuid,
  p_user_id uuid
) returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.conversation_participants
    where conversation_id = p_conversation_id
      and user_id = p_user_id
  );
$$;
revoke all on function public.is_conversation_participant(uuid, uuid) from public;
grant execute on function public.is_conversation_participant(uuid, uuid) to authenticated;

-- ---- Enable RLS ----
alter table public.profiles                  enable row level security;
alter table public.conversations             enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages                  enable row level security;
alter table public.message_reactions         enable row level security;
alter table public.call_logs                 enable row level security;

-- ===================== profiles =====================
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert to authenticated with check (id = auth.uid());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ============== conversation_participants ==============
drop policy if exists cp_select on public.conversation_participants;
create policy cp_select on public.conversation_participants
  for select to authenticated
  using (public.is_conversation_participant(conversation_id, auth.uid()));

drop policy if exists cp_insert on public.conversation_participants;
create policy cp_insert on public.conversation_participants
  for insert to authenticated
  with check (user_id = auth.uid()
              or public.is_conversation_participant(conversation_id, auth.uid()));

drop policy if exists cp_update on public.conversation_participants;
create policy cp_update on public.conversation_participants
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===================== conversations =====================
drop policy if exists conv_select on public.conversations;
create policy conv_select on public.conversations
  for select to authenticated
  using (public.is_conversation_participant(id, auth.uid()));

drop policy if exists conv_insert on public.conversations;
create policy conv_insert on public.conversations
  for insert to authenticated with check (created_by = auth.uid());

-- ===================== messages =====================
drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select to authenticated
  using (
    public.is_conversation_participant(conversation_id, auth.uid())
    and not deleted_for_everyone
    and not (auth.uid() = any(deleted_for_me))
  );

drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_participant(conversation_id, auth.uid())
  );

-- recipient marks seen/delivered
drop policy if exists msg_update_receipt on public.messages;
create policy msg_update_receipt on public.messages
  for update to authenticated
  using (receiver_id = auth.uid()) with check (receiver_id = auth.uid());

-- sender edits / deletes-for-everyone own message
drop policy if exists msg_update_owner on public.messages;
create policy msg_update_owner on public.messages
  for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());

-- column-level guard: recipient may only touch receipt/hide fields;
-- only the sender may flip deleted_for_everyone.
create or replace function public.enforce_message_update_rules()
returns trigger language plpgsql as $$
begin
  if auth.uid() = new.receiver_id and auth.uid() <> new.sender_id then
    if new.message is distinct from old.message
       or new.deleted_for_everyone is distinct from old.deleted_for_everyone
       or new.media_url is distinct from old.media_url then
      raise exception 'recipient may only update receipt/hide fields';
    end if;
  end if;

  if new.deleted_for_everyone and not old.deleted_for_everyone
     and auth.uid() <> old.sender_id then
    raise exception 'only sender can delete for everyone';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_message_update_rules on public.messages;
create trigger trg_message_update_rules
  before update on public.messages
  for each row execute function public.enforce_message_update_rules();

-- ===================== message_reactions =====================
drop policy if exists react_select on public.message_reactions;
create policy react_select on public.message_reactions
  for select to authenticated
  using (exists (
    select 1 from public.messages m
    where m.id = message_id
      and public.is_conversation_participant(m.conversation_id, auth.uid())
  ));

drop policy if exists react_insert on public.message_reactions;
create policy react_insert on public.message_reactions
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.messages m
      where m.id = message_id
        and public.is_conversation_participant(m.conversation_id, auth.uid())
    )
  );

drop policy if exists react_update on public.message_reactions;
create policy react_update on public.message_reactions
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists react_delete on public.message_reactions;
create policy react_delete on public.message_reactions
  for delete to authenticated using (user_id = auth.uid());

-- ===================== call_logs =====================
drop policy if exists call_select on public.call_logs;
create policy call_select on public.call_logs
  for select to authenticated
  using (caller_id = auth.uid() or callee_id = auth.uid());

drop policy if exists call_insert on public.call_logs;
create policy call_insert on public.call_logs
  for insert to authenticated
  with check (caller_id = auth.uid() or callee_id = auth.uid());
