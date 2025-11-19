import { getDb } from "../db";
import bcrypt from "bcryptjs";
import type { UserRecord } from "../types";
import { v4 as uuid } from "uuid";

export interface CreateUserInput {
  email: string;
  password: string;
  displayName?: string;
}

export async function createUser(input: CreateUserInput): Promise<UserRecord> {
  const passwordHash = await bcrypt.hash(input.password, 10);
  const db = await getDb();
  const collection = db.collection("users");

  const user = {
    id: uuid(),
    email: input.email,
    password_hash: passwordHash,
    display_name: input.displayName ?? null,
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(user);

  return {
    id: user.id,
    email: user.email,
    display_name: user.display_name,
    created_at: user.created_at,
  };
}

export async function getUserByEmail(email: string): Promise<(UserRecord & { password_hash: string }) | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const user = await collection.findOne<{
    id: string;
    email: string;
    password_hash: string;
    display_name: string | null;
    created_at: string;
  }>({ email });

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    password_hash: user.password_hash,
    display_name: user.display_name,
    created_at: user.created_at,
  };
}

export async function getUserById(id: string): Promise<UserRecord | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const user = await collection.findOne<{
    id: string;
    email: string;
    display_name: string | null;
    created_at: string;
  }>({ id });

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    display_name: user.display_name,
    created_at: user.created_at,
  };
}

export async function verifyPassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
  return bcrypt.compare(plainPassword, hashedPassword);
}
