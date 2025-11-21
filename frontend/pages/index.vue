<script setup lang="ts">
const router = useRouter();
const auth = useAuthStore();
const mail = useMailStore();
const bootstrapError = ref<string | null>(null);

try {
  await mail.bootstrap();
} catch (error) {
  console.error("Failed to bootstrap mailbox", error);
  bootstrapError.value =
    (error as { data?: { error?: string } }).data?.error ||
    (error as Error).message ||
    "Unable to reach the backend API.";
}

function handleSelectMessage(id: string) {
  mail.selectMessage(id);
}

function goToSettings() {
  router.push("/settings");
}

async function handleSend(payload: any) {
  await mail.sendMessage(payload);
}

async function handleLogout() {
  await auth.logout();
  await router.push("/login");
}
</script>

<template>
  <div class="flex min-h-screen flex-col">
    <MailTopBar
      :emails="mail.emails"
      :active-inbox-id="mail.activeInboxId"
      :user-email="auth.currentEmail"
      @select-inbox="mail.setActiveInbox"
      @compose="mail.toggleComposer(true)"
      @settings="goToSettings"
      @logout="handleLogout"
    />

    <div class="flex flex-1 bg-slate-950/80 text-slate-100">
      <div
        v-if="bootstrapError"
        class="mx-auto flex max-w-xl flex-col items-center justify-center text-center"
      >
        <p class="text-rose-300">We couldn't reach the backend API.</p>
        <p class="mt-2 text-sm text-slate-400">
          {{ bootstrapError }}
        </p>
        <p class="mt-4 text-sm text-slate-500">
          Make sure the Express backend is running and `NUXT_PUBLIC_API_BASE` points to it, then refresh.
        </p>
      </div>
      <template v-else>
        <MailSidebar
          :buckets="mail.inboxBuckets"
          :active-inbox-id="mail.activeInboxId"
          :domains="mail.domains"
          @select="mail.setActiveInbox"
        />
        <div class="grid flex-1 grid-cols-2 lg:grid-cols-3">
          <MailMessageList
            :messages="mail.messages"
            :selected-id="mail.selectedMessageId"
            :loading="mail.loadingMessages"
            @select="handleSelectMessage"
          />
          <div class="col-span-2 hidden border-l border-white/5 lg:block">
            <MailMessageViewer :message="mail.messageDetail" />
          </div>
          <div class="col-span-2 border-t border-white/5 lg:hidden">
            <MailMessageViewer :message="mail.messageDetail" />
          </div>
        </div>
      </template>
    </div>

    <MailComposerDrawer
      :open="mail.composerOpen"
      :emails="mail.emails"
      :active-inbox-id="mail.activeInboxId"
      :context="mail.composerContext"
      :submit="handleSend"
      @close="mail.toggleComposer(false)"
    />
  </div>
</template>

