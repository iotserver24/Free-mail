import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import type { SendMessagePayload, Email } from "../lib/api";
import { uploadFileToCatbox } from "../lib/api";

interface ComposerProps {
  emails?: Email[];
  onSend(payload: SendMessagePayload): Promise<void>;
  sending: boolean;
  error?: string | null;
  pulseSignal?: number;
  initialValues?: {
    to?: string;
    subject?: string;
    body?: string;
    replyTo?: string; // For reply, pre-fill the "from" field
    threadId?: string | null; // For threading
  };
  onClose?: () => void;
}

interface LocalAttachment {
  id: string;
  filename: string;
  file: File;
  url?: string; // Catbox URL after upload
  uploading?: boolean;
  error?: string;
}

const templates = [
  {
    label: "Status update",
    subject: "Weekly status update",
    body: "Hi team,\n\nHere is the latest status update:\n• Progress:\n• Blockers:\n• Next steps:\n\nThanks!",
  },
  {
    label: "Follow-up",
    subject: "Quick follow-up",
    body: "Hello,\n\nJust checking in to see if you had a chance to review my previous note.\n\nBest regards,",
  },
  {
    label: "Welcome",
    subject: "Welcome aboard!",
    body: "Hi there,\n\nThrilled to have you with us. Let me know if you need anything.\n\nCheers,",
  },
];

export function Composer({ emails = [], onSend, sending, error, pulseSignal, initialValues, onClose }: ComposerProps) {
  const [from, setFrom] = useState(initialValues?.replyTo || "");
  const [to, setTo] = useState(initialValues?.to || "");
  const [cc, setCc] = useState("");
  const [bcc, setBcc] = useState("");
  const [subject, setSubject] = useState(initialValues?.subject || "");
  const [body, setBody] = useState(initialValues?.body || "");
  const [threadId, setThreadId] = useState<string | null>(initialValues?.threadId || null);
  const [attachments, setAttachments] = useState<LocalAttachment[]>([]);
  const [highlight, setHighlight] = useState(false);

  // Update form when initialValues change
  useEffect(() => {
    if (initialValues) {
      if (initialValues.to) setTo(initialValues.to);
      if (initialValues.subject) setSubject(initialValues.subject);
      if (initialValues.body) setBody(initialValues.body);
      if (initialValues.replyTo) setFrom(initialValues.replyTo);
      if (initialValues.threadId !== undefined) setThreadId(initialValues.threadId);
    }
  }, [initialValues]);

  const isValid = useMemo(() => {
    const hasRequiredFields = from.trim().length > 0 && to.trim().length > 0 && subject.trim().length > 0;
    const allAttachmentsReady = attachments.every(att => att.url && !att.uploading && !att.error);
    return hasRequiredFields && allAttachmentsReady;
  }, [from, to, subject, attachments]);

  useEffect(() => {
    if (pulseSignal === undefined) return;
    setHighlight(true);
    const timeout = setTimeout(() => setHighlight(false), 1200);
    return () => clearTimeout(timeout);
  }, [pulseSignal]);

  const parseList = (value: string) =>
    value
      .split(",")
      .map((entry) => entry.trim())
      .filter(Boolean);

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const files = event.target.files;
    if (!files) return;

    // Check file size limit (25MB)
    const maxSize = 25 * 1024 * 1024; // 25MB in bytes
    const oversizedFiles = Array.from(files).filter(file => file.size > maxSize);
    if (oversizedFiles.length > 0) {
      alert(`Some files exceed the 25MB limit: ${oversizedFiles.map(f => f.name).join(", ")}`);
      event.target.value = "";
      return;
    }

    // Create attachment entries first (with uploading state)
    const newAttachments: LocalAttachment[] = Array.from(files).map((file) => ({
      id: typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`,
      filename: file.name,
      file,
      uploading: true,
    }));

    // Add to attachments list immediately (shows uploading state)
    setAttachments((prev) => [...prev, ...newAttachments]);

    // Upload files to Catbox
    try {
      const uploadResults = await Promise.all(
        Array.from(files).map(async (file, index) => {
          try {
            const url = await uploadFileToCatbox(file);
            return { index, url, error: null };
          } catch (error) {
            return { 
              index, 
              url: null, 
              error: error instanceof Error ? error.message : "Upload failed" 
            };
          }
        })
      );

      // Update attachments with URLs or errors
      setAttachments((prev) =>
        prev.map((att) => {
          const result = uploadResults.find((r) => 
            newAttachments[r.index]?.id === att.id
          );
          if (result) {
            return {
              ...att,
              url: result.url || undefined,
              uploading: false,
              error: result.error || undefined,
            };
          }
          return att;
        })
      );
    } catch (error) {
      console.error("Error uploading files:", error);
    }

    event.target.value = "";
  }

  function handleRemoveAttachment(id: string) {
    setAttachments((prev) => prev.filter((att) => att.id !== id));
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;

    const toList = parseList(to);
    const ccList = parseList(cc);
    const bccList = parseList(bcc);

    // Filter out attachments that failed to upload or are still uploading
    const validAttachments = attachments.filter(
      (att) => att.url && !att.uploading && !att.error
    );

    if (attachments.some(att => att.uploading)) {
      alert("Please wait for all files to finish uploading before sending.");
      return;
    }

    if (attachments.some(att => att.error)) {
      alert("Some files failed to upload. Please remove them or try again.");
      return;
    }

    await onSend({
      from: from.trim(),
      to: toList,
      cc: ccList.length ? ccList : undefined,
      bcc: bccList.length ? bccList : undefined,
      subject,
      text: body,
      threadId: threadId || undefined,
      attachments: validAttachments.length > 0 ? validAttachments.map(({ filename, url, file }) => ({
        filename,
        url: url!,
        contentType: file.type || "application/octet-stream",
      })) : undefined,
    });

    // Reset form (but keep initial values if provided)
    if (!initialValues) {
      setFrom("");
      setTo("");
      setSubject("");
      setBody("");
    } else {
      // Reset to initial values
      setTo(initialValues.to || "");
      setSubject(initialValues.subject || "");
      setBody(initialValues.body || "");
    }
    setAttachments([]);
    setCc("");
    setBcc("");
    
    // Scroll to composer and close if onClose provided
    if (onClose) {
      setTimeout(() => {
        document.getElementById("composer-panel")?.scrollIntoView({ behavior: "smooth", block: "center" });
        onClose();
      }, 100);
    }
  }

  return (
    <form id="composer-panel" className={`panel composer-panel ${highlight ? "composer-highlight" : ""}`} onSubmit={handleSubmit}>
      <div className="panel-header composer-header">
        <div>
          <h3>{initialValues ? (initialValues.to ? "Reply" : "Forward") : "Compose"}</h3>
          <small>{isValid ? "Ready to ship" : "Fill out sender, recipients & subject"}</small>
        </div>
        {initialValues && onClose && (
          <button type="button" className="btn btn-ghost" onClick={onClose}>
            Cancel
          </button>
        )}
        <div className="template-chips">
          {templates.map((template) => (
            <button type="button" key={template.label} className="chip" onClick={() => {
              setSubject(template.subject);
              setBody(template.body);
            }}>
              {template.label}
            </button>
          ))}
        </div>
      </div>
      <div className="composer">
        {error && <div className="error-banner">{error}</div>}
        <div className="composer-grid">
          <label>
            From
            {emails.length > 0 ? (
              <select
                value={from}
                onChange={(event) => setFrom(event.target.value)}
                required
              >
                <option value="">Select email address</option>
                {emails.map((email) => (
                  <option key={email.id} value={email.email}>
                    {email.email}
                  </option>
                ))}
              </select>
            ) : (
              <input 
                type="email" 
                placeholder="your-email@yourdomain.com" 
                value={from} 
                onChange={(event) => setFrom(event.target.value)} 
                required 
              />
            )}
          </label>
          <label>
            To
            <input placeholder="person@example.com, team@example.com" value={to} onChange={(event) => setTo(event.target.value)} />
          </label>
          <label>
            Cc
            <input placeholder="optional cc" value={cc} onChange={(event) => setCc(event.target.value)} />
          </label>
          <label>
            Bcc
            <input placeholder="optional bcc" value={bcc} onChange={(event) => setBcc(event.target.value)} />
          </label>
        </div>
        <label>
          Subject
          <input placeholder="Quarterly update" value={subject} onChange={(event) => setSubject(event.target.value)} />
        </label>
        <label>
          Message
          <textarea placeholder="Write your email…" value={body} onChange={(event) => setBody(event.target.value)} />
        </label>
        <div className="attachment-row">
          <label htmlFor="fileInput" className="btn btn-ghost attach-btn">
            📎 Attach (Max 25MB per file)
          </label>
          <input 
            id="fileInput" 
            type="file" 
            multiple 
            hidden 
            onChange={handleFileChange}
            accept="*/*"
          />
          <span>
            {attachments.length} attachment(s)
            {attachments.some(att => att.uploading) && " (Uploading...)"}
          </span>
        </div>
        {attachments.length > 0 && (
          <div className="attachments">
            {attachments.map((att) => {
              const fileSizeMB = (att.file.size / (1024 * 1024)).toFixed(2);
              return (
                <div key={att.id} className={`attachment-pill ${att.error ? "attachment-error" : ""} ${att.uploading ? "attachment-uploading" : ""}`}>
                  <span>
                    {att.filename} ({fileSizeMB} MB)
                    {att.uploading && " ⏳ Uploading..."}
                    {att.error && ` ❌ ${att.error}`}
                    {att.url && !att.uploading && !att.error && " ✓"}
                  </span>
                  <button type="button" onClick={() => handleRemoveAttachment(att.id)} disabled={att.uploading}>
                    ✕
                  </button>
                </div>
              );
            })}
          </div>
        )}
        <div className="composer-actions">
          <div className="composer-status">
            <span className={isValid ? "status-ready" : "status-pending"}>
              {isValid ? "Ready to deploy" : "Missing required fields"}
            </span>
          </div>
          <button className="btn btn-primary" type="submit" disabled={!isValid || sending}>
            {sending ? "Sending…" : "Send"}
          </button>
        </div>
      </div>
    </form>
  );
}

