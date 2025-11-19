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

const statusFilters: Array<"all" | Message["status"]> = ["all", "queued", "sent", "received", "failed"];
const directionFilters: Array<"all" | Message["direction"]> = ["all", "inbound", "outbound"];

export function InboxList({ messages = [], loading, selectedId, onSelect, onCompose }: InboxListProps) {
  const [query, setQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<(typeof statusFilters)[number]>("all");
  const [directionFilter, setDirectionFilter] = useState<(typeof directionFilters)[number]>("all");

  const filtered = useMemo(() => {
    const lowered = query.toLowerCase();
    return messages.filter((msg) => {
      const matchesQuery =
        !lowered ||
        msg.subject.toLowerCase().includes(lowered) ||
        (msg.preview_text ?? "").toLowerCase().includes(lowered) ||
        msg.status.toLowerCase().includes(lowered);
      const matchesStatus = statusFilter === "all" || msg.status === statusFilter;
      const matchesDirection = directionFilter === "all" || msg.direction === directionFilter;
      return matchesQuery && matchesStatus && matchesDirection;
    });
  }, [messages, query, statusFilter, directionFilter]);

  return (
    <div className="panel panel-inbox">
      <div className="panel-header inbox-header">
        <div className="search-field">
          <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden focusable="false">
            <path d="M21 21l-4.35-4.35m1.52-4.89a6.41 6.41 0 11-12.82 0 6.41 6.41 0 0112.82 0z" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" />
          </svg>
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search mail" />
        </div>
        <button className="btn btn-primary" onClick={onCompose}>
          Compose
        </button>
      </div>
      <div className="filter-row">
        <div className="chip-group">
          {statusFilters.map((filter) => (
            <button
              key={filter}
              type="button"
              className={`chip ${statusFilter === filter ? "active" : ""}`}
              onClick={() => setStatusFilter(filter)}
            >
              {filter}
            </button>
          ))}
        </div>
        <div className="chip-group subtle">
          {directionFilters.map((filter) => (
            <button
              key={filter}
              type="button"
              className={`chip ${directionFilter === filter ? "active" : ""}`}
              onClick={() => setDirectionFilter(filter)}
            >
              {filter}
            </button>
          ))}
        </div>
      </div>
      <div className="inbox-scroll">
        {loading && (
          <div className="message-row">
            <p>Loading messages…</p>
          </div>
        )}
        {!loading && filtered.length === 0 && (
          <div className="message-row empty-copy">
            <p>No messages match those filters.</p>
          </div>
        )}
        {filtered.map((message) => (
          <button
            key={message.id}
            className={`message-row ${message.id === selectedId ? "active" : ""}`}
            onClick={() => onSelect(message.id)}
          >
            <div className="message-row-top">
              <h4>{message.subject}</h4>
              <time>{timeFormatter.format(new Date(message.created_at))}</time>
            </div>
            <p>{message.preview_text ?? "No preview available"}</p>
            <div className="message-meta">
              <span className={`badge badge-${message.direction}`}>{message.direction}</span>
              <span className={`status-pill status-${message.status}`}>{message.status}</span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

