-- Migration: Add password_hash column to users table
-- Run this if you have an existing database without the password_hash field

-- Check if password_hash column exists, if not add it
do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_name = 'users'
    and column_name = 'password_hash'
  ) then
    alter table users add column password_hash text;
    
    -- For existing users without passwords, set a placeholder
    -- You should update these manually or delete them
    update users set password_hash = '' where password_hash is null;
    
    -- Make it required for new users
    alter table users alter column password_hash set not null;
  end if;
end
$$;

