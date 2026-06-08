-- Storage buckets + policies (SPEC §5).
-- print-files & signatures are PRIVATE; the rest are public.

insert into storage.buckets (id, name, public) values
  ('print-files',       'print-files',       false),
  ('print-previews',    'print-previews',    true),
  ('mockups',           'mockups',           true),
  ('product-templates', 'product-templates', true),
  ('signatures',        'signatures',        false)
on conflict (id) do nothing;

-- Public read for the three public buckets.
create policy "public read public buckets"
  on storage.objects for select
  using (bucket_id in ('print-previews', 'mockups', 'product-templates'));

-- Designers upload their own hi-res print files and watermarked previews.
-- print-files has NO public read — only the generate-signed-url function (service
-- role) ever hands these out, to production/admin (SPEC §13).
create policy "owner upload print files"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('print-files', 'print-previews') and owner = auth.uid());

create policy "owner manage own print files"
  on storage.objects for update to authenticated
  using (bucket_id in ('print-files', 'print-previews') and owner = auth.uid());

-- Signatures: private; the signer may upload and read their own.
create policy "owner upload signature"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'signatures' and owner = auth.uid());

create policy "owner read signature"
  on storage.objects for select to authenticated
  using (bucket_id = 'signatures' and owner = auth.uid());

-- NOTE: mockups & product-templates are written by server jobs (service role),
-- which bypasses RLS — no client insert policy needed.
