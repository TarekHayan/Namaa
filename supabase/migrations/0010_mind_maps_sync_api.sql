-- One owner-derived mutation boundary for the four independently versioned records.
begin;

create or replace function public.apply_mind_map_change(
  p_entity_type text, p_map_id uuid, p_entity_id text, p_payload jsonb,
  p_operation_id text, p_updated_at timestamptz, p_kind text
) returns table (
  owner uuid, entity_type text, entity_id text, payload jsonb,
  operation_id text, updated_at timestamptz, deleted_at timestamptz,
  conflict_detected boolean, conflict_unresolved boolean,
  retained_payload jsonb, retained_updated_at timestamptz,
  rejection_reason text, replayed boolean
)
language plpgsql security definer set search_path = '' as $$
declare
  v_owner uuid := auth.uid();
  v_receipt public.mind_map_operation_receipts%rowtype;
  v_map public.mind_maps%rowtype;
  v_node public.mind_map_nodes%rowtype;
  v_slot public.mind_map_parent_slots%rowtype;
  v_side public.mind_map_side_links%rowtype;
  v_node_id uuid;
  v_child_id uuid;
  v_parent_id uuid;
  v_first uuid;
  v_second uuid;
  v_task_id uuid;
  v_old_payload jsonb;
  v_old_at timestamptz;
  v_old_deleted timestamptz;
  v_result jsonb;
  v_result_at timestamptz;
  v_result_deleted timestamptz;
  v_retained jsonb;
  v_retained_at timestamptz;
  v_conflict boolean := false;
  v_unresolved boolean := false;
  v_rejection text;
  v_apply boolean := false;
  v_pair_at timestamptz;
  v_pair_payload jsonb;
begin
  if v_owner is null then
    raise exception using errcode = '42501', message = 'Not authenticated';
  end if;
  if p_entity_type not in ('mind_map', 'mind_map_node',
      'mind_map_parent_slot', 'mind_map_side_link') or
     p_map_id is null or p_entity_id is null or p_operation_id is null or
     pg_catalog.btrim(p_operation_id) = '' or p_updated_at is null or
     p_kind not in ('create', 'update', 'delete') or
     p_payload is null or pg_catalog.jsonb_typeof(p_payload) <> 'object' or
     p_payload->>'ownerId' is distinct from v_owner::text or
     (p_payload->>'updatedAt')::timestamptz is distinct from p_updated_at or
     (p_kind = 'delete') is distinct from (p_payload->>'deletedAt' is not null) or
     (p_kind = 'delete' and
       (p_payload->>'deletedAt')::timestamptz is distinct from p_updated_at) or
     pg_catalog.btrim(coalesce(p_payload->>'revisionId', '')) = '' then
    raise exception using errcode = '22023', message = 'Invalid map operation';
  end if;

  if p_entity_type = 'mind_map' then
    if p_entity_id <> p_map_id::text or
       p_payload->>'id' is distinct from p_map_id::text or
       pg_catalog.btrim(coalesce(p_payload->>'title', '')) = '' or
       p_payload->>'centralNodeId' is null or
       pg_catalog.jsonb_typeof(p_payload->'settings') <> 'object' then
      raise exception using errcode = '22023', message = 'Invalid map payload';
    end if;
  elsif p_entity_type = 'mind_map_node' then
    if p_payload->>'mapId' is distinct from p_map_id::text or
       p_payload->>'id' is null or
       p_entity_id <> p_map_id::text || ':' || (p_payload->>'id') or
       pg_catalog.btrim(coalesce(p_payload->>'title', '')) = '' or
       p_payload->>'kind' not in ('central','mainIdea','branch','task','note') or
       pg_catalog.jsonb_typeof(p_payload->'appearance') <> 'object' then
      raise exception using errcode = '22023', message = 'Invalid map node payload';
    end if;
    v_node_id := (p_payload->>'id')::uuid;
  elsif p_entity_type = 'mind_map_parent_slot' then
    if p_payload->>'mapId' is distinct from p_map_id::text or
       p_payload->>'childNodeId' is null or
       p_payload->>'parentNodeId' is null or
       p_entity_id <> p_map_id::text || ':parent:' ||
         (p_payload->>'childNodeId') or
       p_payload->>'childNodeId' = p_payload->>'parentNodeId' then
      raise exception using errcode = '22023', message = 'Invalid parent slot payload';
    end if;
    v_child_id := (p_payload->>'childNodeId')::uuid;
    v_parent_id := (p_payload->>'parentNodeId')::uuid;
  else
    if p_payload->>'mapId' is distinct from p_map_id::text or
       p_payload->>'firstNodeId' is null or
       p_payload->>'secondNodeId' is null or
       p_payload->>'firstNodeId' >= p_payload->>'secondNodeId' or
       p_entity_id <> p_map_id::text || ':side:' ||
         (p_payload->>'firstNodeId') || ':' ||
         (p_payload->>'secondNodeId') then
      raise exception using errcode = '22023', message = 'Invalid side link payload';
    end if;
    v_first := (p_payload->>'firstNodeId')::uuid;
    v_second := (p_payload->>'secondNodeId')::uuid;
  end if;

  -- Stable receipts and every structural edit serialize on the owner/map.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_owner::text || ':map:' || p_map_id::text, 0));
  select * into v_receipt from public.mind_map_operation_receipts r
    where r.owner = v_owner and r.operation_id = p_operation_id;
  if found then
    if v_receipt.entity_type <> p_entity_type or
       v_receipt.entity_id <> p_entity_id or v_receipt.kind <> p_kind or
       v_receipt.request_payload <> p_payload or
       v_receipt.request_updated_at <> p_updated_at then
      raise exception using errcode = '22023', message = 'Operation identity collision';
    end if;
    return query select v_owner, p_entity_type, p_entity_id,
      v_receipt.result_payload, p_operation_id, v_receipt.result_updated_at,
      v_receipt.result_deleted_at, v_receipt.conflict_detected,
      v_receipt.conflict_unresolved, v_receipt.retained_payload,
      v_receipt.retained_updated_at, v_receipt.rejection_reason, true;
    return;
  end if;

  select * into v_map from public.mind_maps m
    where m.owner = v_owner and m.id = p_map_id for update;
  if p_entity_type <> 'mind_map' then
    if v_map.owner is null then
      raise exception using errcode = '23503', message = 'Map parent missing';
    end if;
  elsif v_map.owner is not null and
      v_map.payload->>'centralNodeId' is distinct from
        p_payload->>'centralNodeId' then
    raise exception using errcode = '22023', message = 'Central node is immutable';
  end if;

  if p_entity_type = 'mind_map' then
    v_old_payload := v_map.payload;
    v_old_at := v_map.updated_at;
    v_old_deleted := v_map.deleted_at;
  elsif p_entity_type = 'mind_map_node' then
    select * into v_node from public.mind_map_nodes n
      where n.owner = v_owner and n.map_id = p_map_id and
        n.node_id = v_node_id for update;
    v_old_payload := v_node.payload;
    v_old_at := v_node.updated_at;
    v_old_deleted := v_node.deleted_at;
    if (v_node.owner is not null and
        v_node.payload->>'kind' is distinct from p_payload->>'kind') or
       ((v_node_id::text = v_map.payload->>'centralNodeId') is distinct from
         (p_payload->>'kind' = 'central')) or
       (v_node_id::text = v_map.payload->>'centralNodeId' and p_kind = 'delete') then
      raise exception using errcode = '22023', message = 'Invalid central node identity';
    end if;
    if p_payload->>'taskId' is not null and
       p_payload->>'taskId' is distinct from v_node.payload->>'taskId' and
       p_kind <> 'delete' then
      v_task_id := (p_payload->>'taskId')::uuid;
      if not exists (select 1 from public.tasks t where t.owner = v_owner
          and t.id = v_task_id and t.deleted_at is null) then
        raise exception using errcode = '23503', message = 'Task link unavailable';
      end if;
    end if;
  elsif p_entity_type = 'mind_map_parent_slot' then
    select * into v_slot from public.mind_map_parent_slots s
      where s.owner = v_owner and s.map_id = p_map_id and
        s.child_node_id = v_child_id for update;
    v_old_payload := v_slot.payload;
    v_old_at := v_slot.updated_at;
    v_old_deleted := v_slot.deleted_at;
  else
    select * into v_side from public.mind_map_side_links s
      where s.owner = v_owner and s.map_id = p_map_id and
        s.first_node_id = v_first and s.second_node_id = v_second for update;
    v_old_payload := v_side.payload;
    v_old_at := v_side.updated_at;
    v_old_deleted := v_side.deleted_at;
  end if;

  if v_map.deleted_at is not null and p_entity_type <> 'mind_map' then
    v_rejection := 'map_deleted';
  elsif p_entity_type = 'mind_map_parent_slot' and p_kind <> 'delete' then
    if not exists (select 1 from public.mind_map_nodes n where n.owner = v_owner
        and n.map_id = p_map_id and n.node_id = v_child_id and
        n.deleted_at is null) or
       not exists (select 1 from public.mind_map_nodes n where n.owner = v_owner
        and n.map_id = p_map_id and n.node_id = v_parent_id and
        n.deleted_at is null) then
      raise exception using errcode = '23503', message = 'Parent endpoints unavailable';
    end if;
    if v_child_id::text = v_map.payload->>'centralNodeId' then
      raise exception using errcode = '22023', message = 'Central node has no parent';
    end if;
    if exists (
      with recursive ancestors(id, path) as (
        select v_parent_id, array[v_parent_id]
        union all
        select s.parent_node_id, a.path || s.parent_node_id
        from ancestors a join public.mind_map_parent_slots s
          on s.owner = v_owner and s.map_id = p_map_id and
             s.child_node_id = a.id and s.deleted_at is null
        where not s.parent_node_id = any(a.path)
      ) select 1 from ancestors where id = v_child_id
    ) then
      v_rejection := 'cycle';
    end if;
    select s.updated_at, s.payload into v_pair_at, v_pair_payload
      from public.mind_map_side_links s where s.owner = v_owner and
        s.map_id = p_map_id and s.deleted_at is null and
        s.first_node_id = least(v_child_id,v_parent_id) and
        s.second_node_id = greatest(v_child_id,v_parent_id);
  elsif p_entity_type = 'mind_map_side_link' and p_kind <> 'delete' then
    if not exists (select 1 from public.mind_map_nodes n where n.owner = v_owner
        and n.map_id = p_map_id and n.node_id = v_first and n.deleted_at is null) or
       not exists (select 1 from public.mind_map_nodes n where n.owner = v_owner
        and n.map_id = p_map_id and n.node_id = v_second and n.deleted_at is null) then
      raise exception using errcode = '23503', message = 'Side endpoints unavailable';
    end if;
    select s.updated_at, s.payload into v_pair_at, v_pair_payload
      from public.mind_map_parent_slots s where s.owner = v_owner and
        s.map_id = p_map_id and s.deleted_at is null and
        least(s.child_node_id,s.parent_node_id) = v_first and
        greatest(s.child_node_id,s.parent_node_id) = v_second;
  end if;

  if v_rejection is null and v_pair_at is not null and p_kind <> 'delete' then
    if p_updated_at <= v_pair_at then
      v_rejection := 'duplicate_pair';
    else
      -- The newer role wins; the replaced role becomes a tombstone and
      -- its original version remains in the visible conflict ledger.
      if p_entity_type = 'mind_map_parent_slot' then
        update public.mind_map_side_links s set
          deleted_at = p_updated_at, updated_at = p_updated_at,
          payload = pg_catalog.jsonb_set(
            pg_catalog.jsonb_set(s.payload, '{updatedAt}',
              pg_catalog.to_jsonb(p_updated_at::text)), '{deletedAt}',
              pg_catalog.to_jsonb(p_updated_at::text))
          where s.owner = v_owner and s.map_id = p_map_id and
            s.first_node_id = least(v_child_id,v_parent_id) and
            s.second_node_id = greatest(v_child_id,v_parent_id);
      else
        update public.mind_map_parent_slots s set
          deleted_at = p_updated_at, updated_at = p_updated_at,
          payload = pg_catalog.jsonb_set(
            pg_catalog.jsonb_set(s.payload, '{updatedAt}',
              pg_catalog.to_jsonb(p_updated_at::text)), '{deletedAt}',
              pg_catalog.to_jsonb(p_updated_at::text))
          where s.owner = v_owner and s.map_id = p_map_id and
            least(s.child_node_id,s.parent_node_id) = v_first and
            greatest(s.child_node_id,s.parent_node_id) = v_second;
      end if;
      insert into public.mind_map_conflicts(owner, conflict_id, map_id,
        entity_type, entity_id, active_payload, active_updated_at,
        retained_payload, retained_updated_at, reason)
      values(v_owner, p_operation_id || ':pair', p_map_id, p_entity_type,
        p_entity_id, p_payload, p_updated_at, v_pair_payload, v_pair_at,
        'duplicate_pair') on conflict do nothing;
    end if;
  end if;

  if v_rejection is not null then
    v_conflict := true;
    v_unresolved := true;
    v_result := case when v_rejection = 'duplicate_pair' then
      v_pair_payload else coalesce(v_old_payload, p_payload) end;
    v_result_at := case when v_rejection = 'duplicate_pair' then
      v_pair_at else coalesce(v_old_at, p_updated_at) end;
    v_result_deleted := v_old_deleted;
    v_retained := p_payload;
    v_retained_at := p_updated_at;
  elsif v_old_payload is null then
    v_apply := true;
    v_result := p_payload;
    v_result_at := p_updated_at;
    v_result_deleted := case when p_kind = 'delete' then p_updated_at end;
  elsif v_old_payload = p_payload then
    v_result := v_old_payload;
    v_result_at := v_old_at;
    v_result_deleted := v_old_deleted;
  else
    v_conflict := true;
    v_unresolved := p_updated_at = v_old_at;
    v_apply := p_updated_at > v_old_at;
    v_result := case when v_apply then p_payload else v_old_payload end;
    v_result_at := case when v_apply then p_updated_at else v_old_at end;
    v_result_deleted := case when v_apply then
      case when p_kind = 'delete' then p_updated_at end else v_old_deleted end;
    v_retained := case when v_apply then v_old_payload else p_payload end;
    v_retained_at := case when v_apply then v_old_at else p_updated_at end;
  end if;

  if v_apply then
    if p_entity_type = 'mind_map' then
      insert into public.mind_maps(owner,id,payload,updated_at,deleted_at)
        values(v_owner,p_map_id,p_payload,p_updated_at,v_result_deleted)
        on conflict on constraint mind_maps_pkey do update set payload=excluded.payload,
          updated_at=excluded.updated_at, deleted_at=excluded.deleted_at;
    elsif p_entity_type = 'mind_map_node' then
      insert into public.mind_map_nodes(owner,map_id,node_id,payload,updated_at,deleted_at)
        values(v_owner,p_map_id,v_node_id,p_payload,p_updated_at,v_result_deleted)
        on conflict on constraint mind_map_nodes_pkey do update set payload=excluded.payload,
          updated_at=excluded.updated_at, deleted_at=excluded.deleted_at;
    elsif p_entity_type = 'mind_map_parent_slot' then
      insert into public.mind_map_parent_slots(owner,map_id,child_node_id,
        parent_node_id,payload,updated_at,deleted_at)
        values(v_owner,p_map_id,v_child_id,v_parent_id,p_payload,p_updated_at,
          v_result_deleted)
        on conflict on constraint mind_map_parent_slots_pkey do update set
          parent_node_id=excluded.parent_node_id,payload=excluded.payload,
          updated_at=excluded.updated_at,deleted_at=excluded.deleted_at;
    else
      insert into public.mind_map_side_links(owner,map_id,first_node_id,
        second_node_id,payload,updated_at,deleted_at)
        values(v_owner,p_map_id,v_first,v_second,p_payload,p_updated_at,
          v_result_deleted)
        on conflict on constraint mind_map_side_links_pkey do update set
          payload=excluded.payload,updated_at=excluded.updated_at,
          deleted_at=excluded.deleted_at;
    end if;
  end if;

  if v_conflict then
    insert into public.mind_map_conflicts(owner,conflict_id,map_id,entity_type,
      entity_id,active_payload,active_updated_at,retained_payload,
      retained_updated_at,reason)
    values(v_owner,p_operation_id,p_map_id,p_entity_type,p_entity_id,
      v_result,v_result_at,v_retained,v_retained_at,
      coalesce(v_rejection,case when v_unresolved then 'equal_time'
        else 'version' end)) on conflict do nothing;
  end if;
  insert into public.mind_map_operation_receipts(owner,operation_id,entity_type,
    entity_id,kind,request_payload,request_updated_at,result_payload,
    result_updated_at,result_deleted_at,conflict_detected,conflict_unresolved,
    retained_payload,retained_updated_at,rejection_reason)
  values(v_owner,p_operation_id,p_entity_type,p_entity_id,p_kind,p_payload,
    p_updated_at,v_result,v_result_at,v_result_deleted,v_conflict,v_unresolved,
    v_retained,v_retained_at,v_rejection);
  return query select v_owner,p_entity_type,p_entity_id,v_result,p_operation_id,
    v_result_at,v_result_deleted,v_conflict,v_unresolved,v_retained,
    v_retained_at,v_rejection,false;
end;
$$;

revoke all on function public.apply_mind_map_change(
  text,uuid,text,jsonb,text,timestamptz,text) from public, anon;
grant execute on function public.apply_mind_map_change(
  text,uuid,text,jsonb,text,timestamptz,text) to authenticated;
notify pgrst, 'reload schema';
commit;
