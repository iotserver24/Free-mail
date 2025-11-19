import { pool } from "../db";
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
  const id = uuid();
  const result = await pool.query<MessageRecord>(
    `
      insert into messages (id, user_id, direction, subject, preview_text, body_plain, body_html, status)
      values ($1, $2, $3, $4, $5, $6, $7, $8)
      returning *
    `,
    [id, input.userId, input.direction, input.subject, input.previewText ?? null, input.bodyPlain ?? null, input.bodyHtml ?? null, input.status]
  );
  const record = result.rows[0];
  if (!record) {
    throw new Error("Failed to insert message");
  }
  return record;
}

export async function listMessages(userId: string, limit = 25): Promise<MessageRecord[]> {
  const result = await pool.query<MessageRecord>(
    `
      select *
      from messages
      where user_id = $1
      order by created_at desc
      limit $2
    `,
    [userId, limit]
  );
  return result.rows;
}

export async function getMessageById(userId: string, messageId: string): Promise<MessageRecord | null> {
  const result = await pool.query<MessageRecord>(
    `
      select *
      from messages
      where user_id = $1
        and id = $2
      limit 1
    `,
    [userId, messageId]
  );
  return result.rows[0] ?? null;
}

interface AttachmentInput {
  messageId: string;
  filename: string;
  mimetype: string;
  size: number;
  url: string;
}

export async function addAttachment(input: AttachmentInput): Promise<AttachmentRecord> {
  const id = uuid();
  const result = await pool.query<AttachmentRecord>(
    `
      insert into attachments (id, message_id, filename, mimetype, size_bytes, url)
      values ($1, $2, $3, $4, $5, $6)
      returning *
    `,
    [id, input.messageId, input.filename, input.mimetype, input.size, input.url]
  );
  const record = result.rows[0];
  if (!record) {
    throw new Error("Failed to insert attachment");
  }
  return record;
}

export async function listAttachments(messageId: string): Promise<AttachmentRecord[]> {
  const result = await pool.query<AttachmentRecord>(
    `
      select *
      from attachments
      where message_id = $1
      order by created_at asc
    `,
    [messageId]
  );
  return result.rows;
}

