import { MongoClient, Db } from "mongodb";
import { config } from "./config";

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectDatabase(): Promise<Db> {
  if (db) {
    return db;
  }

  if (!client) {
    client = new MongoClient(config.database.url);
    await client.connect();
  }

  const dbName = config.database.url.split("/").pop()?.split("?")[0] || "freemail";
  db = client.db(dbName);
  return db;
}

export async function ensureConnection(): Promise<void> {
  const database = await connectDatabase();
  await database.admin().ping();
  
  // Create indexes for better performance
  const usersCollection = database.collection("users");
  await usersCollection.createIndex({ email: 1 }, { unique: true });
  await usersCollection.createIndex({ id: 1 }, { unique: true });
  
  const messagesCollection = database.collection("messages");
  await messagesCollection.createIndex({ user_id: 1, created_at: -1 });
  await messagesCollection.createIndex({ id: 1 }, { unique: true });
  
  const attachmentsCollection = database.collection("attachments");
  await attachmentsCollection.createIndex({ message_id: 1 });
  await attachmentsCollection.createIndex({ id: 1 }, { unique: true });
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
