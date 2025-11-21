<script setup lang="ts">
import type { DomainRecord, EmailRecord, InboxRecord } from "~/types/api";
import { formatShortDate } from "~/lib/formatters";

const props = defineProps<{
  buckets: {
    email: EmailRecord;
    inbox?: InboxRecord;
  }[];
  activeInboxId: string | null;
  domains: DomainRecord[];
}>();

const emit = defineEmits<{
  select: [inboxId: string];
}>();
</script>

<template>
  <aside class="flex w-80 flex-col gap-6 border-r border-white/5 bg-slate-950/60 p-6">
    <div>
      <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Custom domains</p>
      <div class="mt-3 space-y-3">
        <div
          v-for="domain in domains"
          :key="domain.id"
          class="rounded-2xl border border-slate-800/80 bg-slate-900/40 px-4 py-3"
        >
          <p class="text-sm font-semibold text-slate-100">{{ domain.domain }}</p>
          <p class="text-xs text-slate-500">Added {{ formatShortDate(domain.created_at) }}</p>
        </div>
        <p v-if="!domains.length" class="text-sm text-slate-500">
          No domains yet. Add one from settings.
        </p>
      </div>
    </div>

    <div class="space-y-3">
      <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Inboxes</p>
      <div class="space-y-2">
        <button
          v-for="bucket in buckets"
          :key="bucket.email.id"
          class="w-full rounded-2xl border px-4 py-3 text-left transition"
          :class="[
            bucket.email.inbox_id === activeInboxId
              ? 'border-brand-500/80 bg-brand-500/10 text-white'
              : 'border-slate-800/60 bg-slate-900/40 text-slate-300 hover:border-slate-700',
          ]"
          @click="emit('select', bucket.email.inbox_id)"
        >
          <p class="text-sm font-semibold">
            {{ bucket.email.email }}
          </p>
          <p class="text-xs text-slate-400">
            {{ bucket.inbox?.name || "Primary inbox" }}
          </p>
        </button>
      </div>
      <p v-if="!buckets.length" class="text-sm text-slate-500">
        Create an email address to unlock inboxes.
      </p>
    </div>
  </aside>
</template>

