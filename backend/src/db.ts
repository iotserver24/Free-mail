import { Pool } from "pg";
import { config } from "./config";

// Remove sslmode from connection string and handle SSL via config
const dbUrl = config.database.url.split("?")[0];

export const pool = new Pool({
  connectionString: dbUrl,
  ssl: {
    rejectUnauthorized: false, // Allow self-signed certificates
  },
});

export async function ensureConnection(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("select 1");
  } finally {
    client.release();
  }
}

