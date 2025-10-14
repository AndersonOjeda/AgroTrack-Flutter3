-- =====================================================
-- Esquema inicial: solo tabla USUARIOS para login
-- =====================================================
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

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

-- RLS
alter table if exists public.usuarios enable row level security;

create policy "Usuarios viewable by owner" on public.usuarios
  for select using (auth.uid() = auth_user_id);
create policy "Usuarios manageable by owner" on public.usuarios
  for all using (auth.uid() = auth_user_id);

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
    new.email_confirmed_at is not null
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created_usuarios on auth.users;
create trigger on_auth_user_created_usuarios
  after insert on auth.users
  for each row execute function public.handle_new_user_usuarios();