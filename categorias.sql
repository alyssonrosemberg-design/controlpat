-- =====================================================================
-- CATEGORIAS DE BENS (Opcional no Supabase)
-- Rode no Supabase: SQL Editor > New query > Run
-- O app funciona com armazenamento local/bens, e sincroniza com esta tabela quando ela existir.
-- =====================================================================
create table if not exists categorias (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique,
  criado_em timestamptz default now()
);

alter table categorias enable row level security;
drop policy if exists cat_sel on categorias; create policy cat_sel on categorias for select to authenticated using (is_ativo());
drop policy if exists cat_adm on categorias; create policy cat_adm on categorias for all to authenticated using (is_admin()) with check (is_admin());
grant select, insert, update, delete on categorias to authenticated;

-- Categorias padrão iniciais
insert into categorias (nome) values
  ('Mobiliário'),
  ('Informática'),
  ('Equipamento'),
  ('Veículo'),
  ('Eletrodoméstico')
on conflict (nome) do nothing;
