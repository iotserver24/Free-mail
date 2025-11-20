const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:4000";

export interface Attachment {
  id: string;
  message_id: string;
  filename: string;
  mimetype: string;
  size_bytes: number;
  url: string;
}

export interface Message {
  id: string;
  inbox_id?: string | null;
  direction: "inbound" | "outbound";
  subject: string;
  sender_email?: string | null;
  recipient_emails?: string[];
  thread_id?: string | null;
  preview_text?: string | null;
  body_plain?: string | null;
  body_html?: string | null;
  status: "queued" | "sent" | "failed" | "received";
  created_at: string;
  attachments?: Attachment[];
}

export interface Domain {
  id: string;
  domain: string;
  user_id: string;
  created_at: string;
}

export interface Email {
  id: string;
  email: string;
  domain: string;
  user_id: string;
  inbox_id: string;
  created_at: string;
}

export interface Inbox {
  id: string;
  email_id: string;
  user_id: string;
  name: string;
  created_at: string;
  email?: string | null;
}

export interface SendMessagePayload {
  from: string; // Email address to send from
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  html?: string;
  text?: string;
  threadId?: string | null; // For threading replies/forwards
  attachments?: {
    filename: string;
    url: string; // Catbox URL
    contentType: string;
  }[];
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: "Request failed" }));
    throw new Error(error.error || "Request failed");
  }

  return response.json() as Promise<T>;
}

/**
 * Upload a file directly to Catbox from the frontend
 * @param file The file to upload
 * @returns The Catbox URL of the uploaded file
 */
export async function uploadFileToCatbox(file: File): Promise<string> {
  const formData = new FormData();
  formData.append("reqtype", "fileupload");
  formData.append("fileToUpload", file);

  const response = await fetch("https://catbox.moe/user/api.php", {
    method: "POST",
    body: formData,
  });

  if (!response.ok) {
    throw new Error(`Catbox upload failed: ${response.statusText}`);
  }

  const url = await response.text();
  
  // Catbox returns the URL directly as text, or an error message
  if (url.startsWith("https://")) {
    return url.trim();
  }

  throw new Error(`Catbox upload failed: ${url}`);
}

export const mailApi = {
  // Messages
  listMessages: (inboxId?: string | null) => {
    const url = inboxId ? `/api/messages?inboxId=${inboxId}` : "/api/messages";
    return apiFetch<Message[]>(url);
  },
  getMessage: (id: string) => apiFetch<Message>(`/api/messages/${id}`),
  sendMessage: (payload: SendMessagePayload) =>
    apiFetch<Message>("/api/messages", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  
  // Domains
  listDomains: () => apiFetch<Domain[]>("/api/domains"),
  createDomain: (domain: string) =>
    apiFetch<Domain>("/api/domains", {
      method: "POST",
      body: JSON.stringify({ domain }),
    }),
  deleteDomain: (domainId: string) =>
    apiFetch<void>(`/api/domains/${domainId}`, {
      method: "DELETE",
    }),
  
  // Emails
  listEmails: () => apiFetch<Email[]>("/api/emails"),
  createEmail: (email: string, domain: string, inboxName?: string) =>
    apiFetch<Email>("/api/emails", {
      method: "POST",
      body: JSON.stringify({ email, domain, inboxName }),
    }),
  deleteEmail: (emailId: string) =>
    apiFetch<void>(`/api/emails/${emailId}`, {
      method: "DELETE",
    }),
  
  // Inboxes
  listInboxes: () => apiFetch<Inbox[]>("/api/inboxes"),
  createInbox: (emailId: string, name: string) =>
    apiFetch<Inbox>("/api/inboxes", {
      method: "POST",
      body: JSON.stringify({ emailId, name }),
    }),
  deleteInbox: (inboxId: string) =>
    apiFetch<void>(`/api/inboxes/${inboxId}`, {
      method: "DELETE",
    }),
};

