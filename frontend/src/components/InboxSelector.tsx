import type { Inbox } from "../lib/api";

interface InboxSelectorProps {
  inboxes: Inbox[];
  selectedInboxId: string | null;
  onSelect: (inboxId: string | null) => void;
}

export function InboxSelector({ inboxes, selectedInboxId, onSelect }: InboxSelectorProps) {
  return (
    <div className="inbox-selector">
      <label>
        <span className="inbox-label">📧 Inbox:</span>
        <select
          value={selectedInboxId || "all"}
          onChange={(e) => onSelect(e.target.value === "all" ? null : e.target.value)}
          className="inbox-select"
          aria-label="Select inbox to filter messages"
        >
          <option value="all">📬 All Messages</option>
          {inboxes.length === 0 ? (
            <option value="none" disabled>No inboxes yet</option>
          ) : (
            inboxes.map((inbox) => (
              <option key={inbox.id} value={inbox.id}>
                {inbox.email || inbox.name}
              </option>
            ))
          )}
        </select>
      </label>
    </div>
  );
}


