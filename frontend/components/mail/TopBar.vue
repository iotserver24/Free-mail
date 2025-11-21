<script setup lang="ts">
import { PencilSquareIcon, Cog6ToothIcon, ArrowRightStartOnRectangleIcon } from "@heroicons/vue/24/outline";
import type { EmailRecord } from "~/types/api";

const props = defineProps<{
  emails: EmailRecord[];
  activeInboxId: string | null;
  userEmail?: string;
}>();

const emit = defineEmits<{
  selectInbox: [inboxId: string];
  compose: [];
  settings: [];
  logout: [];
}>();

const selectedInbox = computed({
  get: () => props.activeInboxId ?? "",
  set: (value: string) => emit("selectInbox", value),
});
</script>

<template>
  <header class="flex items-center gap-4 border-b border-white/5 px-6 py-4 backdrop-blur">
    <div class="flex items-center gap-2">
      <div class="rounded-full bg-brand-500/20 p-2 text-brand-200">
        ✉️
      </div>
      <div>
        <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Free Mail</p>
        <p class="text-lg font-semibold">Gmail-style Workspace</p>
      </div>
    </div>

    <div class="flex flex-1 items-center gap-3 rounded-2xl border border-slate-800 bg-slate-900/60 px-4 py-2">
      <input
        type="search"
        placeholder="Search subject, sender, or body…"
        class="w-full bg-transparent text-sm text-slate-200 placeholder-slate-500 focus:outline-none"
      />
    </div>

    <div class="flex items-center gap-3">
      <div class="text-right">
        <p class="text-xs text-slate-400">Active identity</p>
        <select
          v-model="selectedInbox"
          :disabled="!emails.length"
          class="mt-1 rounded-xl border border-slate-700 bg-slate-900/80 px-3 py-2 text-sm text-slate-100 focus:border-brand-400 focus:outline-none disabled:opacity-50"
        >
          <option v-if="!emails.length" value="">No inboxes</option>
          <option v-for="email in emails" :key="email.id" :value="email.inbox_id">
            {{ email.email }}
          </option>
        </select>
      </div>

      <button
        class="rounded-2xl bg-brand-500/90 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-brand-500/40 transition hover:bg-brand-400"
        @click="emit('compose')"
      >
        <div class="flex items-center gap-2">
          <PencilSquareIcon class="h-4 w-4" />
          Compose
        </div>
      </button>

      <button
        class="rounded-2xl border border-slate-700/70 px-3 py-2 text-slate-300 transition hover:border-brand-400/60 hover:text-white"
        @click="emit('settings')"
      >
        <span class="flex items-center gap-2 text-sm">
          <Cog6ToothIcon class="h-4 w-4" />
          Settings
        </span>
      </button>

      <button
        class="rounded-2xl border border-slate-800/80 px-3 py-2 text-slate-400 transition hover:border-rose-500/40 hover:text-rose-200"
        @click="emit('logout')"
      >
        <span class="flex items-center gap-2 text-sm">
          <ArrowRightStartOnRectangleIcon class="h-4 w-4" />
          Sign out
        </span>
      </button>
    </div>
  </header>
</template>

