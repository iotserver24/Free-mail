import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { mailApi } from "../lib/api";
import type { Email, Domain } from "../lib/api";

interface EmailManagerProps {
  emails: Email[];
  domains: Domain[];
}

export function EmailManager({ emails, domains }: EmailManagerProps) {
  const [showAddForm, setShowAddForm] = useState(false);
  const [newEmail, setNewEmail] = useState("");
  const [selectedDomain, setSelectedDomain] = useState("");
  const [inboxName, setInboxName] = useState("");
  const queryClient = useQueryClient();

  const createMutation = useMutation({
    mutationFn: ({ email, domain, inboxName }: { email: string; domain: string; inboxName?: string }) =>
      mailApi.createEmail(email, domain, inboxName),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["emails"] });
      queryClient.invalidateQueries({ queryKey: ["inboxes"] });
      setNewEmail("");
      setSelectedDomain("");
      setInboxName("");
      setShowAddForm(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (emailId: string) => mailApi.deleteEmail(emailId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["emails"] });
      queryClient.invalidateQueries({ queryKey: ["inboxes"] });
      queryClient.invalidateQueries({ queryKey: ["messages"] });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newEmail.trim() && selectedDomain) {
      createMutation.mutate({
        email: newEmail.trim(),
        domain: selectedDomain,
        inboxName: inboxName.trim() || undefined,
      });
    }
  };

  return (
    <div className="email-manager">
      <div className="email-manager-header">
        <h3>Email Addresses</h3>
        <button
          type="button"
          className="btn btn-ghost"
          onClick={() => setShowAddForm(!showAddForm)}
          disabled={domains.length === 0}
        >
          {showAddForm ? "Cancel" : "+ Add Email"}
        </button>
      </div>

      {domains.length === 0 && (
        <p className="empty-state">Add a domain first before creating email addresses.</p>
      )}

      {showAddForm && domains.length > 0 && (
        <form onSubmit={handleSubmit} className="email-form">
          <div className="form-row">
            <input
              type="text"
              placeholder="username"
              value={newEmail}
              onChange={(e) => setNewEmail(e.target.value)}
              disabled={createMutation.isPending}
            />
            <span className="email-at">@</span>
            <select
              value={selectedDomain}
              onChange={(e) => setSelectedDomain(e.target.value)}
              disabled={createMutation.isPending}
              required
            >
              <option value="">Select domain</option>
              {domains.map((domain) => (
                <option key={domain.id} value={domain.domain}>
                  {domain.domain}
                </option>
              ))}
            </select>
          </div>
          <input
            type="text"
            placeholder="Inbox name (optional, defaults to email)"
            value={inboxName}
            onChange={(e) => setInboxName(e.target.value)}
            disabled={createMutation.isPending}
          />
          <button
            type="submit"
            className="btn btn-primary"
            disabled={!newEmail.trim() || !selectedDomain || createMutation.isPending}
          >
            {createMutation.isPending ? "Creating..." : "Create"}
          </button>
          {createMutation.isError && (
            <div className="error-banner">
              {(createMutation.error as Error).message}
            </div>
          )}
        </form>
      )}

      <div className="email-list">
        {emails.length === 0 ? (
          <p className="empty-state">No email addresses yet. Create your first email address.</p>
        ) : (
          emails.map((email) => (
            <div key={email.id} className="email-item">
              <span className="email-address">{email.email}</span>
              <button
                type="button"
                className="btn btn-ghost btn-sm"
                onClick={() => {
                  if (confirm(`Delete email ${email.email}? This will also delete its inbox.`)) {
                    deleteMutation.mutate(email.id);
                  }
                }}
                disabled={deleteMutation.isPending}
              >
                Delete
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}


