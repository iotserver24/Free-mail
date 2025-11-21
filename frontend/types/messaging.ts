export interface AttachmentPayload {
  filename: string;
  url: string;
  contentType?: string;
}

export interface ComposePayload {
  from: string;
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  text?: string;
  html?: string;
  attachments?: AttachmentPayload[];
}

