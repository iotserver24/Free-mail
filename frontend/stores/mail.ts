import { defineStore } from "pinia";
import type { DomainRecord, EmailRecord, InboxRecord, MessageRecord } from "~/types/api";
import type { ComposeContext, ComposePayload } from "~/types/messaging";

interface MailState {
  domains: DomainRecord[];
  emails: EmailRecord[];
  inboxes: InboxRecord[];
  messages: MessageRecord[];
  selectedMessageId: string | null;
  messageDetail: MessageRecord | null;
  threadMessages: MessageRecord[];
  activeInboxId: string | null;
  composerOpen: boolean;
  composerContext: ComposeContext | null;
  loadingMessages: boolean;
  bootstrapped: boolean;
}

export const useMailStore = defineStore("mail", {
  state: (): MailState => ({
    domains: [],
    emails: [],
    inboxes: [],
    messages: [],
    selectedMessageId: null,
    messageDetail: null,
    threadMessages: [],
    activeInboxId: null,
    composerOpen: false,
    composerContext: null,
    loadingMessages: false,
    bootstrapped: false,
  }),
  getters: {
    activeEmail(state): EmailRecord | undefined {
      return state.emails.find((email) => email.inbox_id === state.activeInboxId);
    },
    activeInbox(state): InboxRecord | undefined {
      return state.inboxes.find((inbox) => inbox.id === state.activeInboxId);
    },
    inboxBuckets(state) {
      return state.emails.map((email) => ({
        email,
        inbox: state.inboxes.find((inbox) => inbox.id === email.inbox_id),
      }));
    },
  },
  actions: {
    async bootstrap() {
      if (this.bootstrapped) {
        return;
      }
      await Promise.all([this.loadDomains(), this.loadEmails(), this.loadInboxes()]);
      if (!this.activeInboxId && this.emails[0]) {
        this.activeInboxId = this.emails[0].inbox_id;
      }
      await this.loadMessages();
      this.bootstrapped = true;
    },
    async loadDomains() {
      const api = useApi();
      this.domains = await api<DomainRecord[]>("/api/domains");
    },
    async loadEmails() {
      const api = useApi();
      this.emails = await api<EmailRecord[]>("/api/emails");
    },
    async loadInboxes() {
      const api = useApi();
      this.inboxes = await api<InboxRecord[]>("/api/inboxes");
    },
    setActiveInbox(inboxId: string) {
      if (this.activeInboxId === inboxId) return;
      this.activeInboxId = inboxId;
      this.selectedMessageId = null;
      this.messageDetail = null;
      this.threadMessages = [];
      this.composerContext = null;
      this.loadMessages();
    },
    async loadMessages() {
      if (!this.activeInboxId) {
        this.messages = [];
        return;
      }
      this.loadingMessages = true;
      const api = useApi();
      try {
        this.messages = await api<MessageRecord[]>("/api/messages", {
          query: { inboxId: this.activeInboxId, limit: 50 },
        });
      } finally {
        this.loadingMessages = false;
      }
    },
    async selectMessage(messageId: string) {
      this.selectedMessageId = messageId;
      const api = useApi();
      this.messageDetail = await api<MessageRecord>(`/api/messages/${messageId}`);

      if (this.messageDetail?.thread_id) {
        this.threadMessages = await api<MessageRecord[]>(`/api/messages/thread/${this.messageDetail.thread_id}`);
      } else if (this.messageDetail) {
        this.threadMessages = [this.messageDetail];
      } else {
        this.threadMessages = [];
      }

      if (!this.messageDetail.is_read) {
        this.updateMessageStatus(messageId, true);
      }
    },
    toggleComposer(open?: boolean, context?: ComposeContext | null) {
      const nextState = typeof open === "boolean" ? open : !this.composerOpen;
      this.composerOpen = nextState;
      if (context) {
        this.composerContext = context;
      } else if (nextState && !context) {
        this.composerContext = null;
      }
      if (!nextState) {
        this.composerContext = null;
      }
    },
    async createDomain(domain: string) {
      const api = useApi();
      await api<DomainRecord>("/api/domains", {
        method: "POST",
        body: { domain },
      });
      await this.loadDomains();
      useToasts().push({
        title: "Domain added",
        message: `${domain} is now tracked.`,
        variant: "success",
      });
    },
    async createEmail(payload: { email: string; domain: string; inboxName?: string }) {
      const api = useApi();
      const created = await api<EmailRecord>("/api/emails", {
        method: "POST",
        body: payload,
      });
      await Promise.all([this.loadEmails(), this.loadInboxes()]);
      useToasts().push({
        title: "Email created",
        message: `${payload.email} is ready to receive mail.`,
        variant: "success",
      });
      this.activeInboxId = created.inbox_id;
      await this.loadMessages();
    },
    async sendMessage(payload: ComposePayload) {
      const api = useApi();
      await api("/api/messages", {
        method: "POST",
        body: payload,
      });
      useToasts().push({
        title: "Message sent",
        message: `Delivered to ${payload.to.join(", ")}`,
        variant: "success",
      });
      await this.loadMessages();
    },
    async updateMessageStatus(messageId: string, isRead: boolean) {
      const api = useApi();
      // Optimistic update
      const message = this.messages.find((m) => m.id === messageId);
      if (message) {
        message.is_read = isRead;
      }
      if (this.messageDetail?.id === messageId) {
        this.messageDetail.is_read = isRead;
      }

      try {
        await api<MessageRecord>(`/api/messages/${messageId}`, {
          method: "PATCH",
          body: { is_read: isRead },
        });
      } catch (error) {
        // Revert on error
        if (message) {
          message.is_read = !isRead;
        }
        if (this.messageDetail?.id === messageId) {
          this.messageDetail.is_read = !isRead;
        }
        throw error;
      }
    },
  },
});

