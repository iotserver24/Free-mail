<script setup lang="ts">
import { PencilSquareIcon, Cog6ToothIcon, ArrowRightStartOnRectangleIcon } from "@heroicons/vue/24/outline";
import type { EmailRecord } from "~/types/api";
import { useAuthStore } from "~/stores/auth";

const authStore = useAuthStore();

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
  <header class="flex items-center justify-between gap-4 border-b border-white/10 bg-slate-950/80 px-4 py-3 backdrop-blur-xl md:px-6">
    <!-- Left Section: Logo + Search -->
    <div class="flex flex-1 items-center gap-4">
      <!-- Logo -->
      <div class="flex items-center gap-2">
        <img
          src="/logo.png"
          alt="Free Mail Logo"
          class="h-9 w-9 rounded-lg object-cover shadow-lg shadow-brand-500/30"
          loading="lazy"
        />
        <span class="hidden text-sm font-bold text-white md:block">Free Mail</span>
      </div>

      <!-- Search Bar -->
      <div class="hidden flex-1 items-center gap-3 rounded-xl border border-slate-800/80 bg-slate-900/60 px-4 py-2 transition-all focus-within:border-brand-500/50 focus-within:bg-slate-900/80 md:flex md:max-w-xl">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4 text-slate-500">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
        </svg>
        <input
          type="search"
          placeholder="Search messages..."
          class="w-full bg-transparent text-sm text-slate-200 placeholder-slate-500 focus:outline-none"
        />
      </div>
    </div>

    <!-- Right Section: Actions -->
    <div class="flex items-center gap-2">
      <!-- Inbox Switcher (Desktop) -->
      <div class="hidden lg:block">
        <MailInboxSwitcher
          :emails="emails"
          :active-inbox-id="activeInboxId"
          @select="(id) => emit('selectInbox', id)"
        />
      </div>

      <!-- Compose Button -->
      <button
        class="flex items-center gap-2 rounded-xl bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-brand-500/30 transition-all hover:bg-brand-400 hover:shadow-brand-500/40"
        @click="emit('compose')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-4 w-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" />
        </svg>
        <span class="hidden sm:inline">Compose</span>
      </button>

      <!-- Admin Dashboard (Desktop) -->
      <NuxtLink
        v-if="authStore.isAdmin"
        to="/admin"
        class="hidden items-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/40 px-3 py-2.5 text-sm text-slate-300 transition-all hover:border-blue-500/40 hover:bg-blue-500/5 hover:text-blue-300 md:flex"
        title="Admin Dashboard"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
        </svg>
        <span class="hidden lg:inline">Admin</span>
      </NuxtLink>

      <!-- Settings (Desktop) -->
      <button
        class="hidden items-center gap-2 rounded-xl border border-slate-700/80 bg-slate-900/40 px-3 py-2.5 text-sm text-slate-300 transition-all hover:border-slate-600 hover:bg-slate-800/60 hover:text-white md:flex"
        @click="emit('settings')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      </button>

      <!-- User Menu / Logout (Desktop) -->
      <button
        class="hidden items-center gap-2 rounded-xl border border-slate-800/80 bg-slate-900/40 px-3 py-2.5 text-sm text-slate-400 transition-all hover:border-rose-500/40 hover:bg-rose-500/5 hover:text-rose-300 md:flex"
        @click="emit('logout')"
      >
        <img
          v-if="authStore.user?.avatarUrl"
          :src="authStore.user.avatarUrl"
          alt="Avatar"
          class="h-5 w-5 rounded-full object-cover"
        />
        <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-4 w-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
        </svg>
        <span class="hidden lg:inline">Logout</span>
      </button>

      <!-- Mobile Menu Button -->
      <button
        class="flex items-center justify-center rounded-xl border border-slate-700/80 bg-slate-900/40 p-2.5 text-slate-300 transition-all hover:border-slate-600 hover:bg-slate-800/60 md:hidden"
        @click="emit('settings')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-5 w-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
        </svg>
      </button>
    </div>
  </header>
</template>

