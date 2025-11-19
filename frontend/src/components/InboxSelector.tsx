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
        <span>Inbox:</span>
        <select
          value={selectedInboxId || "all"}
          onChange={(e) => onSelect(e.target.value === "all" ? null : e.target.value)}
        >
          <option value="all">All Messages</option>
          {inboxes.map((inbox) => (
            <option key={inbox.id} value={inbox.id}>
              {inbox.name} {inbox.email && `(${inbox.email})`}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}


