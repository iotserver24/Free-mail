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
  direction: "inbound" | "outbound";
  subject: string;
  preview_text?: string | null;
  body_plain?: string | null;
  body_html?: string | null;
  status: "queued" | "sent" | "failed" | "received";
  created_at: string;
  attachments?: Attachment[];
}

export interface SendMessagePayload {
  from: string; // Email address to send from
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  html?: string;
  text?: string;
  attachments?: {
    filename: string;
    contentBase64: string;
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

export const mailApi = {
  listMessages: () => apiFetch<Message[]>("/api/messages"),
  getMessage: (id: string) => apiFetch<Message>(`/api/messages/${id}`),
  sendMessage: (payload: SendMessagePayload) =>
    apiFetch<Message>("/api/messages", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
};

