import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { mailApi } from "../lib/api";
import type { Domain } from "../lib/api";

interface DomainManagerProps {
  domains: Domain[];
}

export function DomainManager({ domains }: DomainManagerProps) {
  const [newDomain, setNewDomain] = useState("");
  const [showAddForm, setShowAddForm] = useState(false);
  const queryClient = useQueryClient();

  const createMutation = useMutation({
    mutationFn: (domain: string) => mailApi.createDomain(domain),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["domains"] });
      setNewDomain("");
      setShowAddForm(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (domainId: string) => mailApi.deleteDomain(domainId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["domains"] });
      queryClient.invalidateQueries({ queryKey: ["emails"] });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newDomain.trim()) {
      createMutation.mutate(newDomain.trim());
    }
  };

  return (
    <div className="domain-manager">
      <div className="domain-manager-header">
        <h3>Domains</h3>
        <button
          type="button"
          className="btn btn-ghost"
          onClick={() => setShowAddForm(!showAddForm)}
        >
          {showAddForm ? "Cancel" : "+ Add Domain"}
        </button>
      </div>

      {showAddForm && (
        <form onSubmit={handleSubmit} className="domain-form">
          <input
            type="text"
            placeholder="example.com"
            value={newDomain}
            onChange={(e) => setNewDomain(e.target.value)}
            disabled={createMutation.isPending}
          />
          <button
            type="submit"
            className="btn btn-primary"
            disabled={!newDomain.trim() || createMutation.isPending}
          >
            {createMutation.isPending ? "Adding..." : "Add"}
          </button>
          {createMutation.isError && (
            <div className="error-banner">
              {(createMutation.error as Error).message}
            </div>
          )}
        </form>
      )}

      <div className="domain-list">
        {domains.length === 0 ? (
          <p className="empty-state">No domains added yet. Add your first domain to get started.</p>
        ) : (
          domains.map((domain) => (
            <div key={domain.id} className="domain-item">
              <span className="domain-name">{domain.domain}</span>
              <button
                type="button"
                className="btn btn-ghost btn-sm"
                onClick={() => {
                  if (confirm(`Delete domain ${domain.domain}? This will also delete all associated emails.`)) {
                    deleteMutation.mutate(domain.id);
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


