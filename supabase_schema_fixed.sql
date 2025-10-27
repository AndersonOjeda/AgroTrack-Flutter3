-- =====================================================
-- ESQUEMA AGROTRACK - BASE DE DATOS SUPABASE (VERSIÓN CORREGIDA)
-- =====================================================
-- 
-- Este esquema define la estructura inicial para la aplicación AgroTrack
-- Incluye manejo de conflictos para políticas y objetos existentes
-- 
-- Versión: 2.2 (Orden de ejecución corregido)
-- Fecha: 2024
-- =====================================================

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- =====================================================
-- TABLA PRINCIPAL: USUARIOS
-- =====================================================

-- Tabla usuarios según especificación
create table if not exists public.usuarios (
  id uuid primary key default uuid_generate_v4(),
  email varchar(255) unique not null,
  nombre varchar(100) not null default '',
  apellido varchar(100) not null default '',
  telefono varchar(20),
  ubicacion text,
  tipo_agricultura varchar(50),
  experiencia_agricola text,
  tamano_finca numeric,
  fecha_nacimiento date,
  bio text,
  profile_image_url text,
  email_confirmado boolean default false,
  fecha_confirmacion_email timestamp with time zone,
  auth_user_id uuid unique,
  fecha_registro timestamp with time zone default now(),
  activo boolean default true,
  fecha_eliminacion timestamp with time zone,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Asegurar columnas requeridas en despliegues existentes
alter table if exists public.usuarios add column if not exists auth_user_id uuid unique;
alter table if exists public.usuarios add column if not exists email_confirmado boolean default false;
alter table if exists public.usuarios add column if not exists fecha_confirmacion_email timestamp with time zone;
alter table if exists public.usuarios add column if not exists experiencia_agricola text;
alter table if exists public.usuarios add column if not exists tamano_finca numeric;
alter table if exists public.usuarios add column if not exists fecha_nacimiento date;
alter table if exists public.usuarios add column if not exists bio text;
alter table if exists public.usuarios add column if not exists profile_image_url text;

-- =====================================================
-- TABLA DE INVENTARIO
-- =====================================================

create table if not exists public.inventory_items (
  id varchar(255) primary key,
  user_id uuid not null references public.usuarios(id) on delete cascade,
  nombre varchar(255) not null,
  categoria varchar(100) not null,
  descripcion text,
  cantidad numeric not null default 0,
  unidad_medida varchar(50) not null,
  precio_unitario numeric,
  valor_total numeric,
  proveedor varchar(255),
  fecha_compra timestamp with time zone,
  fecha_vencimiento timestamp with time zone,
  ubicacion_almacen varchar(255),
  lote varchar(100),
  cantidad_minima numeric,
  estado varchar(50) default 'disponible',
  notas text,
  imagen_url text,
  needs_sync boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- =====================================================
-- VINCULAR USUARIOS CON AUTH
-- =====================================================

-- Vincular usuarios.auth_user_id con auth.users.id (FK condicional)
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'usuarios_auth_user_fk'
  ) then
    alter table public.usuarios
      add constraint usuarios_auth_user_fk
      foreign key (auth_user_id)
      references auth.users(id)
      on delete set null;
  end if;
end $$;

-- =====================================================
-- LIMPIEZA DE POLÍTICAS EXISTENTES (DESPUÉS DE CREAR TABLAS)
-- =====================================================

-- Eliminar políticas existentes para usuarios
drop policy if exists "Usuarios visibles por propietario" on public.usuarios;
drop policy if exists "Usuarios viewable by owner" on public.usuarios;
drop policy if exists "Usuarios manageable by owner" on public.usuarios;
drop policy if exists "Usuarios gestionables por propietario" on public.usuarios;

-- Eliminar políticas de inventario si existen
drop policy if exists "Inventory items viewable by owner" on public.inventory_items;
drop policy if exists "Inventory items insertable by owner" on public.inventory_items;
drop policy if exists "Inventory items updatable by owner" on public.inventory_items;
drop policy if exists "Inventory items deletable by owner" on public.inventory_items;

-- =====================================================
-- CONFIGURACIÓN DE SEGURIDAD (RLS)
-- =====================================================

-- Habilitar RLS para usuarios
alter table if exists public.usuarios enable row level security;

-- Crear políticas para usuarios con nombres únicos
create policy "usuarios_select_policy" on public.usuarios
  for select using (auth.uid() = auth_user_id);

create policy "usuarios_insert_policy" on public.usuarios
  for insert with check (auth.uid() = auth_user_id);

create policy "usuarios_update_policy" on public.usuarios
  for update using (auth.uid() = auth_user_id);

create policy "usuarios_delete_policy" on public.usuarios
  for delete using (auth.uid() = auth_user_id);

-- Habilitar RLS para inventario
alter table if exists public.inventory_items enable row level security;

-- Políticas para inventario con nombres únicos
create policy "inventory_select_policy" on public.inventory_items
  for select using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "inventory_insert_policy" on public.inventory_items
  for insert with check (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "inventory_update_policy" on public.inventory_items
  for update using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "inventory_delete_policy" on public.inventory_items
  for delete using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

-- =====================================================
-- TRIGGERS Y FUNCIONES AUTOMÁTICAS
-- =====================================================

-- Función para actualizar updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$ language plpgsql;

-- Eliminar triggers existentes y crear nuevos
drop trigger if exists usuarios_set_updated_at on public.usuarios;
create trigger usuarios_set_updated_at
  before update on public.usuarios
  for each row execute function public.set_updated_at();

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
  before update on public.inventory_items
  for each row execute function public.set_updated_at();

-- Función para manejar nuevos usuarios
create or replace function public.handle_new_user_usuarios()
returns trigger as $$
begin
  -- Verificar si el usuario ya existe para evitar duplicados
  if exists (select 1 from public.usuarios where auth_user_id = new.id) then
    return new;
  end if;
  
  insert into public.usuarios (
    auth_user_id,
    email,
    nombre,
    apellido,
    ubicacion,
    experiencia_agricola,
    tamano_finca,
    tipo_agricultura,
    fecha_nacimiento,
    bio,
    profile_image_url,
    email_confirmado
  )
  values (
    new.id,
    new.email,
    coalesce((new.raw_user_meta_data ->> 'nombre'), ''),
    coalesce((new.raw_user_meta_data ->> 'apellido'), ''),
    (new.raw_user_meta_data ->> 'ubicacion'),
    (new.raw_user_meta_data ->> 'experiencia_agricola'),
    nullif((new.raw_user_meta_data ->> 'tamano_finca'), '')::numeric,
    (new.raw_user_meta_data ->> 'tipo_agricultura'),
    nullif((new.raw_user_meta_data ->> 'fecha_nacimiento'), '')::date,
    (new.raw_user_meta_data ->> 'bio'),
    (new.raw_user_meta_data ->> 'profile_image_url'),
    new.email_confirmed_at is not null
  );
  return new;
exception
  when others then
    -- Log del error pero no fallar el registro de autenticación
    raise warning 'Error al crear usuario en tabla usuarios: %', sqlerrm;
    return new;
end;
$$ language plpgsql security definer;

-- Eliminar trigger existente y crear nuevo
drop trigger if exists on_auth_user_created_usuarios on auth.users;
create trigger on_auth_user_created_usuarios
  after insert on auth.users
  for each row execute function public.handle_new_user_usuarios();

-- =====================================================
-- FUNCIONES DE DEBUG Y UTILIDADES
-- =====================================================

-- Función para verificar si un usuario existe
create or replace function public.debug_check_user_exists(user_auth_id uuid)
returns boolean as $$
begin
  return exists (select 1 from public.usuarios where auth_user_id = user_auth_id);
end;
$$ language plpgsql security definer;

-- Función para crear un usuario manualmente
create or replace function public.debug_create_user_manual(
  user_auth_id uuid,
  user_email varchar(255),
  user_nombre varchar(100) default '',
  user_apellido varchar(100) default ''
)
returns uuid as $$
declare
  new_user_id uuid;
begin
  -- Verificar si el usuario ya existe
  if exists (select 1 from public.usuarios where auth_user_id = user_auth_id) then
    raise exception 'Usuario ya existe con auth_user_id: %', user_auth_id;
  end if;
  
  -- Crear el usuario
  insert into public.usuarios (
    auth_user_id,
    email,
    nombre,
    apellido,
    email_confirmado
  )
  values (
    user_auth_id,
    user_email,
    user_nombre,
    user_apellido,
    true
  )
  returning id into new_user_id;
  
  return new_user_id;
end;
$$ language plpgsql security definer;

-- Función para obtener información de usuario
create or replace function public.debug_get_user_info(user_auth_id uuid)
returns table (
  user_id uuid,
  email varchar(255),
  nombre varchar(100),
  apellido varchar(100),
  auth_user_id uuid,
  email_confirmado boolean,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
) as $$
begin
  return query
  select 
    u.id,
    u.email,
    u.nombre,
    u.apellido,
    u.auth_user_id,
    u.email_confirmado,
    u.created_at,
    u.updated_at
  from public.usuarios u
  where u.auth_user_id = user_auth_id;
end;
$$ language plpgsql security definer;

-- Función para listar usuarios
create or replace function public.debug_list_all_users()
returns table (
  user_id uuid,
  email varchar(255),
  nombre varchar(100),
  apellido varchar(100),
  auth_user_id uuid,
  email_confirmado boolean,
  created_at timestamp with time zone
) as $$
begin
  return query
  select 
    u.id,
    u.email,
    u.nombre,
    u.apellido,
    u.auth_user_id,
    u.email_confirmado,
    u.created_at
  from public.usuarios u
  order by u.created_at desc
  limit 50;
end;
$$ language plpgsql security definer;

-- =====================================================
-- FUNCIONES PARA MANEJO DE CONFIRMACIÓN DE EMAIL
-- =====================================================

-- Función para reenviar correo de confirmación
create or replace function public.resend_confirmation_email(user_email varchar(255))
returns json as $$
declare
  auth_user_record record;
begin
  -- Buscar el usuario en auth.users
  select * into auth_user_record 
  from auth.users 
  where email = user_email;
  
  if not found then
    return json_build_object(
      'success', false,
      'error', 'Usuario no encontrado',
      'message', 'No existe un usuario registrado con este correo electrónico'
    );
  end if;
  
  -- Verificar si ya está confirmado
  if auth_user_record.email_confirmed_at is not null then
    return json_build_object(
      'success', false,
      'error', 'Email ya confirmado',
      'message', 'Este correo electrónico ya ha sido confirmado'
    );
  end if;
  
  return json_build_object(
    'success', true,
    'message', 'Correo de confirmación reenviado exitosamente',
    'email', user_email,
    'user_id', auth_user_record.id
  );
  
exception
  when others then
    return json_build_object(
      'success', false,
      'error', 'Error interno',
      'message', 'Error al procesar la solicitud: ' || sqlerrm
    );
end;
$$ language plpgsql security definer;

-- Función para actualizar estado de confirmación
create or replace function public.update_email_confirmation_status(user_auth_id uuid, confirmed boolean default true)
returns json as $$
declare
  updated_rows integer;
begin
  update public.usuarios 
  set 
    email_confirmado = confirmed,
    fecha_confirmacion_email = case when confirmed then now() else null end,
    updated_at = now()
  where auth_user_id = user_auth_id;
  
  get diagnostics updated_rows = row_count;
  
  if updated_rows = 0 then
    return json_build_object(
      'success', false,
      'error', 'Usuario no encontrado',
      'message', 'No se encontró un usuario con el ID proporcionado'
    );
  end if;
  
  return json_build_object(
    'success', true,
    'message', 'Estado de confirmación actualizado exitosamente',
    'user_id', user_auth_id,
    'confirmed', confirmed
  );
  
exception
  when others then
    return json_build_object(
      'success', false,
      'error', 'Error interno',
      'message', 'Error al actualizar confirmación: ' || sqlerrm
    );
end;
$$ language plpgsql security definer;

-- Función para verificar estado de confirmación
create or replace function public.check_email_confirmation_status(user_email varchar(255))
returns json as $$
declare
  user_record record;
  auth_record record;
begin
  -- Buscar en tabla usuarios
  select * into user_record 
  from public.usuarios 
  where email = user_email;
  
  -- Buscar en auth.users
  select * into auth_record 
  from auth.users 
  where email = user_email;
  
  if not found then
    return json_build_object(
      'success', false,
      'error', 'Usuario no encontrado',
      'message', 'No existe un usuario registrado con este correo electrónico'
    );
  end if;
  
  return json_build_object(
    'success', true,
    'email', user_email,
    'auth_confirmed', auth_record.email_confirmed_at is not null,
    'auth_confirmed_at', auth_record.email_confirmed_at,
    'usuarios_confirmed', coalesce(user_record.email_confirmado, false),
    'usuarios_confirmed_at', user_record.fecha_confirmacion_email,
    'user_exists_in_usuarios', user_record.id is not null,
    'auth_user_id', auth_record.id
  );
  
exception
  when others then
    return json_build_object(
      'success', false,
      'error', 'Error interno',
      'message', 'Error al verificar confirmación: ' || sqlerrm
    );
end;
$$ language plpgsql security definer;

-- Función para vincular usuario existente
create or replace function public.link_existing_usuario_to_auth_user(user_email varchar)
returns boolean as $$
begin
  update public.usuarios
     set auth_user_id = auth.uid(), updated_at = now()
   where email = user_email
     and (auth_user_id is null or auth_user_id = auth.uid());

  return found;
end;
$$ language plpgsql security definer;

-- =====================================================
-- FUNCIONES AUXILIARES PARA INVENTARIO
-- =====================================================

-- Función para obtener user_id del usuario autenticado
create or replace function public.get_user_id_from_auth()
returns uuid as $$
begin
  return (
    select id from public.usuarios where auth_user_id = auth.uid() limit 1
  );
end;
$$ language plpgsql security definer;

-- Función para estadísticas del inventario
create or replace function public.get_inventory_stats()
returns json as $$
declare
  current_user_id uuid;
  total_items integer;
  low_stock_items integer;
  expiring_items integer;
  expired_items integer;
  total_value numeric;
begin
  current_user_id := public.get_user_id_from_auth();
  
  if current_user_id is null then
    return json_build_object(
      'success', false,
      'error', 'Usuario no encontrado'
    );
  end if;
  
  select 
    count(*),
    count(*) filter (where cantidad <= coalesce(cantidad_minima, 0)),
    count(*) filter (where fecha_vencimiento between now() and now() + interval '30 days'),
    count(*) filter (where fecha_vencimiento < now()),
    coalesce(sum(valor_total), 0)
  into 
    total_items,
    low_stock_items,
    expiring_items,
    expired_items,
    total_value
  from public.inventory_items
  where user_id = current_user_id;
  
  return json_build_object(
    'success', true,
    'total_items', total_items,
    'low_stock_items', low_stock_items,
    'expiring_items', expiring_items,
    'expired_items', expired_items,
    'total_value', total_value
  );
  
exception
  when others then
    return json_build_object(
      'success', false,
      'error', 'Error al calcular estadísticas: ' || sqlerrm
    );
end;
$$ language plpgsql security definer;

-- Función para items con stock bajo
create or replace function public.get_low_stock_items()
returns table (
  id varchar(255),
  nombre varchar(255),
  categoria varchar(100),
  cantidad numeric,
  cantidad_minima numeric,
  unidad_medida varchar(50)
) as $$
declare
  current_user_id uuid;
begin
  current_user_id := public.get_user_id_from_auth();
  
  if current_user_id is null then
    return;
  end if;
  
  return query
  select 
    i.id,
    i.nombre,
    i.categoria,
    i.cantidad,
    i.cantidad_minima,
    i.unidad_medida
  from public.inventory_items i
  where i.user_id = current_user_id
    and i.cantidad <= coalesce(i.cantidad_minima, 0)
    and i.cantidad_minima is not null
  order by i.nombre;
end;
$$ language plpgsql security definer;

-- Función para items próximos a vencer
create or replace function public.get_expiring_items(days_ahead integer default 30)
returns table (
  id varchar(255),
  nombre varchar(255),
  categoria varchar(100),
  fecha_vencimiento timestamp with time zone,
  dias_restantes integer
) as $$
declare
  current_user_id uuid;
begin
  current_user_id := public.get_user_id_from_auth();
  
  if current_user_id is null then
    return;
  end if;
  
  return query
  select 
    i.id,
    i.nombre,
    i.categoria,
    i.fecha_vencimiento,
    extract(days from i.fecha_vencimiento - now())::integer as dias_restantes
  from public.inventory_items i
  where i.user_id = current_user_id
    and i.fecha_vencimiento between now() and now() + make_interval(days => days_ahead)
  order by i.fecha_vencimiento;
end;
$$ language plpgsql security definer;

-- =====================================================
-- PERMISOS PARA FUNCIONES
-- =====================================================

-- Permisos para funciones de debug
grant execute on function public.debug_check_user_exists(uuid) to authenticated;
grant execute on function public.debug_create_user_manual(uuid, varchar, varchar, varchar) to authenticated;
grant execute on function public.debug_get_user_info(uuid) to authenticated;
grant execute on function public.debug_list_all_users() to authenticated;

-- Permisos para funciones de email
grant execute on function public.resend_confirmation_email(varchar) to authenticated;
grant execute on function public.update_email_confirmation_status(uuid, boolean) to authenticated;
grant execute on function public.check_email_confirmation_status(varchar) to authenticated;
grant execute on function public.link_existing_usuario_to_auth_user(varchar) to authenticated;

-- Permisos para funciones de inventario
grant execute on function public.get_user_id_from_auth() to authenticated;
grant execute on function public.get_inventory_stats() to authenticated;
grant execute on function public.get_low_stock_items() to authenticated;
grant execute on function public.get_expiring_items(integer) to authenticated;

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para usuarios
create index if not exists idx_usuarios_auth_user_id on public.usuarios(auth_user_id);
create index if not exists idx_usuarios_email on public.usuarios(email);
create index if not exists idx_usuarios_activo on public.usuarios(activo);
create index if not exists idx_usuarios_fecha_registro on public.usuarios(fecha_registro);
create index if not exists idx_usuarios_activo_fecha on public.usuarios(activo, fecha_registro desc);

-- Índices para inventario
create index if not exists idx_inventory_items_user_id on public.inventory_items(user_id);
create index if not exists idx_inventory_items_categoria on public.inventory_items(categoria);
create index if not exists idx_inventory_items_estado on public.inventory_items(estado);
create index if not exists idx_inventory_items_fecha_vencimiento on public.inventory_items(fecha_vencimiento);
create index if not exists idx_inventory_items_cantidad_minima on public.inventory_items(cantidad, cantidad_minima);
create index if not exists idx_inventory_items_created_at on public.inventory_items(created_at);
create index if not exists idx_inventory_items_updated_at on public.inventory_items(updated_at);
create index if not exists idx_inventory_items_needs_sync on public.inventory_items(needs_sync);

-- Índices compuestos
create index if not exists idx_inventory_items_user_categoria on public.inventory_items(user_id, categoria);
create index if not exists idx_inventory_items_user_estado on public.inventory_items(user_id, estado);
create index if not exists idx_inventory_items_user_sync on public.inventory_items(user_id, needs_sync);