import type { Message } from "../lib/api";

interface MessageViewerProps {
  message?: Message | null;
  isLoading: boolean;
  refetching?: boolean;
  onReply?: (message: Message) => void;
  onForward?: (message: Message) => void;
}

const STATUS_PATH: Array<Message["status"]> = ["queued", "sent", "received", "failed"];

export function MessageViewer({ message, isLoading, refetching, onReply, onForward }: MessageViewerProps) {
  if (isLoading) {
    return (
      <div className="panel message-panel">
        <div className="message-viewer">
          <div className="message-state loading-state">
            <div className="skeleton subject-skeleton" />
            <div className="skeleton meta-skeleton" />
            <div className="skeleton body-skeleton" />
          </div>
        </div>
      </div>
    );
  }

  if (!message) {
    return (
      <div className="panel message-panel">
        <div className="message-viewer">
          <div className="message-state empty-state">
            <p>Awaiting selection</p>
            <span>Select any email from the left to unlock a detailed preview.</span>
          </div>
        </div>
      </div>
    );
  }

  const timelineIndexRaw = STATUS_PATH.indexOf(message.status);
  const timelineIndex = timelineIndexRaw === -1 ? STATUS_PATH.length - 1 : timelineIndexRaw;

  const formatDate = (value?: string | Date | null) => {
    if (!value) return "Unknown date";
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) return "Unknown date";
    return new Intl.DateTimeFormat(undefined, {
      weekday: "short",
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  };

  return (
    <div className="panel message-panel">
      <div className="panel-header viewer-header">
        <div className="viewer-header-content">
          <h2>{message.subject || "(No subject)"}</h2>
          <div className="viewer-meta-info">
            <div className="viewer-from-to">
              <span className="viewer-label">From:</span>
              <span className="viewer-value">{message.sender_email || "Unknown"}</span>
            </div>
            <div className="viewer-from-to">
              <span className="viewer-label">To:</span>
              <span className="viewer-value">{message.recipient_emails?.join(", ") || "Unknown"}</span>
            </div>
            <div className="viewer-date">{formatDate(message.created_at)}</div>
          </div>
        </div>
        <div className="viewer-actions">
          {refetching && <span className="inline-indicator">Syncing…</span>}
          {message.direction === "inbound" && onReply && (
            <button type="button" className="btn btn-ghost" onClick={() => onReply(message)}>
              Reply
            </button>
          )}
          {onForward && (
            <button type="button" className="btn btn-ghost" onClick={() => onForward(message)}>
              Forward
            </button>
          )}
        </div>
      </div>
      <div className="message-viewer">
        <div className="message-metadata-grid">
          <article>
            <span>Direction</span>
            <strong className={`badge badge-${message.direction}`}>{message.direction}</strong>
          </article>
          <article>
            <span>Status</span>
            <strong className={`status-pill status-${message.status}`}>{message.status}</strong>
          </article>
          <article>
            <span>Received</span>
            <strong>{formatDate(message.created_at)}</strong>
          </article>
          <article>
            <span>Preview</span>
            <strong>{message.preview_text ?? "No preview available"}</strong>
          </article>
        </div>

        <div className="status-timeline">
          {STATUS_PATH.map((step, index) => {
            const isActive = timelineIndex === index;
            const isComplete = timelineIndex > index;
            return (
              <div key={step} className={`timeline-step ${isComplete ? "complete" : ""} ${isActive ? "active" : ""}`}>
                <div className="timeline-bullet" />
                <span className="timeline-label">{step}</span>
              </div>
            );
          })}
        </div>

        <section className="message-body rich-text">
          {message.body_html ? (
            <div dangerouslySetInnerHTML={{ __html: message.body_html }} />
          ) : (
            <pre>{message.body_plain ?? "No body content"}</pre>
          )}
        </section>

        {message.attachments && message.attachments.length > 0 && (
          <section className="message-attachments">
            <h3 className="attachments-title">Attachments</h3>
            <div className="attachments">
              {message.attachments.map((att) => (
                <a key={att.id} className="attachment-pill" href={att.url} target="_blank" rel="noreferrer">
                  {att.filename} ({Math.round(att.size_bytes / 1024)} KB)
                </a>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}

