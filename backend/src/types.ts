export interface MessageRecord {
  id: string;
  user_id: string;
  direction: "inbound" | "outbound";
  subject: string;
  preview_text: string | null;
  body_plain: string | null;
  body_html: string | null;
  status: "queued" | "sent" | "failed" | "received";
  created_at: string;
  updated_at: string;
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

export interface UserRecord {
  id: string;
  email: string;
  display_name: string | null;
  created_at: string;
}

