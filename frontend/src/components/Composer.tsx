import { useEffect, useMemo, useState } from "react";
import type { FormEvent } from "react";
import type { SendMessagePayload, Email } from "../lib/api";

interface ComposerProps {
  emails?: Email[];
  onSend(payload: SendMessagePayload): Promise<void>;
  sending: boolean;
  error?: string | null;
  pulseSignal?: number;
}

interface LocalAttachment {
  id: string;
  filename: string;
  contentBase64: string;
  contentType: string;
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

export function Composer({ emails = [], onSend, sending, error, pulseSignal }: ComposerProps) {
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [cc, setCc] = useState("");
  const [bcc, setBcc] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [attachments, setAttachments] = useState<LocalAttachment[]>([]);
  const [highlight, setHighlight] = useState(false);

  const isValid = useMemo(() => from.trim().length > 0 && to.trim().length > 0 && subject.trim().length > 0, [from, to, subject]);

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

    const results = await Promise.all(
      Array.from(files).map(
        (file) =>
          new Promise<LocalAttachment>((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
              const base64 = (reader.result as string).split(",")[1];
              resolve({
                id: typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`,
                filename: file.name,
                contentBase64: base64,
                contentType: file.type || "application/octet-stream",
              });
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
          })
      )
    );

    setAttachments((prev) => [...prev, ...results]);
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

    await onSend({
      from: from.trim(),
      to: toList,
      cc: ccList.length ? ccList : undefined,
      bcc: bccList.length ? bccList : undefined,
      subject,
      text: body,
      attachments: attachments.map(({ filename, contentBase64, contentType }) => ({
        filename,
        contentBase64,
        contentType,
      })),
    });

    setFrom("");
    setTo("");
    setSubject("");
    setBody("");
    setAttachments([]);
    setCc("");
    setBcc("");
  }

  return (
    <form id="composer-panel" className={`panel composer-panel ${highlight ? "composer-highlight" : ""}`} onSubmit={handleSubmit}>
      <div className="panel-header composer-header">
        <div>
          <h3>Compose</h3>
          <small>{isValid ? "Ready to ship" : "Fill out sender, recipients & subject"}</small>
        </div>
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
            📎 Attach
          </label>
          <input id="fileInput" type="file" multiple hidden onChange={handleFileChange} />
          <span>{attachments.length} attachment(s)</span>
        </div>
        {attachments.length > 0 && (
          <div className="attachments">
            {attachments.map((att) => (
              <div key={att.id} className="attachment-pill">
                <span>{att.filename}</span>
                <button type="button" onClick={() => handleRemoveAttachment(att.id)}>
                  ✕
                </button>
              </div>
            ))}
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

