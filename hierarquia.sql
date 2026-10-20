-- =====================================================================
-- HIERARQUIA ORGANIZACIONAL (3 NÍVEIS):
-- Local (Nível 1) ➔ Gerência (Nível 2) ➔ Equipamento / Setor (Nível 3)
-- Rode no Supabase: SQL Editor > New query > Run
-- =====================================================================

-- 1. Tabela de Gerências (Nível 2) pertencentes a um Local (Nível 1)
create table if not exists gerencias (
  id uuid primary key default gen_random_uuid(),
  local_id uuid not null references locais(id) on delete cascade,
  nome text not null,
  sigla text,
  responsavel text,
  criado_em timestamptz default now()
);

-- 2. Tabela de Equipamentos / Setores (Nível 3) pertencentes a uma Gerência (Nível 2)
-- Representa a unidade funcional, setor, sala ou equipamento público
create table if not exists equipamentos (
  id uuid primary key default gen_random_uuid(),
  gerencia_id uuid not null references gerencias(id) on delete cascade,
  nome text not null,
  tipo text default 'Setor',                -- Setor | Sala | Unidade funcional | Depósito | Posto
  descricao text,
  criado_em timestamptz default now()
);

-- 3. Vincular Bens diretamente ao Equipamento (Nível 3)
alter table bens add column if not exists equipamento_id uuid references equipamentos(id) on delete set null;

-- 4. Suporte a Equipamentos nas Movimentações
alter table movimentacoes add column if not exists de_equipamento_id uuid references equipamentos(id) on delete set null;
alter table movimentacoes add column if not exists para_equipamento_id uuid references equipamentos(id) on delete set null;

-- 5. Suporte a Equipamentos e Gerências nas Conferências
alter table conferencias add column if not exists gerencia_id uuid references gerencias(id) on delete set null;
alter table conferencias add column if not exists equipamento_id uuid references equipamentos(id) on delete set null;
alter table conferencia_itens add column if not exists equipamento_encontrado_id uuid references equipamentos(id) on delete set null;

-- 6. MIGRAÇÃO DE DADOS EXISTENTES (Garante que nenhum bem existente fique órfão)
-- Para cada Local já existente sem Gerência, cria uma Gerência inicial padrão
insert into gerencias (local_id, nome, sigla)
select id, coalesce(nullif(setor, ''), 'Gerência Geral'), 'GER'
from locais l
where not exists (select 1 from gerencias g where g.local_id = l.id);

-- Para cada Gerência sem Equipamento, cria um Equipamento / Setor inicial padrão
insert into equipamentos (gerencia_id, nome, tipo)
select g.id, 'Setor Principal', 'Setor'
from gerencias g
where not exists (select 1 from equipamentos e where e.gerencia_id = g.id);

-- Para bens que já possuem local_id mas estão sem equipamento_id, aloca no equipamento padrão do local
update bens b
   set equipamento_id = (
     select e.id 
       from equipamentos e
       join gerencias g on g.id = e.gerencia_id
      where g.local_id = b.local_id
      order by e.criado_em asc limit 1
   )
 where b.equipamento_id is null and b.local_id is not null;

-- 7. Trigger para manter bens.local_id sempre sincronizado com o local do equipamento
create or replace function sync_bem_local() returns trigger as $$
begin
  if NEW.equipamento_id is not null then
    select g.local_id into NEW.local_id
      from equipamentos e
      join gerencias g on g.id = e.gerencia_id
     where e.id = NEW.equipamento_id;
  end if;
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_sync_bem_local on bens;
create trigger trg_sync_bem_local
before insert or update of equipamento_id on bens
for each row execute function sync_bem_local();

-- 8. Atualizar RPC conferir_bem para suportar conferência por Equipamento ou Local
drop function if exists conferir_bem(uuid, uuid, boolean, uuid);
drop function if exists conferir_bem(uuid, uuid, boolean, uuid, uuid);
create or replace function conferir_bem(
  p_bem uuid, 
  p_local uuid default null, 
  p_mover boolean default false, 
  p_conf uuid default null,
  p_equipamento uuid default null
)
returns void language plpgsql security definer set search_path = public as $$
declare 
  v_old_loc uuid; v_old_eq uuid;
  v_new_loc uuid; v_new_eq uuid;
  v_res text; v_email text;
begin
  if not is_ativo() then raise exception 'Sem acesso'; end if;
  select local_id, equipamento_id into v_old_loc, v_old_eq from bens where id = p_bem;
  if not found then raise exception 'Bem não encontrado'; end if;

  -- Se foi passado um equipamento específico
  if p_equipamento is not null then
    select g.local_id into v_new_loc
      from equipamentos e join gerencias g on g.id = e.gerencia_id
     where e.id = p_equipamento;
    v_new_eq := case when p_mover then p_equipamento else v_old_eq end;
    if p_mover then 
      v_new_loc := coalesce(v_new_loc, p_local); 
    else 
      v_new_loc := v_old_loc; 
    end if;
  else
    v_new_loc := case when p_mover then p_local else v_old_loc end;
    v_new_eq := v_old_eq;
  end if;

  v_res := case 
    when p_mover then 'Movido'
    when p_equipamento is not null and v_old_eq is distinct from p_equipamento then 'Local divergente'
    when p_local is not null and v_old_loc is distinct from p_local then 'Local divergente'
    else 'Presente' end;

  update bens 
     set local_id = coalesce(v_new_loc, local_id),
         equipamento_id = coalesce(v_new_eq, equipamento_id),
         verificado_em = now(),
         status = case when status = 'Não localizado' then 'Ativo' else status end
   where id = p_bem;

  if p_mover then
    insert into movimentacoes(bem_id, tipo, de_local_id, para_local_id, de_equipamento_id, para_equipamento_id) 
    values (p_bem, 'Transferência (inventário)', v_old_loc, v_new_loc, v_old_eq, v_new_eq);
  end if;

  insert into movimentacoes(bem_id, tipo, de_local_id, para_local_id, de_equipamento_id, para_equipamento_id) 
  values (p_bem, 'Conferência', v_new_loc, v_new_loc, v_new_eq, v_new_eq);

  if p_conf is null then
    select email into v_email from perfis where id = auth.uid();
    insert into conferencias(local_id, equipamento_id, tipo, usuario_email, finalizada_em, total_esperado)
    values (v_new_loc, v_new_eq, 'Avulsa', v_email, now(), 1) returning id into p_conf;
  end if;

  insert into conferencia_itens(conferencia_id, bem_id, resultado, local_encontrado_id, equipamento_encontrado_id)
  values (p_conf, p_bem, v_res, coalesce(p_local, v_old_loc), coalesce(p_equipamento, v_old_eq))
  on conflict (conferencia_id, bem_id) do update set resultado = excluded.resultado, data = now();
end $$;

-- 9. Políticas de Segurança (RLS)
alter table gerencias enable row level security;
alter table equipamentos enable row level security;

drop policy if exists ger_sel on gerencias;    create policy ger_sel on gerencias for select to authenticated using (is_ativo());
drop policy if exists ger_adm on gerencias;    create policy ger_adm on gerencias for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists eq_sel on equipamentos;  create policy eq_sel on equipamentos for select to authenticated using (is_ativo());
drop policy if exists eq_adm on equipamentos;  create policy eq_adm on equipamentos for all to authenticated using (is_admin()) with check (is_admin());

grant select, insert, update, delete on gerencias, equipamentos to authenticated;
grant execute on function conferir_bem(uuid, uuid, boolean, uuid, uuid) to authenticated;
notify pgrst, 'reload schema';
