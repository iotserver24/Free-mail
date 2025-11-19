# PostgreSQL Database Setup Guide

## Quick Setup (Recommended)

### Option 1: Using PowerShell Script (Windows) ⭐

**Prerequisites:**
- PostgreSQL client tools installed (`psql` command)
- Or use the manual method below

**Steps:**

1. **Open PowerShell** in the project root directory:
   ```powershell
   cd C:\Users\Asus\codes-rep\Free-mail
   ```

2. **Run the setup script**:
   ```powershell
   .\db\setup.ps1
   ```

   The script will:
   - Connect to your PostgreSQL database
   - Execute `init.sql` to create all tables
   - Set up extensions, triggers, and schema

3. **Verify setup**:
   ```powershell
   psql -h 193.24.208.154 -U postgres -d chat -c "\dt"
   ```
   You should see all tables: `users`, `messages`, `attachments`, `labels`, `mailboxes`, `message_labels`

---

### Option 2: Using psql Command Directly

**If you have PostgreSQL client tools installed:**

```powershell
# Set password (Windows PowerShell)
$env:PGPASSWORD = "18751@Anish"

# Run the init script
psql -h 193.24.208.154 -U postgres -d chat -f db\init.sql
```

**Or on Linux/Mac:**

```bash
export PGPASSWORD="18751@Anish"
psql -h 193.24.208.154 -U postgres -d chat -f db/init.sql
```

---

### Option 3: Using Database GUI Tool

**Using pgAdmin, DBeaver, or any PostgreSQL client:**

1. **Connect to your database:**
   - Host: `193.24.208.154`
   - Port: `5432`
   - Database: `chat`
   - Username: `postgres`
   - Password: `18751@Anish`
   - SSL Mode: `allow` or `require`

2. **Open SQL Editor** and paste the contents of `db/init.sql`

3. **Execute** the SQL script

---

### Option 4: Manual Step-by-Step

If you prefer to run commands manually:

```sql
-- 1. Connect to your database
\c chat;

-- 2. Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. Create timestamp trigger function
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Create all tables (copy from init.sql)
-- ... (see db/init.sql for full schema)
```

---

## Database Connection Details

From your `backend/.env`:

```
Host: 193.24.208.154
Port: 5432
Database: chat
Username: postgres
Password: 18751@Anish
SSL Mode: allow
```

**Connection String:**
```
postgres://postgres:18751%40Anish@193.24.208.154:5432/chat?sslmode=allow
```

---

## What Gets Created

The `init.sql` script creates:

1. **Extensions:**
   - `uuid-ossp` - For UUID generation

2. **Functions:**
   - `trigger_set_timestamp()` - Auto-updates `updated_at` column

3. **Tables:**
   - `users` - User accounts (with password_hash)
   - `mailboxes` - Email mailboxes/folders
   - `labels` - Email labels/tags
   - `messages` - Email messages (inbound/outbound)
   - `attachments` - Email attachments
   - `message_labels` - Many-to-many relationship between messages and labels

4. **Enums:**
   - `message_direction` - 'inbound' | 'outbound'
   - `message_status` - 'queued' | 'sent' | 'failed' | 'received'

5. **Triggers:**
   - `messages_updated_at` - Auto-updates `updated_at` on message updates

---

## Troubleshooting

### Error: "relation does not exist"
- Make sure you're connected to the `chat` database
- Run `\c chat;` before executing SQL

### Error: "extension uuid-ossp does not exist"
- Your PostgreSQL version might not have it
- Install with: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

### Error: "password authentication failed"
- Verify password: `18751@Anish`
- Check if your IP is whitelisted on the PostgreSQL server

### Error: "could not connect to server"
- Check if PostgreSQL server is running
- Verify host: `193.24.208.154` and port: `5432`
- Check firewall settings

### SSL Connection Issues
- Your connection string uses `sslmode=allow`
- If issues persist, try `sslmode=require` or `sslmode=prefer`

---

## Migration Scripts

### If you have an existing database:

**Add password_hash column:**
```sql
-- Run this if users table exists but password_hash is missing
\i db/migration_add_password.sql
```

Or manually:
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
UPDATE users SET password_hash = '' WHERE password_hash IS NULL;
ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL;
```

---

## Verify Setup

After running the setup, verify everything is created:

```sql
-- List all tables
\dt

-- Check users table structure
\d users

-- Check messages table structure
\d messages

-- Verify extensions
\dx
```

You should see:
- ✅ `uuid-ossp` extension
- ✅ All 6 tables created
- ✅ Proper foreign key relationships

---

## Next Steps

After database setup:

1. **Start your backend:**
   ```bash
   cd backend
   npm run dev
   ```

2. **Test connection:**
   - Backend should connect automatically
   - Check logs for "API listening on port 4000"

3. **Login:**
   - Use admin credentials from `backend/.env`
   - Admin user will be auto-created on first login

---

## Files in this directory:

- **`init.sql`** - Main setup script (creates everything)
- **`schema.sql`** - Just the schema (no extensions/triggers)
- **`migration_add_password.sql`** - Migration for existing databases
- **`setup.ps1`** - PowerShell automation script
- **`setup.sh`** - Bash automation script

**Use `init.sql` for fresh database setup!**

