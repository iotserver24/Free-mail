create extension if not exists "uuid-ossp";

create or replace function trigger_set_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create table if not exists users (
  id uuid primary key default uuid_generate_v4(),
  email text not null unique,
  password_hash text not null,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists mailboxes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  slug text not null,
  created_at timestamptz not null default now(),
  unique (user_id, slug)
);

create table if not exists labels (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

do $$
begin
  if not exists (select 1 from pg_type where typname = 'message_direction') then
    create type message_direction as enum ('inbound', 'outbound');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'message_status') then
    create type message_status as enum ('queued', 'sent', 'failed', 'received');
  end if;
end
$$;

create table if not exists messages (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references users(id) on delete cascade,
  mailbox_id uuid references mailboxes(id) on delete set null,
  direction message_direction not null,
  subject text not null,
  preview_text text,
  body_plain text,
  body_html text,
  status message_status not null,
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger messages_updated_at
before update on messages
for each row
execute procedure trigger_set_timestamp();

create table if not exists attachments (
  id uuid primary key,
  message_id uuid not null references messages(id) on delete cascade,
  filename text not null,
  mimetype text not null,
  size_bytes integer not null,
  url text not null,
  created_at timestamptz not null default now()
);

create table if not exists message_labels (
  message_id uuid not null references messages(id) on delete cascade,
  label_id uuid not null references labels(id) on delete cascade,
  primary key (message_id, label_id)
);

