<script setup lang="ts">
import { computed } from "vue";
import type { MessageRecord } from "~/types/api";
import { formatDateTime, formatBytes } from "~/lib/formatters";
import { useMailStore } from "~/stores/mail";
import { useAuthStore } from "~/stores/auth";

const props = defineProps<{
  message: MessageRecord | null;
}>();

const mail = useMailStore();
const auth = useAuthStore();

const fallbackUserEmail = computed(() => mail.activeEmail?.email || auth.currentEmail || null);

const activeThreadMessages = computed(() => {
  if (mail.threadMessages.length) {
    return mail.threadMessages;
  }
  return props.message ? [props.message] : [];
});

const hasSelection = computed(() => Boolean(props.message));

const fromLabel = computed(() => {
  if (!props.message) return "—";
  if (props.message.direction === "outbound") {
    return props.message.sender_email || fallbackUserEmail.value || "You";
  }
  return props.message.sender_email || "Unknown";
});

const toLabel = computed(() => {
  if (!props.message) return "—";
  const recipients = props.message.recipient_emails || [];

  if (props.message.direction === "outbound") {
    return recipients.length ? recipients.join(", ") : "—";
  }

  if (recipients.length) {
    return recipients.join(", ");
  }

  return fallbackUserEmail.value || "—";
});

function authorLabel(entry: MessageRecord) {
  return entry.direction === "outbound" ? "You" : entry.sender_email || "Unknown";
}

function recipientLabel(entry: MessageRecord) {
  if (entry.direction === "outbound") {
    return entry.recipient_emails?.length ? `to ${entry.recipient_emails.join(", ")}` : "";
  }
  if (entry.recipient_emails?.length) {
    return `to ${entry.recipient_emails.join(", ")}`;
  }
  return "";
}

const canReply = computed(() => Boolean(props.message?.sender_email));
const canForward = computed(() => Boolean(props.message));

function stripHtml(html: string) {
  return html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
}

function getPlainBody(entry: MessageRecord) {
  if (entry.body_plain) {
    return entry.body_plain;
  }
  if (entry.body_html) {
    return stripHtml(entry.body_html);
  }
  return "";
}

function parseSender(sender: string): { name: string; email: string } {
  const match = sender.match(/^(.*?)\s*<(.+)>$/);
  if (match) {
    return { name: match[1].trim(), email: match[2].trim() };
  }
  return { name: "", email: sender.trim() };
}

function formatReplyDate(dateStr: string): string {
  if (!dateStr) return "Unknown date";
  const date = new Date(dateStr);
  // Format: "Thu, 27 Nov 2025 at 15:56"
  // We can use Intl.DateTimeFormat or manual formatting.
  // Manual is safer for exact match.
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  
  const dayName = days[date.getDay()];
  const day = date.getDate();
  const month = months[date.getMonth()];
  const year = date.getFullYear();
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  
  return `${dayName}, ${day} ${month} ${year} at ${hours}:${minutes}`;
}

function quoteBody(text: string, senderRaw: string, timestamp: string) {
  if (!text) return "";
  
  const { name, email } = parseSender(senderRaw || "Unknown");
  const dateStr = formatReplyDate(timestamp);
  
  let header = "";
  if (name) {
    header = `On ${dateStr}, ${name} <${email}> wrote:`;
  } else {
    header = `On ${dateStr}, ${email} wrote:`;
  }

  const quotedBody = text
    .split(/\r?\n/)
    .map((line) => {
      if (line.startsWith(">")) {
        return `>${line}`;
      }
      return `> ${line}`;
    })
    .join("\n");
    
  return `${header}\n${quotedBody}`;
}

function buildReplyContext(entry: MessageRecord) {
  let to: string[] = [];
  if (entry.direction === "outbound") {
    // If replying to an outbound message, reply to the original recipients
    to = entry.recipient_emails || [];
  } else {
    // If replying to an inbound message, reply to the sender
    to = entry.sender_email ? [entry.sender_email] : [];
  }

  const subject = entry.subject?.match(/^re:/i) ? entry.subject : `Re: ${entry.subject || ""}`;
  const quoted = quoteBody(getPlainBody(entry), entry.sender_email || "Unknown", entry.created_at || "");
  
  return {
    to,
    subject: subject.trim(),
    body: `\n\n${quoted}\n\n`,
    threadId: entry.thread_id,
    inReplyTo: entry.id,
    references: Array.isArray(entry.references) 
      ? entry.references 
      : (typeof entry.references === 'string' ? [entry.references] : undefined),
  };
}

function buildForwardContext(entry: MessageRecord) {
  const subject = entry.subject?.match(/^fwd:/i) ? entry.subject : `Fwd: ${entry.subject || ""}`;
  const headerLines = [
    "---------- Forwarded message ----------",
    `From: ${entry.sender_email || "Unknown"}`,
    `Date: ${formatDateTime(entry.created_at)}`,
    `Subject: ${entry.subject || "(no subject)"}`,
    `To: ${entry.recipient_emails?.join(", ") || "Undisclosed recipients"}`,
    "",
  ];
  const body = `\n\n${headerLines.join("\n")}${getPlainBody(entry)}\n\n`;
  return {
    subject: subject.trim(),
    body,
    threadId: entry.thread_id,
  };
}

function handleReply() {
  if (!props.message) return;
  const context = buildReplyContext(props.message);
  mail.toggleComposer(true, context);
}

function handleForward() {
  if (!props.message) return;
  const context = buildForwardContext(props.message);
  mail.toggleComposer(true, context);
}

</script>

<template>
  <section class="flex h-full flex-col bg-gradient-to-br from-slate-950 via-slate-950/95 to-slate-900/80">
    <!-- Header -->
    <div class="border-b border-white/10 bg-slate-950/40 px-6 py-6 backdrop-blur-sm md:px-8">
      <div class="flex items-start justify-between gap-4">
        <div class="flex-1">
          <p class="text-xs font-medium uppercase tracking-[0.25em] text-slate-500">Message</p>
          <h2 class="mt-2 text-2xl font-bold leading-tight text-white md:text-3xl">
            {{ message?.subject || "Select a message" }}
          </h2>
          <div v-if="message" class="mt-3 flex flex-wrap items-center gap-2 text-sm text-slate-400">
            <span class="font-medium text-slate-300">{{ fromLabel }}</span>
            <span class="text-slate-600">•</span>
            <span>{{ formatDateTime(message.created_at) }}</span>
          </div>
        </div>
        
        <!-- Action Buttons (Desktop) -->
        <div v-if="hasSelection" class="hidden gap-2 md:flex">
          <button
            v-if="canReply"
            class="group flex items-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-2.5 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-brand-400/60 hover:bg-brand-500/10 hover:text-brand-300"
            @click="handleReply"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 15L3 9m0 0l6-6M3 9h12a6 6 0 010 12h-3" />
            </svg>
            Reply
          </button>
          <button
            v-if="canForward"
            class="group flex items-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-2.5 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-purple-400/60 hover:bg-purple-500/10 hover:text-purple-300"
            @click="handleForward"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 15l6-6m0 0l-6-6m6 6H9a6 6 0 000 12h3" />
            </svg>
            Forward
          </button>
          <button
            v-if="message?.is_read"
            class="group flex items-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-2.5 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-blue-400/60 hover:bg-blue-500/10 hover:text-blue-300"
            @click="mail.updateMessageStatus(message!.id, false)"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
            Mark unread
          </button>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="!hasSelection" class="flex flex-1 flex-col items-center justify-center gap-4 text-slate-500">
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor" class="h-16 w-16 text-slate-700">
        <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
      </svg>
      <p class="text-sm">Select a message to view its contents</p>
    </div>

    <!-- Message Content -->
    <div v-else class="flex-1 space-y-6 overflow-y-auto px-6 py-6 md:px-8">
      <!-- Metadata Card -->
      <div class="overflow-hidden rounded-2xl border border-slate-800/70 bg-gradient-to-br from-slate-900/60 to-slate-900/40 backdrop-blur-sm">
        <div class="grid gap-px bg-slate-800/30 md:grid-cols-2">
          <div class="bg-slate-900/60 p-5">
            <p class="text-xs font-medium uppercase tracking-wider text-slate-500">From</p>
            <p class="mt-2 text-base font-semibold text-slate-100">{{ fromLabel }}</p>
            <p class="mt-1 text-xs text-slate-400">{{ message && formatDateTime(message.created_at) }}</p>
          </div>
          <div class="bg-slate-900/60 p-5">
            <p class="text-xs font-medium uppercase tracking-wider text-slate-500">To</p>
            <p class="mt-2 text-base font-medium text-slate-100">{{ toLabel }}</p>
          </div>
        </div>
      </div>

      <!-- Action Buttons (Mobile) -->
      <div class="flex flex-wrap gap-3 md:hidden">
        <button
          v-if="canReply"
          class="flex flex-1 items-center justify-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-3 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-brand-400/60 hover:bg-brand-500/10"
          @click="handleReply"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 15L3 9m0 0l6-6M3 9h12a6 6 0 010 12h-3" />
          </svg>
          Reply
        </button>
        <button
          v-if="canForward"
          class="flex flex-1 items-center justify-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-3 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-purple-400/60 hover:bg-purple-500/10"
          @click="handleForward"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 15l6-6m0 0l-6-6m6 6H9a6 6 0 000 12h3" />
          </svg>
          Forward
        </button>
        <button
          v-if="message?.is_read"
          class="flex flex-1 items-center justify-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/60 px-4 py-3 text-sm font-semibold text-slate-200 backdrop-blur-sm transition-all hover:border-blue-400/60 hover:bg-blue-500/10"
          @click="mail.updateMessageStatus(message!.id, false)"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
          </svg>
          Mark unread
        </button>
      </div>

      <!-- Thread Messages -->
      <div class="space-y-5">
        <div class="flex items-center gap-3">
          <p class="text-xs font-medium uppercase tracking-[0.25em] text-slate-500">Conversation</p>
          <div class="h-px flex-1 bg-gradient-to-r from-slate-800 to-transparent"></div>
        </div>

        <div v-if="!activeThreadMessages.length" class="rounded-2xl border border-slate-800/70 bg-slate-900/40 p-8 text-center text-sm text-slate-400">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor" class="mx-auto mb-3 h-12 w-12 text-slate-700">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
          </svg>
          No messages in this thread yet.
        </div>

        <div v-else class="space-y-6">
          <div
            v-for="entry in activeThreadMessages"
            :key="entry.id"
            class="flex flex-col gap-3"
            :class="entry.direction === 'outbound' ? 'items-end' : 'items-start'"
          >
            <!-- Message Metadata -->
            <div class="flex items-center gap-2 text-xs text-slate-500">
              <span class="font-semibold text-slate-300">{{ authorLabel(entry) }}</span>
              <span v-if="recipientLabel(entry)" class="text-slate-600">•</span>
              <span class="text-slate-400">{{ recipientLabel(entry) }}</span>
              <span class="text-slate-600">•</span>
              <span>{{ formatDateTime(entry.created_at) }}</span>
            </div>

            <!-- Message Bubble -->
            <div
              class="message-bubble w-full max-w-3xl space-y-5 rounded-2xl border p-6 shadow-lg backdrop-blur-sm transition-all hover:shadow-xl"
              :class="entry.direction === 'outbound'
                ? 'border-brand-400/30 bg-gradient-to-br from-brand-500/10 to-brand-600/5 text-slate-100 shadow-brand-500/5'
                : 'border-slate-800/70 bg-gradient-to-br from-slate-900/80 to-slate-900/60 text-slate-200 shadow-black/20'"
            >
              <!-- Message Body -->
              <div v-if="entry.body_html" class="rich-text text-base leading-relaxed" v-html="entry.body_html" />
              <pre v-else class="whitespace-pre-wrap font-sans text-base leading-relaxed text-inherit">{{ entry.body_plain || "No content provided." }}</pre>

              <!-- Attachments -->
              <div v-if="entry.attachments?.length" class="space-y-4 border-t border-white/5 pt-5">
                <div class="flex items-center gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4 text-slate-400">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M18.375 12.739l-7.693 7.693a4.5 4.5 0 01-6.364-6.364l10.94-10.94A3 3 0 1119.5 7.372L8.552 18.32m.009-.01l-.01.01m5.699-9.941l-7.81 7.81a1.5 1.5 0 002.112 2.13" />
                  </svg>
                  <p class="text-xs font-semibold uppercase tracking-wider text-slate-400">
                    {{ entry.attachments.length }} Attachment{{ entry.attachments.length > 1 ? 's' : '' }}
                  </p>
                </div>
                <div class="attachment-grid">
                  <a
                    v-for="attachment in entry.attachments"
                    :key="attachment.id"
                    :href="attachment.url"
                    target="_blank"
                    rel="noreferrer"
                    class="group relative overflow-hidden rounded-xl border border-slate-700/50 bg-slate-900/60 p-4 backdrop-blur-sm transition-all hover:border-brand-400/50 hover:bg-slate-800/80 hover:shadow-lg hover:shadow-brand-500/10"
                  >
                    <div class="flex items-start justify-between gap-3">
                      <div class="flex-1 overflow-hidden">
                        <p class="truncate font-semibold text-slate-200 group-hover:text-brand-300">
                          {{ attachment.filename }}
                        </p>
                        <p class="mt-1 text-xs text-slate-500">
                          {{ attachment.mimetype || "Unknown type" }}
                        </p>
                      </div>
                      <div class="flex flex-col items-end gap-1">
                        <p class="text-xs font-medium text-slate-400">{{ formatBytes(attachment.size_bytes) }}</p>
                        <span class="flex items-center gap-1 text-xs font-semibold text-brand-400 transition-transform group-hover:translate-x-0.5">
                          Open
                          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-3 w-3">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                          </svg>
                        </span>
                      </div>
                    </div>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.rich-text :deep(p) {
  margin-bottom: 1rem;
  line-height: 1.7;
}

.rich-text :deep(a) {
  color: rgb(96 165 250);
  text-decoration: underline;
  transition: color 0.2s;
}

.rich-text :deep(a:hover) {
  color: rgb(147 197 253);
}

.attachment-grid {
  display: grid;
  gap: 0.75rem;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
}

@media (max-width: 640px) {
  .attachment-grid {
    grid-template-columns: 1fr;
  }
}

.message-bubble {
  animation: fadeInScale 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes fadeInScale {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* Custom scrollbar for message viewer */
.flex-1.overflow-y-auto {
  scrollbar-width: thin;
  scrollbar-color: rgb(71 85 105) rgb(15 23 42);
}

.flex-1.overflow-y-auto::-webkit-scrollbar {
  width: 8px;
}

.flex-1.overflow-y-auto::-webkit-scrollbar-track {
  background: rgb(15 23 42);
  border-radius: 4px;
}

.flex-1.overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgb(71 85 105);
  border-radius: 4px;
  transition: background 0.2s;
}

.flex-1.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: rgb(100 116 139);
}
</style>


