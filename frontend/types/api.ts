export interface ApiUser {
  id: string;
  email: string;
  displayName: string;
  role: "admin" | "user";
}

export interface DomainRecord {
  id: string;
  domain: string;
  user_id: string;
  created_at: string;
}

export interface EmailRecord {
  id: string;
  email: string;
  domain: string;
  user_id: string;
  inbox_id: string;
  created_at: string;
}

export interface InboxRecord {
  id: string;
  email_id: string;
  user_id: string;
  name: string;
  created_at: string;
  email?: string | null;
}

export interface AttachmentRecord {
  id: string;
  message_id: string;
  filename: string;
  mimetype: string;
  size_bytes: number;
  url: string;
  created_at: string;
}

export interface MessageRecord {
  id: string;
  user_id: string;
  inbox_id: string | null;
  direction: "inbound" | "outbound";
  subject: string;
  sender_email: string | null;
  recipient_emails: string[];
  thread_id: string | null;
  preview_text: string | null;
  body_plain: string | null;
  body_html: string | null;
  status: "sent" | "queued" | "failed" | "received";
  created_at: string;
  updated_at: string;
  attachments?: AttachmentRecord[];
}

export interface ApiError {
  error: string;
  message?: string;
}

