-- =====================================================================
-- CONFERÊNCIA DE BENS — rode no Supabase: SQL Editor > New query > Run
-- Cria o registro de conferências (avulsas e inventários) e recria as funções.
-- =====================================================================
create table if not exists conferencias (
  id uuid primary key default gen_random_uuid(),
  local_id uuid references locais(id) on delete set null,
  tipo text default 'Inventário',            -- Inventário | Avulsa
  usuario_id uuid default auth.uid(),
  usuario_email text,
  iniciada_em timestamptz default now(),
  finalizada_em timestamptz,
  total_esperado int default 0
);
create table if not exists conferencia_itens (
  id uuid primary key default gen_random_uuid(),
  conferencia_id uuid not null references conferencias(id) on delete cascade,
  bem_id uuid not null references bens(id) on delete cascade,
  resultado text,                            -- Presente | Local divergente | Movido | Faltante
  local_encontrado_id uuid,
  data timestamptz default now(),
  unique (conferencia_id, bem_id)
);

alter table conferencias enable row level security;
alter table conferencia_itens enable row level security;
drop policy if exists conf_sel on conferencias;      create policy conf_sel on conferencias for select to authenticated using (is_ativo());
drop policy if exists conf_adm on conferencias;      create policy conf_adm on conferencias for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists confi_sel on conferencia_itens; create policy confi_sel on conferencia_itens for select to authenticated using (is_ativo());
drop policy if exists confi_adm on conferencia_itens; create policy confi_adm on conferencia_itens for all to authenticated using (is_admin()) with check (is_admin());
grant select, insert, update, delete on conferencias, conferencia_itens to authenticated;

-- Inicia um inventário em um local
create or replace function iniciar_conferencia(p_local uuid, p_tipo text default 'Inventário') returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  if not is_ativo() then raise exception 'Sem acesso'; end if;
  insert into conferencias(local_id, tipo, usuario_email, total_esperado)
  values (p_local, p_tipo, (select email from perfis where id = auth.uid()),
          (select count(*) from bens where local_id = p_local and status <> 'Baixado'))
  returning id into v;
  return v;
end $$;

-- Confere um bem (cria sozinho uma conferência "Avulsa" se não houver inventário em andamento)
drop function if exists conferir_bem(uuid, uuid, boolean);
drop function if exists conferir_bem(uuid, uuid, boolean, uuid);
create or replace function conferir_bem(p_bem uuid, p_local uuid default null, p_mover boolean default false, p_conf uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_old uuid; v_new uuid; v_res text; v_email text;
begin
  if not is_ativo() then raise exception 'Sem acesso'; end if;
  select local_id into v_old from bens where id = p_bem;
  if not found then raise exception 'Bem não encontrado'; end if;
  v_new := case when p_mover then p_local else v_old end;
  v_res := case when p_mover then 'Movido'
                when p_local is not null and v_old is distinct from p_local then 'Local divergente'
                else 'Presente' end;
  update bens set local_id = v_new, verificado_em = now(),
         status = case when status = 'Não localizado' then 'Ativo' else status end
   where id = p_bem;
  if p_mover then
    insert into movimentacoes(bem_id,tipo,de_local_id,para_local_id) values (p_bem,'Transferência (inventário)',v_old,v_new);
  end if;
  insert into movimentacoes(bem_id,tipo,de_local_id,para_local_id) values (p_bem,'Conferência',v_new,v_new);
  if p_conf is null then
    select email into v_email from perfis where id = auth.uid();
    insert into conferencias(local_id,tipo,usuario_email,finalizada_em,total_esperado)
    values (v_new,'Avulsa',v_email,now(),1) returning id into p_conf;
  end if;
  insert into conferencia_itens(conferencia_id,bem_id,resultado,local_encontrado_id)
  values (p_conf,p_bem,v_res,coalesce(p_local,v_old))
  on conflict (conferencia_id,bem_id) do update set resultado = excluded.resultado, data = now();
end $$;

-- Finaliza o inventário: registra os faltantes (e opcionalmente marca "Não localizado")
create or replace function finalizar_conferencia(p_conf uuid, p_marcar boolean default false) returns void
language plpgsql security definer set search_path = public as $$
declare v_local uuid;
begin
  if not is_ativo() then raise exception 'Sem acesso'; end if;
  select local_id into v_local from conferencias where id = p_conf;
  insert into conferencia_itens(conferencia_id,bem_id,resultado)
    select p_conf, b.id, 'Faltante' from bens b
     where b.local_id = v_local and b.status <> 'Baixado'
       and not exists (select 1 from conferencia_itens i where i.conferencia_id = p_conf and i.bem_id = b.id);
  if p_marcar then
    insert into movimentacoes(bem_id,tipo,de_local_id,para_local_id)
      select i.bem_id,'Não localizado',v_local,v_local from conferencia_itens i join bens b on b.id = i.bem_id
       where i.conferencia_id = p_conf and i.resultado = 'Faltante' and b.status <> 'Não localizado';
    update bens set status = 'Não localizado'
     where id in (select bem_id from conferencia_itens where conferencia_id = p_conf and resultado = 'Faltante') and status <> 'Baixado';
  end if;
  update conferencias set finalizada_em = now() where id = p_conf;
end $$;

grant execute on function iniciar_conferencia(uuid,text), conferir_bem(uuid,uuid,boolean,uuid), finalizar_conferencia(uuid,boolean), marcar_nao_localizado(uuid) to authenticated;
notify pgrst, 'reload schema';
