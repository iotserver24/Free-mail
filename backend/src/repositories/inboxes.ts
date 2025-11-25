import { getDb } from "../db";
import { v4 as uuid } from "uuid";

export interface InboxRecord {
  id: string;
  email_id: string;
  user_id: string;
  name: string;
  created_at: string;
}

export interface CreateInboxInput {
  id?: string;
  emailId: string;
  userId: string;
  name: string;
}

export async function createInbox(input: CreateInboxInput): Promise<InboxRecord> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const inbox = {
    id: input.id || uuid(),
    email_id: input.emailId,
    user_id: input.userId,
    name: input.name.trim(),
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(inbox);

  return {
    id: inbox.id,
    email_id: inbox.email_id,
    user_id: inbox.user_id,
    name: inbox.name,
    created_at: inbox.created_at,
  };
}

export async function listInboxes(userId: string): Promise<InboxRecord[]> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const inboxes = await collection
    .find<{
      id: string;
      email_id: string;
      user_id: string;
      name: string;
      created_at: string;
    }>({ user_id: userId })
    .sort({ created_at: -1 })
    .toArray();

  return inboxes.map((i) => ({
    id: i.id,
    email_id: i.email_id,
    user_id: i.user_id,
    name: i.name,
    created_at: i.created_at,
  }));
}

export async function getInboxById(userId: string, inboxId: string): Promise<InboxRecord | null> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const inbox = await collection.findOne<{
    id: string;
    email_id: string;
    user_id: string;
    name: string;
    created_at: string;
  }>({ id: inboxId, user_id: userId });

  if (!inbox) {
    return null;
  }

  return {
    id: inbox.id,
    email_id: inbox.email_id,
    user_id: inbox.user_id,
    name: inbox.name,
    created_at: inbox.created_at,
  };
}

export async function getInboxByEmailId(userId: string, emailId: string): Promise<InboxRecord | null> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const inbox = await collection.findOne<{
    id: string;
    email_id: string;
    user_id: string;
    name: string;
    created_at: string;
  }>({ email_id: emailId, user_id: userId });

  if (!inbox) {
    return null;
  }

  return {
    id: inbox.id,
    email_id: inbox.email_id,
    user_id: inbox.user_id,
    name: inbox.name,
    created_at: inbox.created_at,
  };
}

export async function deleteInbox(userId: string, inboxId: string): Promise<boolean> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const result = await collection.deleteOne({ id: inboxId, user_id: userId });
  return result.deletedCount > 0;
}

export async function deleteInboxAny(inboxId: string): Promise<boolean> {
  const db = await getDb();
  const collection = db.collection("inboxes");

  const result = await collection.deleteOne({ id: inboxId });
  return result.deletedCount > 0;
}

