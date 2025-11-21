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
</script>

<template>
  <div class="flex h-full flex-col border-r border-white/5 bg-slate-950/40">
    <div class="flex items-center justify-between border-b border-white/5 px-6 py-3">
      <p class="text-sm font-semibold text-slate-300">Conversations</p>
      <span class="text-xs text-slate-500">{{ messages.length }} threads</span>
    </div>

    <div class="flex-1 overflow-y-auto">
      <div v-if="loading" class="p-6 text-sm text-slate-500">
        Loading messages…
      </div>
      <div v-else-if="!messages.length" class="p-6 text-sm text-slate-500">
        No messages yet. Send the first email from this inbox.
      </div>
      <ul v-else class="divide-y divide-white/5">
        <li v-for="message in messages" :key="message.id">
          <button
            class="flex w-full flex-col gap-1 px-6 py-4 text-left transition"
            :class="[
              message.id === selectedId
                ? 'bg-brand-500/5 text-white'
                : 'hover:bg-slate-900/60 text-slate-200',
            ]"
            @click="emit('select', message.id)"
          >
            <div class="flex items-center justify-between text-sm">
              <p class="font-semibold">
                {{ message.subject || "No subject" }}
              </p>
              <span class="text-xs text-slate-500">
                {{ formatShortDate(message.created_at) }}
              </span>
            </div>
            <p class="text-xs uppercase tracking-wide text-slate-500">
              {{ message.sender_email || message.recipient_emails?.[0] || "Unknown" }}
            </p>
            <p class="text-sm text-slate-400 line-clamp-2">
              {{ message.preview_text || message.body_plain || "—" }}
            </p>
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>

