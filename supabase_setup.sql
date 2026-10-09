-- SchoolBridge: PRIVATE file storage for homework attachments (PDF / JPG / PNG).
--
-- Run this once in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- It is safe to run again, and it also locks down an earlier public setup.
--
-- How access works now
--   * The bucket is PRIVATE and has NO storage policies, so the app's public
--     (anon) key can neither read, upload, list nor delete anything.
--   * Every upload, view and delete goes through the Edge Function
--     "homework-files" (supabase/functions/homework-files). It verifies the
--     caller's Firebase login, checks their role and ownership against
--     Firestore, and only then returns a short-lived signed link.
--   * The function uses the project's service-role key, which exists only on
--     Supabase's servers. It is never placed in the Flutter app.

-- 1) The bucket: private, 10 MB per file, PDF / JPEG / PNG only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'homework-files',
  'homework-files',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- 2) Remove the open policies from the earlier version, if they exist.
drop policy if exists "homework files: upload" on storage.objects;
drop policy if exists "homework files: delete" on storage.objects;

-- 3) Check: the next query should return the bucket with public = false, and
--    the one after it should return NO rows mentioning 'homework-files'.
--
--   select id, public, file_size_limit, allowed_mime_types
--     from storage.buckets where id = 'homework-files';
--
--   select policyname, cmd, roles
--     from pg_policies
--    where schemaname = 'storage' and tablename = 'objects'
--      and (qual ilike '%homework-files%' or with_check ilike '%homework-files%');