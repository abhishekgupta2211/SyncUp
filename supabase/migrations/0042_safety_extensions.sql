-- Rider App Transformation — 0042 Safety Extensions
-- Adds medical and emergency contact info to profiles.

alter table public.profiles
add column if not exists blood_group text,
add column if not exists allergies text,
add column if not exists emergency_contact_name text,
add column if not exists emergency_contact_phone text;
