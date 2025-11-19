import { useMemo, useState } from "react";
import type { FormEvent } from "react";
import type { SendMessagePayload } from "../lib/api";

interface ComposerProps {
  onSend(payload: SendMessagePayload): Promise<void>;
  sending: boolean;
  error?: string | null;
}

interface LocalAttachment {
  id: string;
  filename: string;
  contentBase64: string;
  contentType: string;
}

export function Composer({ onSend, sending, error }: ComposerProps) {
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [attachments, setAttachments] = useState<LocalAttachment[]>([]);

  const isValid = useMemo(() => from.trim().length > 0 && to.trim().length > 0 && subject.trim().length > 0, [from, to, subject]);

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

    await onSend({
      from: from.trim(),
      to: to.split(",").map((value) => value.trim()).filter(Boolean),
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
  }

  return (
    <form id="composer-panel" className="panel composer-panel" onSubmit={handleSubmit}>
      <div className="panel-header">
        <h3>Composer</h3>
        <small>{isValid ? "Ready to send" : "Fill in from, to, and subject"}</small>
      </div>
      <div className="composer">
        {error && <div className="error-banner">{error}</div>}
        <label>
          From
          <input type="email" placeholder="your-email@yourdomain.com" value={from} onChange={(event) => setFrom(event.target.value)} required />
        </label>
        <label>
          To
          <input placeholder="person@example.com, team@example.com" value={to} onChange={(event) => setTo(event.target.value)} />
        </label>
        <label>
          Subject
          <input placeholder="Quarterly update" value={subject} onChange={(event) => setSubject(event.target.value)} />
        </label>
        <label>
          Message
          <textarea placeholder="Write your email…" value={body} onChange={(event) => setBody(event.target.value)} />
        </label>
        <div>
          <label htmlFor="fileInput" className="btn btn-ghost" style={{ display: "inline-flex", alignItems: "center", gap: "0.35rem" }}>
            📎 Attach
          </label>
          <input id="fileInput" type="file" multiple hidden onChange={handleFileChange} />
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
          <span>{attachments.length} attachment(s)</span>
          <button className="btn btn-primary" type="submit" disabled={!isValid || sending}>
            {sending ? "Sending…" : "Send"}
          </button>
        </div>
      </div>
    </form>
  );
}

