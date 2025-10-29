-- Crear la tabla de tareas
create table if not exists public.tasks (
  id uuid primary key default uuid_generate_v4(),
  title varchar(255) not null,
  description text,
  date date not null,
  time time not null,
  priority varchar(20) not null check (priority in ('baja', 'media', 'alta')),
  status varchar(20) not null check (status in ('pendiente', 'en_progreso', 'completada')),
  user_id uuid not null references public.usuarios(id),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone,
  constraint fk_user foreign key (user_id) references public.usuarios(id) on delete cascade
);

-- Crear índices para optimizar búsquedas
create index if not exists idx_tasks_user_id on public.tasks(user_id);
create index if not exists idx_tasks_date on public.tasks(date);
create index if not exists idx_tasks_status on public.tasks(status);

-- Configurar RLS (Row Level Security)
alter table public.tasks enable row level security;

-- Crear políticas de seguridad
create policy "Users can view their own tasks"
  on public.tasks for select
  using (auth.uid() = user_id);

create policy "Users can insert their own tasks"
  on public.tasks for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own tasks"
  on public.tasks for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own tasks"
  on public.tasks for delete
  using (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at
  before update on public.tasks
  for each row
  execute procedure public.handle_updated_at();