import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import "./App.css";
import { InboxList } from "./components/InboxList";
import { Composer } from "./components/Composer";
import { MessageViewer } from "./components/MessageViewer";
import { Login } from "./components/Login";
import { useMessage, useMessages, useSendMessage } from "./hooks/useMail";
import { getCurrentUser, logout, type User } from "./lib/auth";

const queryClient = new QueryClient();

function MailExperience({ user }: { user: User }) {
  const [selectedId, setSelectedId] = useState<string | undefined>();
  const messagesQuery = useMessages();
  const messageQuery = useMessage(selectedId);
  const sendMutation = useSendMessage();

  useEffect(() => {
    if (!selectedId && messagesQuery.data && messagesQuery.data.length > 0) {
      setSelectedId(messagesQuery.data[0].id);
    }
  }, [messagesQuery.data, selectedId]);

  const handleComposeClick = () => {
    document.getElementById("composer-panel")?.scrollIntoView({ behavior: "smooth", block: "center" });
  };

  const handleLogout = async () => {
    await logout();
    window.location.reload();
  };

  return (
    <div className="app-shell">
      <header className="top-bar">
        <div className="brand">
          <span>FreeMail</span>
          <span className="user-email">{user.email}</span>
        </div>
        <div className="top-actions">
          <button className="btn btn-ghost" onClick={() => messagesQuery.refetch()}>
            Refresh
          </button>
          <button className="btn btn-ghost" onClick={handleLogout}>
            Logout
          </button>
        </div>
      </header>
      <section className="app-card">
        <div className="mail-grid">
          <InboxList
            messages={messagesQuery.data}
            loading={messagesQuery.isLoading}
            selectedId={selectedId}
            onSelect={setSelectedId}
            onCompose={handleComposeClick}
          />
          <MessageViewer message={messageQuery.data} isLoading={messageQuery.isFetching} />
          <Composer
            onSend={(payload) => sendMutation.mutateAsync(payload).then(() => {})}
            sending={sendMutation.isPending}
            error={sendMutation.isError ? (sendMutation.error as Error).message : null}
          />
        </div>
      </section>
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
