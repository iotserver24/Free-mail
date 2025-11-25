import { getDb } from "../db";
import { v4 as uuid } from "uuid";

export interface EmailRecord {
  id: string;
  email: string;
  domain: string;
  user_id: string;
  inbox_id: string;
  created_at: string;
}

export interface CreateEmailInput {
  email: string;
  domain: string;
  userId: string;
  inboxId: string;
}

export async function createEmail(input: CreateEmailInput): Promise<EmailRecord> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(input.email)) {
    throw new Error("Invalid email format");
  }

  // Extract domain from email
  const emailDomain = input.email.split("@")[1];
  if (emailDomain !== input.domain) {
    throw new Error("Email domain does not match provided domain");
  }

  // Check if email already exists
  const existing = await collection.findOne({ email: input.email.toLowerCase() });
  if (existing) {
    throw new Error("Email address already exists");
  }

  const emailRecord = {
    id: uuid(),
    email: input.email.toLowerCase(),
    domain: input.domain.toLowerCase(),
    user_id: input.userId,
    inbox_id: input.inboxId,
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(emailRecord);

  return {
    id: emailRecord.id,
    email: emailRecord.email,
    domain: emailRecord.domain,
    user_id: emailRecord.user_id,
    inbox_id: emailRecord.inbox_id,
    created_at: emailRecord.created_at,
  };
}

export async function listEmails(userId: string): Promise<EmailRecord[]> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  const emails = await collection
    .find<{
      id: string;
      email: string;
      domain: string;
      user_id: string;
      inbox_id: string;
      created_at: string;
    }>({ user_id: userId })
    .sort({ created_at: -1 })
    .toArray();

  return emails.map((e) => ({
    id: e.id,
    email: e.email,
    domain: e.domain,
    user_id: e.user_id,
    inbox_id: e.inbox_id,
    created_at: e.created_at,
  }));
}

export async function getEmailByAddress(email: string): Promise<EmailRecord | null> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  const emailRecord = await collection.findOne<{
    id: string;
    email: string;
    domain: string;
    user_id: string;
    inbox_id: string;
    created_at: string;
  }>({ email: email.toLowerCase() });

  if (!emailRecord) {
    return null;
  }

  return {
    id: emailRecord.id,
    email: emailRecord.email,
    domain: emailRecord.domain,
    user_id: emailRecord.user_id,
    inbox_id: emailRecord.inbox_id,
    created_at: emailRecord.created_at,
  };
}

export async function getEmailById(userId: string, emailId: string): Promise<EmailRecord | null> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  const emailRecord = await collection.findOne<{
    id: string;
    email: string;
    domain: string;
    user_id: string;
    inbox_id: string;
    created_at: string;
  }>({ id: emailId, user_id: userId });

  if (!emailRecord) {
    return null;
  }

  return {
    id: emailRecord.id,
    email: emailRecord.email,
    domain: emailRecord.domain,
    user_id: emailRecord.user_id,
    inbox_id: emailRecord.inbox_id,
    created_at: emailRecord.created_at,
  };
}

export async function deleteEmail(userId: string, emailId: string): Promise<boolean> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  const result = await collection.deleteOne({ id: emailId, user_id: userId });
  return result.deletedCount > 0;
}

export async function deleteEmailAny(emailId: string): Promise<boolean> {
  const db = await getDb();
  const collection = db.collection("email_addresses");

  const result = await collection.deleteOne({ id: emailId });
  return result.deletedCount > 0;
}

