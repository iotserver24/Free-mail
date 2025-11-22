<script setup lang="ts">
import { ArrowLeftIcon } from "@heroicons/vue/24/outline";

const route = useRoute();
const router = useRouter();
const mail = useMailStore();

watch(
  () => route.params.messageId,
  (newId) => {
    if (newId) {
      mail.selectMessage(newId as string);
    }
  },
  { immediate: true }
);

function goBack() {
  router.push(`/inbox/${route.params.id}`);
}
</script>

<template>
  <div class="flex h-full flex-col">
    <!-- Mobile Header with Back Button -->
    <div class="flex items-center gap-3 border-b border-white/5 bg-slate-900/50 px-4 py-3 lg:hidden">
      <button 
        class="-ml-2 rounded-full p-2 text-slate-400 hover:bg-white/5 hover:text-slate-200"
        @click="goBack"
      >
        <ArrowLeftIcon class="h-5 w-5" />
      </button>
      <span class="text-sm font-medium text-slate-200">Message</span>
    </div>

    <!-- Message Viewer -->
    <div class="flex-1 overflow-hidden">
      <MailMessageViewer :message="mail.messageDetail" />
    </div>
  </div>
</template>
