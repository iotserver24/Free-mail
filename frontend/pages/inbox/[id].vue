<script setup lang="ts">
const route = useRoute();
const router = useRouter();
const mail = useMailStore();

const inboxId = computed(() => route.params.id as string);
const isMessageView = computed(() => route.name && String(route.name).includes('message-messageId'));

// Load messages for this inbox
watch(inboxId, (newId) => {
  if (newId) {
    mail.setActiveInbox(newId);
  }
}, { immediate: true });

function handleSelectMessage(messageId: string) {
  router.push(`/inbox/${inboxId.value}/message/${messageId}`);
}
</script>

<template>
  <div class="flex h-full w-full overflow-hidden">
    <!-- Message List Column -->
    <!-- Hidden on mobile if viewing a message -->
    <div 
      class="flex h-full w-full flex-col border-r border-white/10 bg-slate-950/40 lg:w-[30%] lg:min-w-[320px] overflow-hidden"
      :class="{ 'hidden lg:flex': isMessageView }"
    >
      <MailMessageList
        :messages="mail.messages"
        :selected-id="String(route.params.messageId || '')"
        :loading="mail.loadingMessages"
        @select="handleSelectMessage"
      />
    </div>

    <!-- Message Content Column -->
    <!-- Hidden on mobile if NOT viewing a message -->
    <div 
      class="h-full w-full flex-1 bg-slate-950/80 overflow-hidden"
      :class="{ 'hidden lg:block': !isMessageView }"
    >
      <NuxtPage />
    </div>
  </div>
</template>
