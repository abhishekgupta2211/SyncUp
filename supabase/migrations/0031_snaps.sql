-- LoveChat — 0031 SyncSnaps
-- Support for one-time viewable media.

alter table public.messages
add column if not exists is_snap boolean default false,
add column if not exists snap_opened_at timestamptz;

-- Update message types to include 'snap'
-- (Existing enum might need update if handled strictly, but we'll use is_snap flag)
