import { MongoClient, Db } from "mongodb";
import { config } from "./config";

// Global connection for serverless (reused across invocations)
let client: MongoClient | null = null;
let db: Db | null = null;

// Connection promise to prevent multiple simultaneous connections
let connectionPromise: Promise<Db> | null = null;

export async function connectDatabase(): Promise<Db> {
  // Return existing connection if available
  if (db) {
    return db;
  }

  // Reuse connection promise if connection is in progress
  if (connectionPromise) {
    return connectionPromise;
  }

  // Create new connection
  connectionPromise = (async () => {
    if (!client) {
      client = new MongoClient(config.database.url, {
        maxPoolSize: 10, // Maintain up to 10 socket connections
        serverSelectionTimeoutMS: 5000, // Keep trying to send operations for 5 seconds
        socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
      });
      await client.connect();
    }

    const dbName = config.database.url.split("/").pop()?.split("?")[0] || "freemail";
    db = client.db(dbName);
    return db;
  })();

  try {
    return await connectionPromise;
  } catch (error) {
    // Reset on error
    connectionPromise = null;
    throw error;
  }
}

export async function ensureConnection(): Promise<void> {
  const database = await connectDatabase();
  await database.admin().ping();
  
  // Create indexes for better performance (only if they don't exist)
  try {
    const usersCollection = database.collection("users");
    await usersCollection.createIndex({ email: 1 }, { unique: true, background: true });
    await usersCollection.createIndex({ id: 1 }, { unique: true, background: true });
    
    const messagesCollection = database.collection("messages");
    await messagesCollection.createIndex({ user_id: 1, created_at: -1 }, { background: true });
    await messagesCollection.createIndex({ id: 1 }, { unique: true, background: true });
    
    const attachmentsCollection = database.collection("attachments");
    await attachmentsCollection.createIndex({ message_id: 1 }, { background: true });
    await attachmentsCollection.createIndex({ id: 1 }, { unique: true, background: true });
  } catch (error) {
    // Indexes might already exist, ignore errors
    console.warn("Index creation warning (may already exist):", error);
  }
}

export async function closeConnection(): Promise<void> {
  if (client) {
    await client.close();
    client = null;
    db = null;
  }
}

// Get database instance
export async function getDb(): Promise<Db> {
  return connectDatabase();
}
