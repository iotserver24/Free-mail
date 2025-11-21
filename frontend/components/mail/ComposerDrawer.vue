<script setup lang="ts">
import { reactive, ref, watch } from "vue";
import { XMarkIcon, PaperClipIcon } from "@heroicons/vue/24/outline";
import type { EmailRecord } from "../../types/api";
import type { ComposePayload, AttachmentPayload } from "../../types/messaging";
import { uploadToCatbox } from "../../lib/catbox";
import { useToasts } from "../../composables/useToasts";

const props = defineProps<{
  open: boolean;
  emails: EmailRecord[];
  activeInboxId: string | null;
  submit?: (payload: ComposePayload) => Promise<void> | void;
}>();

const emit = defineEmits<{
  close: [];
}>();

const toasts = useToasts();

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
const sending = ref(false);

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

function resetForm() {
  form.to = "";
  form.cc = "";
  form.bcc = "";
  form.subject = "";
  form.body = "";
  attachments.value = [];
}

watch(
  () => props.open,
  (isOpen) => {
    if (!isOpen) {
      resetForm();
    }
  }
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
    try {
      const result = await uploadToCatbox(file);
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
            <label class="text-xs text-slate-500">Message</label>
            <textarea
              v-model="form.body"
              rows="6"
              placeholder="Write your message…"
              class="mt-1 w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-3 py-3 text-sm focus:border-brand-400 focus:outline-none"
            />
          </div>

          <div class="rounded-2xl border border-dashed border-slate-700/80 p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-semibold">Attachments via Catbox</p>
                <p class="text-xs text-slate-500">
                  Files upload directly to catbox.moe (reqtype=fileupload) before sending.
                </p>
              </div>
              <label class="inline-flex cursor-pointer items-center gap-2 rounded-2xl border border-slate-700 px-3 py-2 text-sm text-slate-200 transition hover:border-brand-400/60">
                <PaperClipIcon class="h-4 w-4" />
                <span>{{ uploading ? "Uploading…" : "Add files" }}</span>
                <input type="file" class="hidden" multiple @change="handleFiles" />
              </label>
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

