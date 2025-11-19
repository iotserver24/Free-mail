import { getDb } from "../db";
import { MessageRecord, AttachmentRecord } from "../types";
import { v4 as uuid } from "uuid";

interface CreateMessageInput {
  userId: string;
  direction: MessageRecord["direction"];
  subject: string;
  previewText?: string | null;
  bodyPlain?: string | null;
  bodyHtml?: string | null;
  status: MessageRecord["status"];
}

export async function createMessage(input: CreateMessageInput): Promise<MessageRecord> {
  const db = await getDb();
  const collection = db.collection("messages");

  const message = {
    id: uuid(),
    user_id: input.userId,
    direction: input.direction,
    subject: input.subject,
    preview_text: input.previewText ?? null,
    body_plain: input.bodyPlain ?? null,
    body_html: input.bodyHtml ?? null,
    status: input.status,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  await collection.insertOne(message);

  return {
    id: message.id,
    user_id: message.user_id,
    direction: message.direction,
    subject: message.subject,
    preview_text: message.preview_text,
    body_plain: message.body_plain,
    body_html: message.body_html,
    status: message.status,
    created_at: message.created_at,
    updated_at: message.updated_at,
  };
}

export async function listMessages(userId: string, limit = 25): Promise<MessageRecord[]> {
  const db = await getDb();
  const collection = db.collection("messages");

  const messages = await collection
    .find<{
      id: string;
      user_id: string;
      direction: string;
      subject: string;
      preview_text: string | null;
      body_plain: string | null;
      body_html: string | null;
      status: string;
      created_at: string;
      updated_at: string;
    }>({ user_id: userId })
    .sort({ created_at: -1 })
    .limit(limit)
    .toArray();

  return messages.map((msg: {
    id: string;
    user_id: string;
    direction: string;
    subject: string;
    preview_text: string | null;
    body_plain: string | null;
    body_html: string | null;
    status: string;
    created_at: string;
    updated_at: string;
  }) => ({
    id: msg.id,
    user_id: msg.user_id,
    direction: msg.direction as MessageRecord["direction"],
    subject: msg.subject,
    preview_text: msg.preview_text,
    body_plain: msg.body_plain,
    body_html: msg.body_html,
    status: msg.status as MessageRecord["status"],
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
    direction: string;
    subject: string;
    preview_text: string | null;
    body_plain: string | null;
    body_html: string | null;
    status: string;
    created_at: string;
    updated_at: string;
  }>({ id: messageId, user_id: userId });

  if (!message) {
    return null;
  }

  return {
    id: message.id,
    user_id: message.user_id,
    direction: message.direction as MessageRecord["direction"],
    subject: message.subject,
    preview_text: message.preview_text,
    body_plain: message.body_plain,
    body_html: message.body_html,
    status: message.status as MessageRecord["status"],
    created_at: message.created_at,
    updated_at: message.updated_at,
  };
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
