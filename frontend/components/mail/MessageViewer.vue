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

</script>

<template>
  <section class="flex h-full flex-col bg-slate-950/20">
    <div class="border-b border-white/5 px-8 py-4">
      <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Preview</p>
      <h2 class="mt-1 text-2xl font-semibold text-white">
        {{ message?.subject || "Select a message" }}
      </h2>
      <p v-if="message" class="text-sm text-slate-400">
        {{ fromLabel }} · {{ formatDateTime(message.created_at) }}
      </p>
    </div>

    <div v-if="!hasSelection" class="flex flex-1 items-center justify-center text-slate-500">
      Choose a conversation to inspect its contents.
    </div>

    <div v-else class="flex-1 space-y-6 overflow-y-auto px-8 py-6">
      <div class="rounded-2xl border border-slate-800/70 bg-slate-900/40 p-4 md:flex md:items-center md:justify-between md:gap-10">
        <div>
          <p class="text-xs uppercase tracking-wide text-slate-500">From</p>
          <p class="text-base font-semibold text-slate-100">{{ fromLabel }}</p>
          <p class="text-xs text-slate-500">{{ message && formatDateTime(message.created_at) }}</p>
        </div>
        <div class="mt-4 h-px w-full bg-slate-800/70 md:mt-0 md:h-16 md:w-px" />
        <div>
          <p class="text-xs uppercase tracking-wide text-slate-500">To</p>
          <p class="text-base text-slate-100">
            {{ toLabel }}
          </p>
        </div>
      </div>

      <div class="space-y-4">
        <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Thread</p>

        <div v-if="!activeThreadMessages.length" class="rounded-2xl border border-slate-800/70 bg-slate-900/40 p-6 text-sm text-slate-400">
          No messages yet for this thread.
        </div>

        <div v-else class="flex flex-col gap-6">
          <div
            v-for="entry in activeThreadMessages"
            :key="entry.id"
            class="flex flex-col gap-2"
            :class="entry.direction === 'outbound' ? 'items-end text-right' : 'items-start text-left'"
          >
            <div class="text-xs text-slate-500">
              <span class="font-semibold text-slate-300">{{ authorLabel(entry) }}</span>
              <span v-if="recipientLabel(entry)" class="mx-1 text-slate-600">•</span>
              <span class="text-slate-400">{{ recipientLabel(entry) }}</span>
              <span class="mx-1 text-slate-600">•</span>
              <span>{{ formatDateTime(entry.created_at) }}</span>
            </div>

            <div
              class="w-full max-w-2xl space-y-4 rounded-2xl border p-5 text-sm leading-relaxed"
              :class="entry.direction === 'outbound'
                ? 'border-brand-400/40 bg-brand-500/5 text-slate-100'
                : 'border-slate-800/70 bg-slate-900/60 text-slate-200'"
            >
              <div v-if="entry.body_html" class="rich-text" v-html="entry.body_html" />
              <pre v-else class="whitespace-pre-wrap text-sm text-inherit">
{{ entry.body_plain || "No body provided." }}
              </pre>

              <div v-if="entry.attachments?.length" class="space-y-3">
                <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Attachments</p>
                <div class="attachment-grid">
                  <a
                    v-for="attachment in entry.attachments"
                    :key="attachment.id"
                    :href="attachment.url"
                    target="_blank"
                    rel="noreferrer"
                    class="attachment-card attachment-generic"
                  >
                    <div>
                      <p class="font-semibold">{{ attachment.filename }}</p>
                      <p class="text-xs text-slate-400">
                        {{ attachment.mimetype || "File" }}
                      </p>
                    </div>
                    <div class="text-right">
                      <p class="text-xs text-slate-400">{{ formatBytes(attachment.size_bytes) }}</p>
                      <span class="text-xs text-brand-300">Open</span>
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
  margin-bottom: 0.75rem;
}

.rich-text :deep(a) {
  color: rgb(96 165 250);
  text-decoration: underline;
}

.attachment-grid {
  display: grid;
  gap: 0.75rem;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}

.attachment-card {
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 1rem;
  background-color: rgba(15, 23, 42, 0.6);
  padding: 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  transition: border-color 0.2s ease, transform 0.2s ease;
}

.attachment-card:hover {
  border-color: rgba(56, 189, 248, 0.5);
  transform: translateY(-2px);
}

.attachment-generic {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.attachment-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.75rem;
  color: rgb(148 163 184);
}
</style>

