export interface MessageRecord {
  id: string;
  user_id: string;
  inbox_id: string | null;
  direction: "inbound" | "outbound";
  subject: string;
  sender_email: string | null; // Email address of sender
  recipient_emails: string[]; // Array of recipient email addresses
  thread_id: string | null; // For grouping replies/forwards with original
  preview_text: string | null;
  body_plain: string | null;
  body_html: string | null;
  status: "queued" | "sent" | "failed" | "received";
  is_read: boolean;
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
  username: string;
  display_name: string | null;
  personal_email: string | null;
  permanent_domain: string | null;
  role: "admin" | "user";
  invite_token: string | null;
  invite_token_expires: string | null;
  avatar_url: string | null;
  created_at: string;
}

