create table if not exists public.quality_document_public_links (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  document_id uuid not null references public.quality_documents(id) on delete cascade,
  token uuid not null unique default gen_random_uuid(),
  expires_at timestamptz not null,
  max_uses integer,
  access_count integer not null default 0,
  revoked_at timestamptz,
  revoked_by uuid,
  created_by uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quality_document_public_links_token_idx
  on public.quality_document_public_links(token);
create index if not exists quality_document_public_links_document_idx
  on public.quality_document_public_links(document_id);
create index if not exists quality_document_public_links_expires_idx
  on public.quality_document_public_links(expires_at);

grant select, insert, update, delete on public.quality_document_public_links to authenticated;
grant all on public.quality_document_public_links to service_role;

alter table public.quality_document_public_links enable row level security;

create policy "qms_master_public_links_all"
  on public.quality_document_public_links
  for all
  to authenticated
  using (
    company_id = public.user_company_id(auth.uid())
    and (public.has_role(auth.uid(), 'qualidade') or public.has_role(auth.uid(), 'super_admin'))
  )
  with check (
    company_id = public.user_company_id(auth.uid())
    and (public.has_role(auth.uid(), 'qualidade') or public.has_role(auth.uid(), 'super_admin'))
  );

create trigger set_quality_document_public_links_updated_at
  before update on public.quality_document_public_links
  for each row execute function public.quality_touch_updated_at();