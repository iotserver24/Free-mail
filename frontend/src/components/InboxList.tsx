import { useMemo, useState } from "react";
import type { Message } from "../lib/api";

interface InboxListProps {
  messages?: Message[];
  loading: boolean;
  selectedId?: string;
  onSelect(message: Message): void;
  searchQuery?: string;
}

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  hour: "2-digit",
  minute: "2-digit",
});

const statusFilters: Array<"all" | Message["status"]> = ["all", "queued", "sent", "received", "failed"];
const directionFilters: Array<"all" | Message["direction"]> = ["all", "inbound", "outbound"];

interface ThreadGroup {
  threadId: string | null;
  messages: Message[];
  latestMessage: Message;
}

export function InboxList(props: InboxListProps) {
  const { messages = [], loading, selectedId, onSelect, searchQuery = "" } = props;
  const [statusFilter, setStatusFilter] = useState<(typeof statusFilters)[number]>("all");
  const [directionFilter, setDirectionFilter] = useState<(typeof directionFilters)[number]>("all");

  // Group messages by thread_id (like Gmail)
  const threadedMessages = useMemo(() => {
    // First filter messages
    const lowered = searchQuery.toLowerCase();
    const filtered = messages.filter((msg) => {
      const matchesQuery =
        !lowered ||
        msg.subject.toLowerCase().includes(lowered) ||
        (msg.preview_text ?? "").toLowerCase().includes(lowered) ||
        (msg.sender_email ?? "").toLowerCase().includes(lowered) ||
        msg.status.toLowerCase().includes(lowered);
      const matchesStatus = statusFilter === "all" || msg.status === statusFilter;
      const matchesDirection = directionFilter === "all" || msg.direction === directionFilter;
      return matchesQuery && matchesStatus && matchesDirection;
    });

    // Group by thread_id
    const threadMap = new Map<string | null, Message[]>();
    
    filtered.forEach((msg) => {
      const threadId = msg.thread_id || msg.id; // Use message ID if no thread_id
      if (!threadMap.has(threadId)) {
        threadMap.set(threadId, []);
      }
      threadMap.get(threadId)!.push(msg);
    });

    // Convert to array and sort by latest message date
    const threads: ThreadGroup[] = Array.from(threadMap.entries()).map(([threadId, msgs]) => {
      const sorted = [...msgs].sort((a, b) => 
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      );
      return {
        threadId,
        messages: sorted,
        latestMessage: sorted[0],
      };
    });

    // Sort threads by latest message date
    return threads.sort((a, b) => 
      new Date(b.latestMessage.created_at).getTime() - new Date(a.latestMessage.created_at).getTime()
    );
  }, [messages, searchQuery, statusFilter, directionFilter]);

  const formatDate = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    
    if (days === 0) {
      return timeFormatter.format(date);
    } else if (days === 1) {
      return "Yesterday";
    } else if (days < 7) {
      return date.toLocaleDateString(undefined, { weekday: "short" });
    } else {
      return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
    }
  };

  return (
    <div className="panel panel-inbox">
      <div className="panel-header inbox-header">
        <div className="inbox-toolbar">
          <button className="gmail-checkbox-btn" aria-label="Select">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M19 5v14H5V5h14m0-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"/>
            </svg>
          </button>
          <button className="gmail-icon-btn-small" aria-label="Refresh">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/>
            </svg>
          </button>
          <button className="gmail-icon-btn-small" aria-label="More">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/>
            </svg>
          </button>
        </div>
        <div className="inbox-pagination">
          <span className="inbox-count">
            {threadedMessages.length > 0 
              ? `1-${Math.min(50, threadedMessages.length)} of ${threadedMessages.length}`
              : "0"
            }
          </span>
        </div>
      </div>
      <div className="filter-row">
        <div className="chip-group">
          <button
            type="button"
            className={`chip ${statusFilter === "all" && directionFilter === "all" ? "active" : ""}`}
            onClick={() => {
              setStatusFilter("all");
              setDirectionFilter("all");
            }}
          >
            Primary
          </button>
          {statusFilters.filter(f => f !== "all").map((filter) => (
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
          {directionFilters.filter(f => f !== "all").map((filter) => (
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
          <div className="message-row empty-copy">
            <p>Loading messages…</p>
          </div>
        )}
        {!loading && threadedMessages.length === 0 && (
          <div className="message-row empty-copy">
            <p>No messages match those filters.</p>
          </div>
        )}
        {threadedMessages.map((thread) => {
          const message = thread.latestMessage;
          const threadCount = thread.messages.length;
          const isSelected = thread.messages.some(m => m.id === selectedId);
          const messageDate = new Date(message.created_at);
          
          return (
            <button
              key={thread.threadId || message.id}
              className={`message-row ${isSelected ? "active" : ""} ${threadCount > 1 ? "threaded" : ""}`}
              onClick={() => onSelect(message)}
            >
              <div className="message-row-checkbox">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M19 5v14H5V5h14m0-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"/>
                </svg>
              </div>
              <div className="message-row-star">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4l-3.76 2.27 1-4.28-3.32-2.88 4.38-.38L12 6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"/>
                </svg>
              </div>
              <div className="message-row-content">
                <div className="message-row-top">
                  <div className="message-sender">
                    {message.direction === "inbound" 
                      ? message.sender_email || "Unknown"
                      : message.recipient_emails?.join(", ") || "Unknown"
                    }
                  </div>
                  <time>{formatDate(messageDate)}</time>
                </div>
                <div className="message-row-subject">
                  <h4>
                    {message.subject || "(No subject)"}
                    {threadCount > 1 && (
                      <span className="thread-count">({threadCount})</span>
                    )}
                  </h4>
                </div>
                <p>{message.preview_text ?? "No preview available"}</p>
                <div className="message-meta">
                  <span className={`badge badge-${message.direction}`}>{message.direction}</span>
                  <span className={`status-pill status-${message.status}`}>{message.status}</span>
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

