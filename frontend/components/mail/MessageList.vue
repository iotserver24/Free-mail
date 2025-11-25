<script setup lang="ts">
import type { MessageRecord } from "~/types/api";
import { formatShortDate } from "~/lib/formatters";

const props = defineProps<{
  messages: MessageRecord[];
  selectedId: string | null;
  loading?: boolean;
}>();

const emit = defineEmits<{
  select: [messageId: string];
}>();

function getInitials(email: string | null | undefined): string {
  if (!email) return "?";
  const name = email.split("@")[0];
  if (!name) return "?";
  return name.substring(0, 2).toUpperCase();
}

function getSenderDisplay(message: MessageRecord): string {
  if (message.direction === "outbound") {
    return message.recipient_emails?.[0] || "Unknown";
  }
  return message.sender_email || "Unknown";
}

function getAvatarColor(email: string | null | undefined): string {
  if (!email) return "bg-slate-700";
  const colors = [
    "bg-blue-500",
    "bg-purple-500",
    "bg-pink-500",
    "bg-green-500",
    "bg-yellow-500",
    "bg-red-500",
    "bg-indigo-500",
    "bg-teal-500",
  ];
  const hash = email.split("").reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return colors[hash % colors.length] || "bg-slate-700";
}
</script>

<template>
  <div class="flex h-full flex-col bg-slate-950/40">
    <!-- Header -->
    <div class="flex items-center justify-between bg-slate-950/60 px-5 py-4 backdrop-blur-sm">
      <div>
        <p class="text-sm font-bold text-slate-200">Inbox</p>
        <p class="text-xs text-slate-500">{{ messages.length }} message{{ messages.length !== 1 ? 's' : '' }}</p>
      </div>
      <button class="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-slate-200">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
        </svg>
      </button>
    </div>

    <!-- Message List -->
    <div class="flex-1 overflow-y-auto">
      <!-- Loading State -->
      <div v-if="loading" class="flex flex-col items-center justify-center gap-3 p-12 text-slate-500">
        <svg class="h-8 w-8 animate-spin text-brand-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="text-sm">Loading messages...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="!messages.length" class="flex flex-col items-center justify-center gap-4 p-12 text-center">
        <div class="rounded-full bg-slate-900/60 p-6">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1" stroke="currentColor" class="h-12 w-12 text-slate-600">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 9v.906a2.25 2.25 0 01-1.183 1.981l-6.478 3.488M2.25 9v.906a2.25 2.25 0 001.183 1.981l6.478 3.488m8.839 2.51l-4.66-2.51m0 0l-1.023-.55a2.25 2.25 0 00-2.134 0l-1.022.55m0 0l-4.661 2.51m16.5 1.615a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V8.844a2.25 2.25 0 011.183-1.98l7.5-4.04a2.25 2.25 0 012.134 0l7.5 4.04a2.25 2.25 0 011.183 1.98V19.5z" />
          </svg>
        </div>
        <div>
          <p class="text-sm font-medium text-slate-400">Your inbox is empty</p>
          <p class="mt-1 text-xs text-slate-500">New messages will appear here</p>
        </div>
      </div>

      <!-- Messages -->
      <ul v-else class="divide-y divide-white/5">
        <li v-for="message in messages" :key="message.id">
          <button
            class="group flex w-full items-start gap-4 px-5 py-4 text-left transition-all"
            :class="[
              message.id === selectedId
                ? 'bg-brand-500/10 border-l-2 border-brand-500'
                : 'hover:bg-slate-900/60 border-l-2 border-transparent',
            ]"
            @click="emit('select', message.id)"
          >
              <div 
                class="relative flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full text-xs font-bold text-white shadow-lg"
                :class="getAvatarColor(message.sender_email || message.recipient_emails?.[0])"
              >
                {{ getInitials(getSenderDisplay(message)) }}
                <span v-if="!message.is_read" class="absolute -right-0.5 -top-0.5 h-3 w-3 rounded-full border-2 border-slate-900 bg-brand-500"></span>
              </div>

            <!-- Message Content -->
            <div class="flex-1 overflow-hidden">
              <!-- Header Row -->
              <div class="flex items-baseline justify-between gap-2">
                <p 
                  class="truncate text-sm"
                  :class="[
                    message.id === selectedId ? 'text-white font-semibold' : 'group-hover:text-white',
                    !message.is_read && message.id !== selectedId ? 'text-white font-bold' : 'text-slate-200 font-medium'
                  ]"
                >
                  {{ getSenderDisplay(message) }}
                </p>
                <span 
                  class="flex-shrink-0 text-xs"
                  :class="!message.is_read ? 'text-brand-400 font-medium' : 'text-slate-500'"
                >
                  {{ formatShortDate(message.created_at) }}
                </span>
              </div>

              <!-- Subject -->
              <p 
                class="mt-1 truncate text-sm"
                :class="[
                  message.id === selectedId ? 'text-slate-200' : 'group-hover:text-slate-300',
                  !message.is_read ? 'text-white font-semibold' : 'text-slate-400 font-medium'
                ]"
              >
                {{ message.subject || "(No subject)" }}
              </p>

              <!-- Preview -->
              <p class="mt-1 line-clamp-2 text-xs leading-relaxed text-slate-500">
                {{ message.preview_text || message.body_plain || "No preview available" }}
              </p>

              <!-- Tags/Indicators -->
              <div class="mt-2 flex items-center gap-2">
                <span 
                  v-if="message.direction === 'outbound'" 
                  class="inline-flex items-center gap-1 rounded-full bg-purple-500/10 px-2 py-0.5 text-xs font-medium text-purple-400"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-3 w-3">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
                  </svg>
                  Sent
                </span>
                <span 
                  v-if="message.attachments?.length" 
                  class="inline-flex items-center gap-1 rounded-full bg-slate-800/60 px-2 py-0.5 text-xs font-medium text-slate-400"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-3 w-3">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M18.375 12.739l-7.693 7.693a4.5 4.5 0 01-6.364-6.364l10.94-10.94A3 3 0 1119.5 7.372L8.552 18.32m.009-.01l-.01.01m5.699-9.941l-7.81 7.81a1.5 1.5 0 002.112 2.13" />
                  </svg>
                  {{ message.attachments.length }}
                </span>
              </div>
            </div>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
/* Custom scrollbar for message list */
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
