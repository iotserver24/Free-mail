<script setup lang="ts">
import { reactive, ref, watch } from "vue";
import { XMarkIcon, PaperClipIcon, SparklesIcon } from "@heroicons/vue/24/outline";
import type { EmailRecord } from "../../types/api";
import type { AttachmentPayload, ComposeContext, ComposePayload } from "../../types/messaging";
import { uploadToCatbox } from "../../lib/catbox";
import { useToasts } from "../../composables/useToasts";
import { useMailStore } from "../../stores/mail";
import AIPromptDialog from "./AIPromptDialog.vue";

const props = defineProps<{
  open: boolean;
  emails: EmailRecord[];
  activeInboxId: string | null;
  context?: ComposeContext | null;
  submit?: (payload: ComposePayload) => Promise<void> | void;
}>();

const emit = defineEmits<{
  close: [];
}>();

const toasts = useToasts();
const runtimeConfig = useRuntimeConfig();
const mail = useMailStore();

const form = reactive({
  from: "",
  to: "",
  cc: "",
  bcc: "",
  subject: "",
  body: "",
});

const attachments = ref<AttachmentPayload[]>([]);
const uploading = ref(false);
const uploadingFileName = ref<string | null>(null);
const uploadProgress = ref(0);
const sending = ref(false);
const aiPromptOpen = ref(false);
const aiGenerating = ref(false);
const aiStreamedContent = ref("");

const MAX_ATTACHMENT_SIZE_BYTES = 20 * 1024 * 1024; // 20MB

watch(
  () => props.activeInboxId,
  (newInbox) => {
    if (!newInbox) return;
    const email = props.emails.find((item) => item.inbox_id === newInbox);
    if (email) {
      form.from = email.email;
    }
  },
  { immediate: true }
);

// Also watch for when emails list changes and update from field if needed
watch(
  () => props.emails,
  () => {
    if (props.activeInboxId && props.open) {
      const email = props.emails.find((item) => item.inbox_id === props.activeInboxId);
      if (email) {
        form.from = email.email;
      }
    }
  },
  { deep: true }
);

function resetForm() {
  form.to = "";
  form.cc = "";
  form.bcc = "";
  form.subject = "";
  form.body = "";
  attachments.value = [];
}

function resetUploadState() {
  uploading.value = false;
  uploadingFileName.value = null;
  uploadProgress.value = 0;
}

function applyContext(context: ComposeContext | null | undefined) {
  if (!context) return;
  form.to = context.to?.join(", ") ?? form.to;
  form.cc = context.cc?.join(", ") ?? form.cc;
  form.bcc = context.bcc?.join(", ") ?? form.bcc;
  if (typeof context.subject === "string") {
    form.subject = context.subject;
  }
  if (typeof context.body === "string") {
    form.body = context.body;
  }
}

watch(
  () => props.open,
  (isOpen) => {
    if (!isOpen) {
      resetForm();
      resetUploadState();
      return;
    }
    resetForm();
    // Set from field based on active inbox when composer opens
    if (props.activeInboxId) {
      const email = props.emails.find((item) => item.inbox_id === props.activeInboxId);
      if (email) {
        form.from = email.email;
      }
    }
    applyContext(props.context);
  }
);

watch(
  () => props.context,
  (context) => {
    if (!props.open) return;
    resetForm();
    applyContext(context);
    resetUploadState();
  },
  { deep: true }
);

function parseRecipients(raw: string) {
  return raw
    .split(/[,;\s]+/)
    .map((entry) => entry.trim())
    .filter(Boolean);
}

async function handleFiles(event: Event) {
  const target = event.target as HTMLInputElement;
  if (!target.files?.length) return;
  uploading.value = true;
  const files = Array.from(target.files);
  for (const file of files) {
    if (file.size > MAX_ATTACHMENT_SIZE_BYTES) {
      toasts.push({
        title: "File too large",
        message: `${file.name} exceeds the 20MB limit.`,
        variant: "error",
      });
      continue;
    }
    try {
      uploadingFileName.value = file.name;
      uploadProgress.value = 0;
      const result = await uploadToCatbox(file, (percent) => {
        uploadProgress.value = percent;
      });
      attachments.value.push({
        filename: result.filename,
        url: result.url,
        contentType: result.type,
      });
      toasts.push({
        title: "Uploaded to Catbox",
        message: `${file.name} is ready to attach.`,
        variant: "success",
      });
    } catch (error) {
      toasts.push({
        title: "Upload failed",
        message: (error as Error).message,
        variant: "error",
      });
    } finally {
      uploadingFileName.value = null;
      uploadProgress.value = 0;
    }
  }
  uploading.value = false;
  target.value = "";
}

async function handleSend() {
  sending.value = true;
  try {
    const payload: ComposePayload = {
      from: form.from,
      to: parseRecipients(form.to),
      cc: parseRecipients(form.cc),
      bcc: parseRecipients(form.bcc),
      subject: form.subject,
      text: form.body,
      html: undefined,
      attachments: attachments.value,
    };
    if (props.submit) {
      if (props.context?.threadId) {
        payload.threadId = props.context.threadId;
      }
      await props.submit(payload);
    }
    resetForm();
    emit("close");
  } finally {
    sending.value = false;
  }
}

function removeAttachment(url: string) {
  attachments.value = attachments.value.filter((attachment) => attachment.url !== url);
}

function parseEmailXML(xmlString: string) {
  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(xmlString, "text/xml");

    const subject = doc.querySelector("subject")?.textContent || "";
    const bodyElement = doc.querySelector("body");
    let body = "";

    if (bodyElement) {
      const paragraphs = bodyElement.querySelectorAll("p");
      if (paragraphs.length > 0) {
        body = Array.from(paragraphs)
          .map((p) => p.textContent)
          .join("\n\n");
      } else {
        body = bodyElement.textContent || "";
      }
    }

    return { subject, body };
  } catch (err) {
    console.error("XML parsing error:", err);
    return null;
  }
}

async function handleAIGenerate(prompt: string) {
  aiGenerating.value = true;
  aiStreamedContent.value = "";

  try {
    const requestBody: any = {
      topic: prompt,
    };

    // If this is a reply/forward, include the whole thread as context
    if (props.context?.body && mail.threadMessages.length > 0) {
      // Build conversation context from all thread messages
      requestBody.conversationContext = mail.threadMessages.map((msg) => {
        const body = msg.body_plain || (msg.body_html ? msg.body_html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim() : "");
        const role = msg.direction === "outbound" ? "assistant" : "user";
        return {
          role,
          content: `Subject: ${msg.subject || ""}\n\n${body}`,
          timestamp: msg.created_at,
        };
      });
    } else if (props.context?.body) {
      // Fallback: if no thread messages, use the context body
      const previousEmailSubject = props.context.subject || "";
      const previousEmailBody = props.context.body;
      requestBody.conversationContext = [
        {
          role: "user",
          content: `Subject: ${previousEmailSubject}\n\n${previousEmailBody}`,
          timestamp: new Date().toISOString(),
        },
      ];
    }

    const apiBase = runtimeConfig.public.apiBase || "http://localhost:4000";

    const response = await fetch(`${apiBase}/api/ai/generate-email-stream`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split("\n");

      lines.forEach((line) => {
        if (line.startsWith("data: ")) {
          try {
            const data = JSON.parse(line.slice(6));

            if (data.content) {
              aiStreamedContent.value += data.content;
            } else if (data.done) {
              aiGenerating.value = false;
              const parsed = parseEmailXML(aiStreamedContent.value);
              if (parsed) {
                form.subject = parsed.subject;
                
                // If this is a reply/forward, preserve the quoted context and prepend AI content
                if (props.context?.body && props.context.body.trim()) {
                  // Prepend AI-generated content above the quoted reply context
                  form.body = `${parsed.body}\n\n${props.context.body}`;
                } else {
                  // For new emails, just use the AI-generated body
                  form.body = parsed.body;
                }
                
                aiPromptOpen.value = false;
                useToasts().push({
                  title: "AI Email Generated",
                  message: "The email has been filled in. Review and send when ready.",
                  variant: "success",
                });
              }
            } else if (data.error) {
              throw new Error(data.error);
            }
          } catch (err) {
            console.error("JSON parse error:", err);
          }
        }
      });
    }
  } catch (err: any) {
    aiGenerating.value = false;
    useToasts().push({
      title: "AI Generation Failed",
      message: err.message || "Failed to generate email",
      variant: "error",
    });
  }
}

function openAIPrompt() {
  aiPromptOpen.value = true;
  aiStreamedContent.value = "";
}
</script>

<template>
  <Transition name="slide-up">
    <div v-if="open" class="fixed inset-0 z-40 flex items-end justify-end bg-black/40 p-6 backdrop-blur-sm">
      <div class="w-full max-w-2xl rounded-3xl border border-slate-800/70 bg-slate-900/90 p-6 text-slate-100 shadow-2xl shadow-black/40">
        <div class="mb-4 flex items-center justify-between">
          <div>
            <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Compose</p>
            <h3 class="text-xl font-semibold">New message</h3>
          </div>
          <button
            class="rounded-full p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white"
            @click="emit('close')"
          >
            <XMarkIcon class="h-5 w-5" />
          </button>
        </div>

        <div class="space-y-4">
          <div class="grid gap-4 md:grid-cols-2">
            <div>
              <label class="text-xs text-slate-500">From</label>
              <select
                v-model="form.from"
                class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              >
                <option v-for="email in emails" :key="email.id" :value="email.email">
                  {{ email.email }}
                </option>
              </select>
            </div>
            <div>
              <label class="text-xs text-slate-500">To</label>
              <input
                v-model="form.to"
                type="text"
                placeholder="alice@example.com, team@company.com"
                class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              />
            </div>
          </div>

          <div class="grid gap-4 md:grid-cols-2">
            <div>
              <label class="text-xs text-slate-500">Cc</label>
              <input
                v-model="form.cc"
                type="text"
                placeholder="Optional"
                class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              />
            </div>
            <div>
              <label class="text-xs text-slate-500">Bcc</label>
              <input
                v-model="form.bcc"
                type="text"
                placeholder="Optional"
                class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              />
            </div>
          </div>

          <div>
            <label class="text-xs text-slate-500">Subject</label>
            <input
              v-model="form.subject"
              type="text"
              placeholder="What's this about?"
              class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
            />
          </div>

          <div>
            <div class="mb-2 flex items-center justify-between">
              <label class="text-xs text-slate-500">Message</label>
              <button
                type="button"
                class="flex items-center gap-1.5 rounded-lg border border-purple-500/30 bg-purple-500/10 px-3 py-1.5 text-xs font-medium text-purple-300 transition hover:border-purple-500/50 hover:bg-purple-500/20"
                @click="openAIPrompt"
              >
                <SparklesIcon class="h-3.5 w-3.5" />
                AI Write
              </button>
            </div>
            <div class="relative">
              <textarea
                v-model="form.body"
                rows="6"
                placeholder="Write your message…"
                class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-3 text-sm focus:border-brand-400 focus:outline-none"
              />
              <!-- AI Typing Animation Overlay -->
              <div
                v-if="aiGenerating"
                class="absolute inset-0 flex items-center justify-center rounded-2xl bg-slate-900/90 backdrop-blur-sm"
              >
                <div class="flex flex-col items-center gap-3">
                  <div class="flex items-center gap-2 text-purple-400">
                    <SparklesIcon class="h-5 w-5 animate-pulse" />
                    <span class="text-sm font-medium">AI is writing...</span>
                  </div>
                  <div class="flex gap-1">
                    <div class="h-2 w-2 animate-bounce rounded-full bg-purple-400" style="animation-delay: 0s"></div>
                    <div class="h-2 w-2 animate-bounce rounded-full bg-purple-400" style="animation-delay: 0.2s"></div>
                    <div class="h-2 w-2 animate-bounce rounded-full bg-purple-400" style="animation-delay: 0.4s"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-2xl border border-dashed border-slate-700/80 p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-semibold">Attachments via Catbox</p>
                <p class="text-xs text-slate-500">
                  Files upload directly to catbox.moe (reqtype=fileupload) before sending. Max size per file: 20MB.
                </p>
              </div>
              <label class="inline-flex cursor-pointer items-center gap-2 rounded-2xl border border-slate-700 px-3 py-2 text-sm text-slate-200 transition hover:border-brand-400/60">
                <PaperClipIcon class="h-4 w-4" />
                <span>{{ uploading ? "Uploading…" : "Add files" }}</span>
                <input type="file" class="hidden" multiple @change="handleFiles" />
              </label>
            </div>

            <div v-if="uploading" class="mt-3 space-y-2">
              <div class="flex items-center justify-between text-xs text-slate-400">
                <span>Uploading {{ uploadingFileName || "file" }}…</span>
                <span>{{ uploadProgress }}%</span>
              </div>
              <div class="h-2 w-full rounded-full bg-slate-800/70">
                <div
                  class="h-full rounded-full bg-brand-500 transition-all"
                  :style="{ width: `${uploadProgress}%` }"
                />
              </div>
            </div>

            <ul v-if="attachments.length" class="mt-3 space-y-2 text-sm">
              <li
                v-for="file in attachments"
                :key="file.url"
                class="flex items-center justify-between rounded-xl bg-slate-900/60 px-3 py-2"
              >
                <span>{{ file.filename }}</span>
                <button class="text-xs text-rose-400 hover:underline" @click="removeAttachment(file.url)">
                  Remove
                </button>
              </li>
            </ul>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <button
            class="rounded-2xl border border-slate-700 px-4 py-2 text-sm text-slate-300 hover:border-slate-500"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            class="rounded-2xl bg-brand-500 px-5 py-2 text-sm font-semibold text-white shadow-lg shadow-brand-500/30 hover:bg-brand-400 disabled:opacity-50"
            :disabled="sending || uploading"
            @click="handleSend"
          >
            {{ sending ? "Sending…" : "Send now" }}
          </button>
        </div>
      </div>
    </div>
  </Transition>

  <!-- AI Prompt Dialog -->
  <AIPromptDialog
    :open="aiPromptOpen"
    :is-reply="!!props.context?.body"
    :previous-email="
      props.context?.body
        ? {
            subject: props.context.subject || '',
            body: props.context.body,
            from: props.context.to?.[0] || '',
            to: props.context.to || [],
          }
        : undefined
    "
    @close="aiPromptOpen = false"
    @generate="handleAIGenerate"
  />
</template>

<style scoped>
.slide-up-enter-active,
.slide-up-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
</style>

