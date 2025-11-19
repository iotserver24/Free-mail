import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import "./App.css";
import { InboxList } from "./components/InboxList";
import { Composer } from "./components/Composer";
import { MessageViewer } from "./components/MessageViewer";
import { Login } from "./components/Login";
import { DomainManager } from "./components/DomainManager";
import { EmailManager } from "./components/EmailManager";
import { InboxSelector } from "./components/InboxSelector";
import { useMessage, useMessages, useSendMessage, useDomains, useEmails, useInboxes } from "./hooks/useMail";
import { getCurrentUser, logout, type User } from "./lib/auth";

const queryClient = new QueryClient();

function MailExperience({ user }: { user: User }) {
  const [selectedId, setSelectedId] = useState<string | undefined>();
  const [selectedInboxId, setSelectedInboxId] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  
  const domainsQuery = useDomains();
  const emailsQuery = useEmails();
  const inboxesQuery = useInboxes();
  const messagesQuery = useMessages(selectedInboxId);
  const messageQuery = useMessage(selectedId);
  const sendMutation = useSendMessage();
  const [composerPulse, setComposerPulse] = useState(0);

  useEffect(() => {
    if (!selectedId && messagesQuery.data && messagesQuery.data.length > 0) {
      setSelectedId(messagesQuery.data[0].id);
    }
  }, [messagesQuery.data, selectedId]);

  const handleComposeClick = () => {
    document.getElementById("composer-panel")?.scrollIntoView({ behavior: "smooth", block: "center" });
    setComposerPulse((value) => value + 1);
  };

  const handleLogout = async () => {
    await logout();
    window.location.reload();
  };

  const analytics = useMemo(() => {
    const items = messagesQuery.data ?? [];
    if (items.length === 0) {
      return {
        total: 0,
        inbound: 0,
        outbound: 0,
        failed: 0,
        latest: null as Date | null,
      };
    }

    const inbound = items.filter((msg) => msg.direction === "inbound").length;
    const outbound = items.length - inbound;
    const failed = items.filter((msg) => msg.status === "failed").length;
    const latest = items
      .slice()
      .sort((a, b) => Number(new Date(b.created_at)) - Number(new Date(a.created_at)))[0];

    return {
      total: items.length,
      inbound,
      outbound,
      failed,
      latest: latest ? new Date(latest.created_at) : null,
    };
  }, [messagesQuery.data]);

  const insightCards = [
    {
      label: "Total traffic",
      value: analytics.total,
      detail: `${analytics.inbound} inbound • ${analytics.outbound} outbound`,
    },
    {
      label: "Delivery health",
      value: analytics.failed === 0 ? "100%" : `${Math.max(0, Math.round(((analytics.total - analytics.failed) / Math.max(1, analytics.total)) * 100))}%`,
      detail: analytics.failed === 0 ? "No failures detected" : `${analytics.failed} messages need attention`,
    },
    {
      label: "Last message",
      value: analytics.latest ? analytics.latest.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "—",
      detail: analytics.latest ? analytics.latest.toLocaleDateString() : "Waiting for first sync",
    },
  ];

  const lastUpdatedAgo = useMemo(() => {
    if (!messagesQuery.dataUpdatedAt) return "Just now";
    const diff = Date.now() - messagesQuery.dataUpdatedAt;
    const minutes = Math.floor(diff / 60000);
    if (minutes <= 0) return "Moments ago";
    if (minutes === 1) return "1 minute ago";
    return `${minutes} minutes ago`;
  }, [messagesQuery.dataUpdatedAt]);

  return (
    <div className="experience-bg">
      <div className="hero-gradient" />
      <div className="app-shell">
        <header className="top-bar">
          <div className="brand">
            <span>FreeMail Mission Control</span>
            <span className="user-email">Signed in as {user.email}</span>
          </div>
          <div className="top-actions">
            {inboxesQuery.data && inboxesQuery.data.length > 0 && (
              <InboxSelector
                inboxes={inboxesQuery.data}
                selectedInboxId={selectedInboxId}
                onSelect={setSelectedInboxId}
              />
            )}
            <div className="sync-indicator">
              <span className="pulse-dot" aria-hidden />
              Synced {lastUpdatedAgo}
            </div>
            <button className="btn btn-ghost" onClick={() => {
              messagesQuery.refetch();
              domainsQuery.refetch();
              emailsQuery.refetch();
              inboxesQuery.refetch();
            }}>
              Refresh
            </button>
            <button className="btn btn-ghost" onClick={() => setShowSettings(!showSettings)}>
              {showSettings ? "Hide" : "Settings"}
            </button>
            <button className="btn btn-ghost" onClick={handleLogout}>
              Logout
            </button>
          </div>
        </header>

        <section className="insight-row">
          {insightCards.map((card) => (
            <article key={card.label} className="insight-card">
              <p>{card.label}</p>
              <strong>{card.value}</strong>
              <span>{card.detail}</span>
            </article>
          ))}
          <article className="insight-card cta-card">
            <p>Need to react fast?</p>
            <strong>Compose instantly</strong>
            <button className="btn btn-primary" onClick={handleComposeClick}>
              Launch composer
            </button>
          </article>
        </section>

        {showSettings && (
          <section className="app-card settings-section">
            <div className="settings-grid">
              <DomainManager domains={domainsQuery.data || []} />
              <EmailManager 
                emails={emailsQuery.data || []} 
                domains={domainsQuery.data || []}
              />
            </div>
          </section>
        )}

        <section className="app-card">
          <div className="mail-grid">
            <InboxList
              messages={messagesQuery.data}
              loading={messagesQuery.isLoading}
              selectedId={selectedId}
              onSelect={setSelectedId}
              onCompose={handleComposeClick}
            />
            <MessageViewer
              message={messageQuery.data}
              isLoading={messageQuery.isFetching}
              refetching={messagesQuery.isRefetching}
            />
            <Composer
              emails={emailsQuery.data || []}
              onSend={(payload) => sendMutation.mutateAsync(payload).then(() => {})}
              sending={sendMutation.isPending}
              error={sendMutation.isError ? (sendMutation.error as Error).message : null}
              pulseSignal={composerPulse}
            />
          </div>
        </section>
      </div>
    </div>
  );
}

function AuthFlow() {
  const { data: user, refetch } = useQuery({
    queryKey: ["currentUser"],
    queryFn: getCurrentUser,
    retry: false,
  });

  if (user) {
    return <MailExperience user={user} />;
  }

  return (
    <div className="auth-container">
      <Login onSuccess={() => refetch()} onSwitchToRegister={() => {}} />
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthFlow />
    </QueryClientProvider>
  );
}
