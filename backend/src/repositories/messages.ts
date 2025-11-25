import { getDb } from "../db";
import { MessageRecord, AttachmentRecord } from "../types";
import { v4 as uuid } from "uuid";

/**
 * Normalize subject for threading (remove Re:/Fwd: prefixes)
 */
function normalizeSubject(subject: string): string {
  return subject
    .replace(/^(Re:|RE:|re:|Fwd:|FWD:|fwd:|Fw:|FW:|fw:)\s*/i, "")
    .replace(/^\[.*?\]\s*/, "")
    .trim();
}

/**
 * Generate or find thread ID for a message
 */
async function getOrCreateThreadId(
  userId: string,
  inboxId: string | null,
  subject: string,
  existingThreadId?: string | null
): Promise<string | null> {
  if (existingThreadId) {
    return existingThreadId;
  }

  const normalizedSubject = normalizeSubject(subject);
  if (!normalizedSubject) {
    return null;
  }

  const db = await getDb();
  const collection = db.collection("messages");

  // Find existing thread with same normalized subject in same inbox
  const existingMessage = await collection.findOne<{ thread_id: string | null }>(
    {
      user_id: userId,
      inbox_id: inboxId,
      $or: [
        { subject: { $regex: new RegExp(`^Re:\\s*${normalizedSubject.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
        { subject: { $regex: new RegExp(`^Fwd:\\s*${normalizedSubject.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
        { subject: normalizedSubject },
      ],
      thread_id: { $ne: null },
    },
    { sort: { created_at: 1 } }
  );

  if (existingMessage?.thread_id) {
    return existingMessage.thread_id;
  }

  // Check if this subject already exists (case-insensitive)
  const existingWithSubject = await collection.findOne<{ id: string; thread_id: string | null }>(
    {
      user_id: userId,
      inbox_id: inboxId,
      $or: [
        { subject: { $regex: new RegExp(`^Re:\\s*${normalizedSubject.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
        { subject: { $regex: new RegExp(`^Fwd:\\s*${normalizedSubject.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
        { subject: normalizedSubject },
      ],
    },
    { sort: { created_at: 1 } }
  );

  if (existingWithSubject) {
    // Use the first message's ID as thread ID
    return existingWithSubject.thread_id || existingWithSubject.id;
  }

  // No existing thread, return null (will be set to message ID after creation)
  return null;
}

interface CreateMessageInput {
  userId: string;
  inboxId?: string | null;
  direction: MessageRecord["direction"];
  subject: string;
  senderEmail?: string | null;
  recipientEmails?: string[];
  threadId?: string | null;
  previewText?: string | null;
  bodyPlain?: string | null;
  bodyHtml?: string | null;
  status: MessageRecord["status"];
}

export async function createMessage(input: CreateMessageInput): Promise<MessageRecord> {
  const db = await getDb();
  const collection = db.collection("messages");

  // Get or create thread ID for threading
  const threadId = await getOrCreateThreadId(
    input.userId,
    input.inboxId ?? null,
    input.subject,
    input.threadId
  );

  const messageId = uuid();
  // If no existing thread, use this message's ID as thread ID
  const finalThreadId = threadId || messageId;

  const message = {
    id: messageId,
    user_id: input.userId,
    inbox_id: input.inboxId ?? null,
    direction: input.direction,
    subject: input.subject,
    sender_email: input.senderEmail ?? null,
    recipient_emails: input.recipientEmails ?? [],
    thread_id: finalThreadId,
    preview_text: input.previewText ?? null,
    body_plain: input.bodyPlain ?? null,
    body_html: input.bodyHtml ?? null,
    status: input.status,
    is_read: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  await collection.insertOne(message);

  return {
    id: message.id,
    user_id: message.user_id,
    inbox_id: message.inbox_id,
    direction: message.direction,
    subject: message.subject,
    sender_email: message.sender_email,
    recipient_emails: message.recipient_emails,
    thread_id: message.thread_id,
    preview_text: message.preview_text,
    body_plain: message.body_plain,
    body_html: message.body_html,
    status: message.status,
    is_read: message.is_read,
    created_at: message.created_at,
    updated_at: message.updated_at,
  };
}

export async function listMessages(userId: string, inboxId?: string | null, limit = 25): Promise<MessageRecord[]> {
  const db = await getDb();
  const collection = db.collection("messages");

  const query: { user_id: string; inbox_id?: string | null } = { user_id: userId };
  if (inboxId !== undefined) {
    query.inbox_id = inboxId;
  }

  const messages = await collection
    .find<{
      id: string;
      user_id: string;
      inbox_id: string | null;
      direction: string;
      subject: string;
      sender_email: string | null;
      recipient_emails: string[];
      thread_id: string | null;
      preview_text: string | null;
      body_plain: string | null;
      body_html: string | null;
      status: string;
      is_read: boolean;
      created_at: string;
      updated_at: string;
    }>(query)
    .sort({ created_at: -1 })
    .limit(limit)
    .toArray();

  return messages.map((msg: {
    id: string;
    user_id: string;
    inbox_id: string | null;
    direction: string;
    subject: string;
    sender_email: string | null;
    recipient_emails: string[];
    thread_id: string | null;
    preview_text: string | null;
    body_plain: string | null;
    body_html: string | null;
    status: string;
    is_read: boolean;
    created_at: string;
    updated_at: string;
  }) => ({
    id: msg.id,
    user_id: msg.user_id,
    inbox_id: msg.inbox_id,
    direction: msg.direction as MessageRecord["direction"],
    subject: msg.subject,
    sender_email: msg.sender_email,
    recipient_emails: msg.recipient_emails,
    thread_id: msg.thread_id,
    preview_text: msg.preview_text,
    body_plain: msg.body_plain,
    body_html: msg.body_html,
    status: msg.status as MessageRecord["status"],
    is_read: msg.is_read || false,
    created_at: msg.created_at,
    updated_at: msg.updated_at,
  }));
}

export async function getMessageById(userId: string, messageId: string): Promise<MessageRecord | null> {
  const db = await getDb();
  const collection = db.collection("messages");

  const message = await collection.findOne<{
    id: string;
    user_id: string;
    inbox_id: string | null;
    direction: string;
    subject: string;
    sender_email: string | null;
    recipient_emails: string[];
    thread_id: string | null;
    preview_text: string | null;
    body_plain: string | null;
    body_html: string | null;
    status: string;
    is_read: boolean;
    created_at: string;
    updated_at: string;
  }>({ id: messageId, user_id: userId });

  if (!message) {
    return null;
  }

  return {
    id: message.id,
    user_id: message.user_id,
    inbox_id: message.inbox_id,
    direction: message.direction as MessageRecord["direction"],
    subject: message.subject,
    sender_email: message.sender_email,
    recipient_emails: message.recipient_emails,
    thread_id: message.thread_id,
    preview_text: message.preview_text,
    body_plain: message.body_plain,
    body_html: message.body_html,
    status: message.status as MessageRecord["status"],
    is_read: message.is_read || false,
    created_at: message.created_at,
    updated_at: message.updated_at,
  };
}

export async function getThreadMessages(userId: string, threadId: string): Promise<MessageRecord[]> {
  const db = await getDb();
  const collection = db.collection("messages");

  const messages = await collection
    .find<{
      id: string;
      user_id: string;
      inbox_id: string | null;
      direction: string;
      subject: string;
      sender_email: string | null;
      recipient_emails: string[];
      thread_id: string | null;
      preview_text: string | null;
      body_plain: string | null;
      body_html: string | null;
      status: string;
      is_read: boolean;
      created_at: string;
      updated_at: string;
    }>({
      user_id: userId,
      thread_id: threadId,
    })
    .sort({ created_at: 1 })
    .toArray();

  return messages.map((msg) => ({
    id: msg.id,
    user_id: msg.user_id,
    inbox_id: msg.inbox_id,
    direction: msg.direction as MessageRecord["direction"],
    subject: msg.subject,
    sender_email: msg.sender_email,
    recipient_emails: msg.recipient_emails,
    thread_id: msg.thread_id,
    preview_text: msg.preview_text,
    body_plain: msg.body_plain,
    body_html: msg.body_html,
    status: msg.status as MessageRecord["status"],
    is_read: msg.is_read || false,
    created_at: msg.created_at,
    updated_at: msg.updated_at,
  }));
}

interface AttachmentInput {
  messageId: string;
  filename: string;
  mimetype: string;
  size: number;
  url: string;
}

export async function addAttachment(input: AttachmentInput): Promise<AttachmentRecord> {
  const db = await getDb();
  const collection = db.collection("attachments");

  const attachment = {
    id: uuid(),
    message_id: input.messageId,
    filename: input.filename,
    mimetype: input.mimetype,
    size_bytes: input.size,
    url: input.url,
    created_at: new Date().toISOString(),
  };

  await collection.insertOne(attachment);

  return {
    id: attachment.id,
    message_id: attachment.message_id,
    filename: attachment.filename,
    mimetype: attachment.mimetype,
    size_bytes: attachment.size_bytes,
    url: attachment.url,
    created_at: attachment.created_at,
  };
}

export async function listAttachments(messageId: string): Promise<AttachmentRecord[]> {
  const db = await getDb();
  const collection = db.collection("attachments");

  const attachments = await collection
    .find<{
      id: string;
      message_id: string;
      filename: string;
      mimetype: string;
      size_bytes: number;
      url: string;
      created_at: string;
    }>({ message_id: messageId })
    .sort({ created_at: 1 })
    .toArray();

  return attachments.map((att: {
    id: string;
    message_id: string;
    filename: string;
    mimetype: string;
    size_bytes: number;
    url: string;
    created_at: string;
  }) => ({
    id: att.id,
    message_id: att.message_id,
    filename: att.filename,
    mimetype: att.mimetype,
    size_bytes: att.size_bytes,
    url: att.url,
    created_at: att.created_at,
  }));
}

export async function updateMessage(
  userId: string,
  messageId: string,
  updates: Partial<MessageRecord>
): Promise<MessageRecord | null> {
  const db = await getDb();
  const collection = db.collection("messages");

  const allowedUpdates: Partial<MessageRecord> = {};
  if (updates.is_read !== undefined) allowedUpdates.is_read = updates.is_read;
  // Add other allowed updates here if needed

  if (Object.keys(allowedUpdates).length === 0) {
    return getMessageById(userId, messageId);
  }

  allowedUpdates.updated_at = new Date().toISOString();

  const result = await collection.findOneAndUpdate(
    { id: messageId, user_id: userId },
    { $set: allowedUpdates },
    { returnDocument: "after" }
  );

  if (!result) {
    return null;
  }

  const message = result as unknown as {
    id: string;
    user_id: string;
    inbox_id: string | null;
    direction: string;
    subject: string;
    sender_email: string | null;
    recipient_emails: string[];
    thread_id: string | null;
    preview_text: string | null;
    body_plain: string | null;
    body_html: string | null;
    status: string;
    is_read: boolean;
    created_at: string;
    updated_at: string;
  };

  return {
    id: message.id,
    user_id: message.user_id,
    inbox_id: message.inbox_id,
    direction: message.direction as MessageRecord["direction"],
    subject: message.subject,
    sender_email: message.sender_email,
    recipient_emails: message.recipient_emails,
    thread_id: message.thread_id,
    preview_text: message.preview_text,
    body_plain: message.body_plain,
    body_html: message.body_html,
    status: message.status as MessageRecord["status"],
    is_read: message.is_read || false,
    created_at: message.created_at,
    updated_at: message.updated_at,
  };
}
