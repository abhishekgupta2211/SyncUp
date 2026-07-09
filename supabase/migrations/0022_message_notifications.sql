-- LoveChat — 0022 message notifications
-- Adds a trigger to create a notification row whenever a new message is sent.
-- This row then triggers the `push` Edge Function to send an FCM push.

create or replace function public.tg_notify_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  sender_name text;
  preview_text text;
begin
  -- Get the sender's name for the notification title
  select display_name into sender_name from public.profiles where id = new.sender_id;

  -- Prepare the preview text based on message type
  preview_text := case
    when new.message_type = 'text' then new.message
    when new.message_type = 'image' then '📷 Photo'
    when new.message_type = 'video' then '🎥 Video'
    when new.message_type = 'voice' then '🎤 Voice message'
    when new.message_type = 'location' then '📍 Location'
    else 'Sent a message'
  end;

  -- Create the notification
  perform public.notify(
    new.receiver_id,
    new.sender_id,
    'message',
    coalesce(sender_name, 'New Message'),
    preview_text,
    jsonb_build_object('conversation_id', new.conversation_id)
  );

  return new;
end; $$;

drop trigger if exists trg_notify_message on public.messages;
create trigger trg_notify_message
  after insert on public.messages
  for each row execute function public.tg_notify_message();
