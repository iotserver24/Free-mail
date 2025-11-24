import { getDb } from "../db";
import bcrypt from "bcryptjs";
import type { UserRecord } from "../types";
import { v4 as uuid } from "uuid";

export interface CreateUserInput {
  email: string;
  username: string;
  password?: string;
  displayName?: string;
  personalEmail?: string;
  permanentDomain?: string;
  role?: "admin" | "user";
  inviteToken?: string;
  inviteTokenExpires?: string;
}

export async function createUser(input: CreateUserInput): Promise<UserRecord> {
  const passwordHash = input.password ? await bcrypt.hash(input.password, 10) : "";
  const db = await getDb();
  const collection = db.collection("users");

  const user = {
    id: uuid(),
    email: input.email,
    username: input.username,
    password_hash: passwordHash,
    display_name: input.displayName ?? null,
    personal_email: input.personalEmail ?? null,
    permanent_domain: input.permanentDomain ?? null,
    role: input.role ?? "user",
    invite_token: input.inviteToken ?? null,
    invite_token_expires: input.inviteTokenExpires ?? null,
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(user);

  return {
    id: user.id,
    email: user.email,
    username: user.username,
    display_name: user.display_name,
    personal_email: user.personal_email,
    permanent_domain: user.permanent_domain,
    role: user.role as "admin" | "user",
    invite_token: user.invite_token,
    invite_token_expires: user.invite_token_expires,
    created_at: user.created_at,
  };
}

export async function updateUser(id: string, updates: Partial<UserRecord> & { password?: string }): Promise<UserRecord | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const updateDoc: any = { ...updates };
  if (updates.password) {
    updateDoc.password_hash = await bcrypt.hash(updates.password, 10);
    delete updateDoc.password;
  }

  const result = await collection.findOneAndUpdate(
    { id },
    { $set: updateDoc },
    { returnDocument: "after" }
  );

  if (!result) {
    return null;
  }

  return {
    id: result.id,
    email: result.email,
    username: result.username,
    display_name: result.display_name,
    personal_email: result.personal_email,
    permanent_domain: result.permanent_domain,
    role: result.role,
    invite_token: result.invite_token,
    invite_token_expires: result.invite_token_expires,
    created_at: result.created_at,
  };
}

export async function getUserByEmail(email: string): Promise<(UserRecord & { password_hash: string }) | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const user = await collection.findOne<{
    id: string;
    email: string;
    username: string;
    password_hash: string;
    display_name: string | null;
    personal_email: string | null;
    permanent_domain: string | null;
    role: "admin" | "user";
    invite_token: string | null;
    invite_token_expires: string | null;
    created_at: string;
  }>({ email });

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    username: user.username,
    password_hash: user.password_hash,
    display_name: user.display_name,
    personal_email: user.personal_email,
    permanent_domain: user.permanent_domain,
    role: user.role,
    invite_token: user.invite_token,
    invite_token_expires: user.invite_token_expires,
    created_at: user.created_at,
  };
}

export async function getUserById(id: string): Promise<UserRecord | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const user = await collection.findOne<{
    id: string;
    email: string;
    username: string;
    display_name: string | null;
    personal_email: string | null;
    permanent_domain: string | null;
    role: "admin" | "user";
    invite_token: string | null;
    invite_token_expires: string | null;
    created_at: string;
  }>({ id });

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    username: user.username,
    display_name: user.display_name,
    personal_email: user.personal_email,
    permanent_domain: user.permanent_domain,
    role: user.role,
    invite_token: user.invite_token,
    invite_token_expires: user.invite_token_expires,
    created_at: user.created_at,
  };
}

export async function getUserByInviteToken(token: string): Promise<UserRecord | null> {
  const db = await getDb();
  const collection = db.collection("users");

  const user = await collection.findOne<{
    id: string;
    email: string;
    username: string;
    display_name: string | null;
    personal_email: string | null;
    permanent_domain: string | null;
    role: "admin" | "user";
    invite_token: string | null;
    invite_token_expires: string | null;
    created_at: string;
  }>({ invite_token: token });

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    email: user.email,
    username: user.username,
    display_name: user.display_name,
    personal_email: user.personal_email,
    permanent_domain: user.permanent_domain,
    role: user.role,
    invite_token: user.invite_token,
    invite_token_expires: user.invite_token_expires,
    created_at: user.created_at,
  };
}

export async function verifyPassword(plainPassword: string, hashedPassword: string): Promise<boolean> {
  if (!hashedPassword) return false;
  return bcrypt.compare(plainPassword, hashedPassword);
}
