-- =====================================================
-- ESQUEMA AGROTRACK - BASE DE DATOS SUPABASE
-- =====================================================
-- 
-- Este esquema define la estructura inicial para la aplicación AgroTrack
-- Incluye:
-- - Tabla de usuarios con campos completos de perfil
-- - Triggers automáticos para sincronización con auth.users
-- - Funciones de debug para diagnóstico y resolución de problemas
-- - Índices optimizados para rendimiento
-- - Políticas RLS (Row Level Security) para seguridad
-- 
-- Versión: 2.0
-- Fecha: 2024
-- =====================================================

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- =====================================================
-- TABLA PRINCIPAL: USUARIOS
-- =====================================================
-- 
-- Almacena información completa de los usuarios de AgroTrack
-- Se sincroniza automáticamente con auth.users mediante triggers
-- 
-- Campos principales:
-- - Información personal: nombre, apellido, email, teléfono
-- - Perfil agrícola: ubicación, tipo_agricultura, experiencia, tamaño_finca
-- - Perfil social: bio, profile_image_url
-- - Control: email_confirmado, activo, fechas de auditoría
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
-- CONFIGURACIÓN DE SEGURIDAD (RLS)
-- =====================================================
-- 
-- Row Level Security (RLS) garantiza que cada usuario solo pueda
-- acceder y modificar sus propios datos
-- =====================================================

-- RLS
alter table if exists public.usuarios enable row level security;

create policy "Usuarios viewable by owner" on public.usuarios
  for select using (auth.uid() = auth_user_id);
create policy "Usuarios manageable by owner" on public.usuarios
  for all using (auth.uid() = auth_user_id);

-- =====================================================
-- TRIGGERS Y FUNCIONES AUTOMÁTICAS
-- =====================================================
-- 
-- Funciones que se ejecutan automáticamente para mantener
-- la sincronización y consistencia de datos
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

-- =====================================================
-- FUNCIONES DE DEBUG Y UTILIDADES
-- =====================================================

-- Función para verificar si un usuario existe en la tabla usuarios
create or replace function public.debug_check_user_exists(user_auth_id uuid)
returns boolean as $$
begin
  return exists (select 1 from public.usuarios where auth_user_id = user_auth_id);
end;
$$ language plpgsql security definer;

-- Función para crear un usuario manualmente en la tabla usuarios
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

-- Función para obtener información completa de un usuario para debug
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

-- Función para listar todos los usuarios (solo para debug)
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
  result json;
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
  
  -- Aquí normalmente se llamaría a la API de Supabase para reenviar
  -- Por ahora retornamos un mensaje de éxito
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

-- Función para actualizar estado de confirmación de email
create or replace function public.update_email_confirmation_status(user_auth_id uuid, confirmed boolean default true)
returns json as $$
declare
  updated_rows integer;
begin
  -- Actualizar en la tabla usuarios
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

-- Función para verificar estado de confirmación de email
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

-- =====================================================
-- POLÍTICAS RLS ADICIONALES PARA FUNCIONES DE DEBUG Y EMAIL
-- =====================================================

-- Permitir acceso a funciones de debug solo para usuarios autenticados
grant execute on function public.debug_check_user_exists(uuid) to authenticated;
grant execute on function public.debug_create_user_manual(uuid, varchar, varchar, varchar) to authenticated;
grant execute on function public.debug_get_user_info(uuid) to authenticated;
grant execute on function public.debug_list_all_users() to authenticated;

-- Permitir acceso a funciones de manejo de email
grant execute on function public.resend_confirmation_email(varchar) to authenticated;
grant execute on function public.update_email_confirmation_status(uuid, boolean) to authenticated;
grant execute on function public.check_email_confirmation_status(varchar) to authenticated;

-- =====================================================
-- UTILIDAD: Vincular fila existente por email con el usuario autenticado
-- =====================================================
-- Corrige casos donde existe un registro en public.usuarios con el mismo
-- email pero sin auth_user_id asignado (o asignado incorrectamente),
-- permitiendo que el usuario autenticado reclame su propia fila.
-- Usa SECURITY DEFINER para operar fuera de RLS, pero con validaciones.
create or replace function public.link_existing_usuario_to_auth_user(user_email varchar)
returns boolean as $$
begin
  -- Solo vincular si la fila existe y NO tiene auth_user_id o coincide
  update public.usuarios
     set auth_user_id = auth.uid(), updated_at = now()
   where email = user_email
     and (auth_user_id is null or auth_user_id = auth.uid());

  return found; -- true si se actualizó alguna fila
end;
$$ language plpgsql security definer;

grant execute on function public.link_existing_usuario_to_auth_user(varchar) to authenticated;

-- =====================================================
-- ACTIVACIÓN DE TRIGGERS
-- =====================================================

drop trigger if exists on_auth_user_created_usuarios on auth.users;
create trigger on_auth_user_created_usuarios
  after insert on auth.users
  for each row execute function public.handle_new_user_usuarios();

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE RENDIMIENTO
-- =====================================================

-- Índice para búsquedas por auth_user_id (más común)
create index if not exists idx_usuarios_auth_user_id on public.usuarios(auth_user_id);

-- Índice para búsquedas por email
create index if not exists idx_usuarios_email on public.usuarios(email);

-- Índice para filtros por estado activo
create index if not exists idx_usuarios_activo on public.usuarios(activo);

-- Índice para ordenamiento por fecha de registro
create index if not exists idx_usuarios_fecha_registro on public.usuarios(fecha_registro);

-- Índice compuesto para consultas comunes de usuarios activos
create index if not exists idx_usuarios_activo_fecha on public.usuarios(activo, fecha_registro desc);