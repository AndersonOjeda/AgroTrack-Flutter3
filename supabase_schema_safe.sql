-- =====================================================
-- ESQUEMA AGROTRACK - BASE DE DATOS SUPABASE (VERSIÓN SEGURA)
-- =====================================================
-- 
-- Esta versión del esquema maneja correctamente las políticas RLS existentes
-- eliminándolas antes de recrearlas para evitar errores de duplicación
-- 
-- Versión: 2.1 (Safe)
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

-- Asegurar columnas requeridas en despliegues existentes antes de RLS
alter table if exists public.usuarios add column if not exists auth_user_id uuid unique;
alter table if exists public.usuarios add column if not exists email_confirmado boolean default false;
alter table if exists public.usuarios add column if not exists fecha_confirmacion_email timestamp with time zone;
alter table if exists public.usuarios add column if not exists experiencia_agricola text;
alter table if exists public.usuarios add column if not exists tamano_finca numeric;
alter table if exists public.usuarios add column if not exists fecha_nacimiento date;
alter table if exists public.usuarios add column if not exists bio text;
alter table if exists public.usuarios add column if not exists profile_image_url text;

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
-- TABLA DE UBICACIONES DE FINCAS
-- =====================================================

create table if not exists public.farm_locations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.usuarios(id) on delete cascade,
  name varchar(255) not null,
  latitude numeric not null,
  longitude numeric not null,
  description text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

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
-- CONFIGURACIÓN DE SEGURIDAD (RLS) - ELIMINACIÓN SEGURA
-- =====================================================

-- Eliminar políticas existentes de forma segura antes de recrearlas
drop policy if exists "Usuarios viewable by owner" on public.usuarios;
drop policy if exists "Usuarios manageable by owner" on public.usuarios;
drop policy if exists "Farm locations viewable by owner" on public.farm_locations;
drop policy if exists "Farm locations insertable by owner" on public.farm_locations;
drop policy if exists "Farm locations updatable by owner" on public.farm_locations;
drop policy if exists "Farm locations deletable by owner" on public.farm_locations;
drop policy if exists "Inventory items viewable by owner" on public.inventory_items;
drop policy if exists "Inventory items insertable by owner" on public.inventory_items;
drop policy if exists "Inventory items updatable by owner" on public.inventory_items;
drop policy if exists "Inventory items deletable by owner" on public.inventory_items;

-- Habilitar RLS
alter table if exists public.usuarios enable row level security;
alter table if exists public.farm_locations enable row level security;
alter table if exists public.inventory_items enable row level security;

-- =====================================================
-- POLÍTICAS RLS PARA USUARIOS
-- =====================================================

create policy "Usuarios viewable by owner" on public.usuarios
  for select using (auth.uid() = auth_user_id);
create policy "Usuarios manageable by owner" on public.usuarios
  for all using (auth.uid() = auth_user_id);

-- =====================================================
-- POLÍTICAS RLS PARA UBICACIONES DE FINCAS
-- =====================================================

create policy "Farm locations viewable by owner" on public.farm_locations
  for select using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Farm locations insertable by owner" on public.farm_locations
  for insert with check (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Farm locations updatable by owner" on public.farm_locations
  for update using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Farm locations deletable by owner" on public.farm_locations
  for delete using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

-- =====================================================
-- POLÍTICAS RLS PARA INVENTARIO
-- =====================================================

create policy "Inventory items viewable by owner" on public.inventory_items
  for select using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Inventory items insertable by owner" on public.inventory_items
  for insert with check (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Inventory items updatable by owner" on public.inventory_items
  for update using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

create policy "Inventory items deletable by owner" on public.inventory_items
  for delete using (
    user_id in (
      select id from public.usuarios where auth_user_id = auth.uid()
    )
  );

-- =====================================================
-- TRIGGERS Y FUNCIONES AUTOMÁTICAS
-- =====================================================

-- Trigger: set updated_at en updates
create or replace function public.set_updated_at()
returns trigger as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists usuarios_set_updated_at on public.usuarios;
create trigger usuarios_set_updated_at
  before update on public.usuarios
  for each row execute function public.set_updated_at();

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
  before update on public.inventory_items
  for each row execute function public.set_updated_at();

-- Trigger: poblar usuarios al registrarse
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

drop trigger if exists on_auth_user_created_usuarios on auth.users;
create trigger on_auth_user_created_usuarios
  after insert on auth.users
  for each row execute function public.handle_new_user_usuarios();

-- =====================================================
-- FUNCIONES AUXILIARES
-- =====================================================

-- Función para obtener el user_id basado en auth.uid()
create or replace function public.get_user_id_from_auth()
returns uuid as $$
begin
  return (
    select id from public.usuarios where auth_user_id = auth.uid() limit 1
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

grant execute on function public.link_existing_usuario_to_auth_user(varchar) to authenticated;
grant execute on function public.get_user_id_from_auth() to authenticated;

-- =====================================================
-- MENSAJE DE FINALIZACIÓN
-- =====================================================

do $$
begin
  raise notice 'Esquema AgroTrack aplicado exitosamente (versión segura)';
  raise notice 'Tablas creadas: usuarios, farm_locations, inventory_items';
  raise notice 'Políticas RLS configuradas correctamente';
  raise notice 'Triggers y funciones auxiliares activados';
end $$;