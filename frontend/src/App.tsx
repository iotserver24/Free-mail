import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import { Navigate, Route, Routes, useNavigate, useParams } from "react-router-dom";
import "./App.css";
import { InboxList } from "./components/InboxList";
import { Composer } from "./components/Composer";
import { MessageViewer } from "./components/MessageViewer";
import { Login } from "./components/Login";
import { DomainManager } from "./components/DomainManager";
import { EmailManager } from "./components/EmailManager";
import { useMessage, useMessages, useSendMessage, useDomains, useEmails, useInboxes } from "./hooks/useMail";
import { getCurrentUser, type User } from "./lib/auth";
import type { Message } from "./lib/api";

const queryClient = new QueryClient();

function MailExperience({
  user,
  emailParam,
  messageParam,
}: {
  user: User;
  emailParam?: string;
  messageParam?: string;
}) {
  const [showSettings, setShowSettings] = useState(false);
  const [showComposer, setShowComposer] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [composerInitialValues, setComposerInitialValues] = useState<{
    to?: string;
    subject?: string;
    body?: string;
    replyTo?: string;
    threadId?: string | null;
  } | null>(null);

  const navigate = useNavigate();
  const domainsQuery = useDomains();
  const emailsQuery = useEmails();
  const inboxesQuery = useInboxes();

  const selectedEmailId = emailParam ?? null;
  const selectedMessageId = messageParam;
  const activeEmail = emailsQuery.data?.find((email) => email.id === selectedEmailId) ?? null;
  const selectedInboxId = activeEmail?.inbox_id ?? null;

  const messagesQuery = useMessages(selectedInboxId);
  const messageQuery = useMessage(selectedMessageId);
  const sendMutation = useSendMessage();

  useEffect(() => {
    if (!selectedEmailId && emailsQuery.data && emailsQuery.data.length > 0) {
      navigate(`/m/${emailsQuery.data[0].id}`, { replace: true });
    }
  }, [selectedEmailId, emailsQuery.data, navigate]);

  useEffect(() => {
    if (!selectedEmailId) return;
    if (!messagesQuery.data || messagesQuery.data.length === 0) return;
    if (selectedMessageId && messagesQuery.data.some((msg) => msg.id === selectedMessageId)) {
      return;
    }
    const firstMessage = messagesQuery.data[0];
    navigate(`/m/${selectedEmailId}/${firstMessage.id}`, { replace: true });
  }, [selectedEmailId, selectedMessageId, messagesQuery.data, navigate]);

  const handleInboxNavigate = (emailId?: string | null) => {
    if (!emailId) {
      navigate("/m");
      return;
    }
    navigate(`/m/${emailId}`);
  };

  const handleMessageSelect = (message: Message) => {
    const emailForMessage = emailsQuery.data?.find((email) => email.inbox_id === message.inbox_id);
    const routeEmailId = emailForMessage?.id ?? selectedEmailId ?? emailsQuery.data?.[0]?.id ?? null;
    if (routeEmailId) {
      navigate(`/m/${routeEmailId}/${message.id}`);
    } else {
      navigate(`/m/${message.id}`);
    }
  };

  const handleComposeClick = () => {
    setComposerInitialValues(null);
    setShowComposer(true);
  };

  const handleReply = (message: Message) => {
    let replyToEmail: string;
    if (message.direction === "inbound" && message.sender_email) {
      replyToEmail = message.sender_email;
    } else if (message.direction === "outbound" && message.recipient_emails && message.recipient_emails.length > 0) {
      replyToEmail = message.recipient_emails[0] ?? "";
    } else {
      const emailRegex = /[\w\.-]+@[\w\.-]+\.\w+/g;
      const matches =
        (message.preview_text?.match(emailRegex) ||
          message.body_plain?.match(emailRegex) ||
          []) as string[];
      replyToEmail = matches.length > 0 ? matches[0] : "";
    }
    
    if (!replyToEmail) {
      alert("Could not determine recipient email address for reply.");
      return;
    }
    
    const replySubject = message.subject.startsWith("Re: ") 
      ? message.subject 
      : `Re: ${message.subject}`;
    
    const originalBody = message.body_plain || message.body_html?.replace(/<[^>]+>/g, "") || "";
    const replyBody = `\n\n--- Original Message ---\nFrom: ${message.sender_email || "Unknown"}\nSubject: ${message.subject}\n\n${originalBody}`;
    
    const fromEmail = emailsQuery.data?.find(email => email.inbox_id === message.inbox_id)?.email || emailsQuery.data?.[0]?.email;
    
    setComposerInitialValues({
      to: replyToEmail,
      subject: replySubject,
      body: replyBody,
      replyTo: fromEmail,
      threadId: message.thread_id || message.id,
    });
    setShowComposer(true);
  };

  const handleForward = (message: Message) => {
    const forwardSubject = message.subject.startsWith("Fwd: ") || message.subject.startsWith("Fw: ")
      ? message.subject 
      : `Fwd: ${message.subject}`;
    
    const originalBody = message.body_plain || message.body_html?.replace(/<[^>]+>/g, "") || "";
    const forwardBody = `\n\n--- Forwarded Message ---\nFrom: ${message.sender_email || "Unknown"}\nSubject: ${message.subject}\n\n${originalBody}`;
    
    setComposerInitialValues({
      subject: forwardSubject,
      body: forwardBody,
      replyTo: emailsQuery.data?.[0]?.email,
      threadId: message.thread_id || message.id,
    });
    setShowComposer(true);
  };

  const unreadCount = useMemo(() => {
    return messagesQuery.data?.filter(msg => msg.direction === "inbound" && msg.status === "received").length || 0;
  }, [messagesQuery.data]);

  return (
    <div className="gmail-app">
      {/* Top Bar */}
      <header className="gmail-top-bar">
        <div className="gmail-top-left">
          <button 
            className="gmail-menu-btn" 
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            aria-label="Menu"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"/>
            </svg>
          </button>
          <div className="gmail-logo">
            <svg width="109" height="40" viewBox="0 0 109 40">
              <path fill="#4285F4" d="M40.268 28.02L49.42 19.87c.38-.38.38-1.02 0-1.4L40.268 9.32c-.38-.38-1.02-.38-1.4 0l-9.15 9.15c-.38.38-.38 1.02 0 1.4l9.15 9.15c.38.38 1.02.38 1.4 0z"/>
              <text x="55" y="28" fill="#5F6368" fontFamily="Arial" fontSize="22" fontWeight="400">FreeMail</text>
            </svg>
          </div>
        </div>
        <div className="gmail-search-container">
          <div className="gmail-search-box">
            <svg className="gmail-search-icon" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
            </svg>
            <input 
              type="text" 
              placeholder="Search mail" 
              className="gmail-search-input"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            {searchQuery && (
              <button 
                className="gmail-search-clear" 
                onClick={() => setSearchQuery("")}
                aria-label="Clear search"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                </svg>
              </button>
            )}
            <button className="gmail-search-filter" aria-label="Show search options">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z"/>
              </svg>
            </button>
          </div>
        </div>
        <div className="gmail-top-right">
          <button className="gmail-icon-btn" onClick={() => {
            messagesQuery.refetch();
            domainsQuery.refetch();
            emailsQuery.refetch();
            inboxesQuery.refetch();
          }} aria-label="Refresh">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/>
            </svg>
          </button>
          <button className="gmail-icon-btn" onClick={() => setShowSettings(!showSettings)} aria-label="Settings">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
              <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.64l-1.92-3.32c-.12-.22-.37-.31-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.09-.47 0-.59.22L2.74 8.87c-.12.22-.08.5.12.64l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.64l1.92 3.32c.12.22.37.31.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.06-.5-.12-.64l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>
            </svg>
          </button>
          <div className="gmail-profile">
            <div className="gmail-profile-avatar">{user.email.charAt(0).toUpperCase()}</div>
          </div>
        </div>
      </header>

      <div className="gmail-main-container">
        {/* Left Sidebar */}
        <aside className={`gmail-sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
          <button className="gmail-compose-btn" onClick={handleComposeClick}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
            </svg>
            <span>Compose</span>
          </button>
          
          <nav className="gmail-nav">
            <button 
              className={`gmail-nav-item ${!selectedEmailId ? "active" : ""}`}
              onClick={() => handleInboxNavigate(null)}
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
              </svg>
              <span>Inbox</span>
              {unreadCount > 0 && <span className="gmail-nav-badge">{unreadCount}</span>}
            </button>
            
            <button className="gmail-nav-item">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
              </svg>
              <span>Starred</span>
            </button>
            
            <button className="gmail-nav-item">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
              <span>Snoozed</span>
            </button>
            
            <button className="gmail-nav-item">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
              </svg>
              <span>Sent</span>
            </button>
            
            <button className="gmail-nav-item">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/>
              </svg>
              <span>Drafts</span>
            </button>

            <div className="gmail-nav-divider"></div>

            <div className="gmail-labels-section">
              <div className="gmail-labels-header">
                <span>Mailboxes</span>
                <button className="gmail-add-label">+</button>
              </div>
              {emailsQuery.data?.map((email) => (
                <button
                  key={email.id}
                  className={`gmail-nav-item ${selectedEmailId === email.id ? "active" : ""}`}
                  onClick={() => handleInboxNavigate(email.id)}
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.63 5.84C17.27 5.33 16.67 5 16 5L5 5.01C3.9 5.01 3 5.9 3 7.01v10c0 1.1.9 1.99 2 1.99L16 19c.67 0 1.27-.33 1.63-.84L22 12l-4.37-6.16z"/>
                  </svg>
                  <span>{email.email}</span>
                </button>
              ))}
            </div>
          </nav>
        </aside>

        {/* Main Content Area */}
        <main className="gmail-content">
          {showSettings && (
            <div className="gmail-settings-panel">
              <div className="gmail-settings-content">
                <DomainManager domains={domainsQuery.data || []} />
                <EmailManager 
                  emails={emailsQuery.data || []} 
                  domains={domainsQuery.data || []}
                />
              </div>
            </div>
          )}
          
          <div className="gmail-mail-view">
            <InboxList
              messages={messagesQuery.data}
              loading={messagesQuery.isLoading}
              selectedId={selectedMessageId}
              onSelect={handleMessageSelect}
              searchQuery={searchQuery}
            />
            <MessageViewer
              message={messageQuery.data}
              isLoading={messageQuery.isFetching}
              refetching={messagesQuery.isRefetching}
              onReply={handleReply}
              onForward={handleForward}
            />
          </div>
        </main>
      </div>

      {/* Composer Modal */}
      {showComposer && (
        <div className="gmail-composer-overlay" onClick={() => {
          setShowComposer(false);
          setComposerInitialValues(null);
        }}>
          <div className="gmail-composer-modal" onClick={(e) => e.stopPropagation()}>
            <Composer
              emails={emailsQuery.data || []}
              onSend={async (payload) => {
                await sendMutation.mutateAsync(payload);
                setComposerInitialValues(null);
                setShowComposer(false);
              }}
              sending={sendMutation.isPending}
              error={sendMutation.isError ? (sendMutation.error as Error).message : null}
              initialValues={composerInitialValues || undefined}
              onClose={() => {
                setShowComposer(false);
                setComposerInitialValues(null);
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

interface AuthFlowProps {
  emailParam?: string;
  messageParam?: string;
}

function AuthFlow({ emailParam, messageParam }: AuthFlowProps) {
  const { data: user, refetch } = useQuery({
    queryKey: ["currentUser"],
    queryFn: getCurrentUser,
    retry: false,
  });

  if (user) {
    return <MailExperience user={user} emailParam={emailParam} messageParam={messageParam} />;
  }

  return (
    <div className="auth-container">
      <Login onSuccess={() => refetch()} onSwitchToRegister={() => {}} />
    </div>
  );
}

function RoutedAuthFlow() {
  const params = useParams<{ emailId?: string; messageId?: string }>();
  return <AuthFlow emailParam={params.emailId} messageParam={params.messageId} />;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/m" replace />} />
      <Route path="/m" element={<RoutedAuthFlow />} />
      <Route path="/m/:emailId" element={<RoutedAuthFlow />} />
      <Route path="/m/:emailId/:messageId" element={<RoutedAuthFlow />} />
      <Route path="*" element={<Navigate to="/m" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppRoutes />
    </QueryClientProvider>
  );
}
