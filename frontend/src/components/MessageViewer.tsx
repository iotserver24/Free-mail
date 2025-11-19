import type { Message } from "../lib/api";

interface MessageViewerProps {
  message?: Message | null;
  isLoading: boolean;
}

export function MessageViewer({ message, isLoading }: MessageViewerProps) {
  if (isLoading) {
    return (
      <div className="panel message-viewer">
        <p>Loading message…</p>
      </div>
    );
  }

  if (!message) {
    return (
      <div className="panel message-viewer">
        <p>Select a message to preview it.</p>
      </div>
    );
  }

  return (
    <div className="panel">
      <div className="message-viewer">
        <h2>{message.subject}</h2>
        <div className="message-metadata">
          <span>Direction: {message.direction}</span>
          <span>Status: {message.status}</span>
          <span>Received: {new Date(message.created_at).toLocaleString()}</span>
        </div>

        <section className="message-body">
          {message.body_html ? (
            <div dangerouslySetInnerHTML={{ __html: message.body_html }} />
          ) : (
            <pre>{message.body_plain ?? "No body content"}</pre>
          )}
        </section>

        {message.attachments && message.attachments.length > 0 && (
          <section style={{ marginTop: "1rem" }}>
            <h4>Attachments</h4>
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

