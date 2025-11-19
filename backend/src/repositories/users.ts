import { pool } from "../db";
import bcrypt from "bcryptjs";
import type { UserRecord } from "../types";

export interface CreateUserInput {
  email: string;
  password: string;
  displayName?: string;
}

export async function createUser(input: CreateUserInput): Promise<UserRecord> {
  const passwordHash = await bcrypt.hash(input.password, 10);
  const result = await pool.query<UserRecord>(
    `insert into users (email, password_hash, display_name)
     values ($1, $2, $3)
     returning id, email, display_name, created_at`,
    [input.email, passwordHash, input.displayName ?? null]
  );
  if (!result.rows[0]) {
    throw new Error("Failed to create user");
  }
  return result.rows[0];
}

export async function getUserByEmail(email: string): Promise<(UserRecord & { password_hash: string }) | null> {
  const result = await pool.query<UserRecord & { password_hash: string }>(
    `select id, email, password_hash, display_name, created_at
     from users
     where email = $1`,
    [email]
  );
  return result.rows[0] ?? null;
}

export async function getUserById(id: string): Promise<UserRecord | null> {
  const result = await pool.query<UserRecord>(
    `select id, email, display_name, created_at
     from users
     where id = $1`,
    [id]
  );
  return result.rows[0] ?? null;
}

export async function verifyPassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
  return bcrypt.compare(plainPassword, hashedPassword);
}

