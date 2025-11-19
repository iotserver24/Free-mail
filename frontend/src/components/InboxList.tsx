import { useMemo, useState } from "react";
import type { Message } from "../lib/api";

interface InboxListProps {
  messages?: Message[];
  loading: boolean;
  selectedId?: string;
  onSelect(messageId: string): void;
  onCompose(): void;
}

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  hour: "2-digit",
  minute: "2-digit",
});

export function InboxList({ messages = [], loading, selectedId, onSelect, onCompose }: InboxListProps) {
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    if (!query) return messages;
    const lowered = query.toLowerCase();
    return messages.filter(
      (msg) =>
        msg.subject.toLowerCase().includes(lowered) ||
        (msg.preview_text ?? "").toLowerCase().includes(lowered) ||
        msg.status.toLowerCase().includes(lowered)
    );
  }, [messages, query]);

  return (
    <div className="panel">
      <div className="panel-header">
        <div className="search-field">
          <span role="img" aria-label="search">
            🔍
          </span>
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search mail" />
        </div>
        <button className="btn btn-primary" onClick={onCompose}>
          Compose
        </button>
      </div>
      <div className="inbox-scroll">
        {loading && (
          <div className="message-row">
            <p>Loading messages…</p>
          </div>
        )}
        {!loading && filtered.length === 0 && (
          <div className="message-row">
            <p>No messages yet.</p>
          </div>
        )}
        {filtered.map((message) => (
          <button
            key={message.id}
            className={`message-row ${message.id === selectedId ? "active" : ""}`}
            onClick={() => onSelect(message.id)}
          >
            <h4>
              <span>{message.subject}</span>
              <span>{timeFormatter.format(new Date(message.created_at))}</span>
            </h4>
            <p>{message.preview_text ?? "No preview available"}</p>
            <div>
              <span className="pill">{message.status}</span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

