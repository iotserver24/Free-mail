<script setup lang="ts">
const router = useRouter();
const auth = useAuthStore();
const mail = useMailStore();

// Bootstrap mail store if needed (e.g. on hard refresh)
if (!mail.bootstrapped && auth.isAuthenticated) {
  mail.bootstrap();
}

function handleSelectInbox(id: string) {
  mail.setActiveInbox(id);
  // Navigate to the inbox route
  router.push(`/inbox/${id}`);
}

function goToSettings() {
  router.push("/settings");
}

async function handleLogout() {
  await auth.logout();
  await router.push("/login");
}

async function handleSend(payload: any) {
  await mail.sendMessage(payload);
}
</script>

<template>
  <div class="flex h-screen flex-col bg-slate-950 text-slate-100">
    <MailTopBar
      v-if="auth.isAuthenticated"
      :emails="mail.emails"
      :active-inbox-id="mail.activeInboxId"
      :user-email="auth.currentEmail"
      @select-inbox="handleSelectInbox"
      @compose="mail.toggleComposer(true)"
      @settings="goToSettings"
      @logout="handleLogout"
    />

    <main class="flex flex-1 overflow-hidden">
      <slot />
    </main>

    <MailComposerDrawer
      v-if="auth.isAuthenticated"
      :open="mail.composerOpen"
      :emails="mail.emails"
      :active-inbox-id="mail.activeInboxId"
      :context="mail.composerContext"
      :submit="handleSend"
      @close="mail.toggleComposer(false)"
    />
    
    <UiToastStack />
  </div>
</template>

