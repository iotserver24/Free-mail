# MongoDB Setup Guide

## Quick Start

### Option 1: MongoDB Atlas (Cloud - Recommended) ⭐

1. **Sign up**: Go to [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. **Create a free cluster** (M0 - Free tier)
3. **Get connection string**:
   - Click "Connect" → "Connect your application"
   - Copy the connection string
   - Replace `<password>` with your database password
   - Example: `mongodb+srv://username:password@cluster.mongodb.net/freemail`

4. **Update `.env`**:
   ```
   MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/freemail
   ```

5. **Whitelist your IP** (if needed):
   - Network Access → Add IP Address
   - Or use `0.0.0.0/0` for development (not recommended for production)

---

### Option 2: Local MongoDB

**Windows:**

1. **Download**: [MongoDB Community Server](https://www.mongodb.com/try/download/community)
2. **Install** MongoDB
3. **Start MongoDB**:
   ```powershell
   # Usually starts automatically as a service
   # Or run manually:
   mongod --dbpath "C:\data\db"
   ```

4. **Update `.env`**:
   ```
   MONGODB_URL=mongodb://localhost:27017/freemail
   ```

**Linux/Mac:**

```bash
# Install
brew install mongodb-community  # Mac
# or
sudo apt-get install mongodb     # Ubuntu

# Start
mongod --dbpath /data/db
```

---

## Connection String Formats

**Local:**
```
mongodb://localhost:27017/freemail
```

**With Authentication:**
```
mongodb://username:password@localhost:27017/freemail
```

**MongoDB Atlas (Cloud):**
```
mongodb+srv://username:password@cluster.mongodb.net/freemail
```

**With Options:**
```
mongodb://localhost:27017/freemail?retryWrites=true&w=majority
```

---

## Collections Created Automatically

The app will automatically create these collections when you first use them:

- `users` - User accounts
- `messages` - Email messages
- `attachments` - Email attachments

**No manual setup needed!** MongoDB creates collections on first insert.

---

## Verify Connection

After starting your backend:

```bash
cd backend
npm run dev
```

You should see:
```
API listening on port 4000
```

If there's a connection error, check:
1. MongoDB is running (if local)
2. Connection string in `.env` is correct
3. Network/firewall allows connection
4. Credentials are correct (if using auth)

---

## Migration from PostgreSQL

✅ **Already done!** The code has been migrated to MongoDB.

**What changed:**
- `pg` → `mongodb` driver
- SQL queries → MongoDB queries
- Tables → Collections
- No schema needed (MongoDB is schema-less)

**No database setup scripts needed!** Just update `MONGODB_URL` in `.env` and you're good to go.

---

## Troubleshooting

### "MongoServerError: Authentication failed"
- Check username/password in connection string
- Verify database user has correct permissions

### "MongoNetworkError: connect ECONNREFUSED"
- MongoDB server is not running (if local)
- Check if port 27017 is accessible
- Verify connection string host/port

### "MongoServerSelectionError"
- Network/firewall blocking connection
- IP not whitelisted (MongoDB Atlas)
- Connection string incorrect

---

## Next Steps

1. **Update `.env`** with your MongoDB connection string
2. **Install dependencies**:
   ```bash
   cd backend
   npm install
   ```
3. **Start backend**:
   ```bash
   npm run dev
   ```
4. **Test**: Login and send an email!

---

## MongoDB Atlas Free Tier

- ✅ 512 MB storage
- ✅ Shared cluster
- ✅ Perfect for development
- ✅ No credit card required (for M0 tier)

**Perfect for this project!** 🚀

