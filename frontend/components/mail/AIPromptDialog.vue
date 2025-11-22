<script setup lang="ts">
import { ref } from "vue";
import { SparklesIcon, XMarkIcon } from "@heroicons/vue/24/outline";

const props = defineProps<{
  open: boolean;
  isReply?: boolean;
  previousEmail?: {
    subject: string;
    body: string;
    from?: string;
    to?: string[];
  };
}>();

const emit = defineEmits<{
  close: [];
  generate: [prompt: string];
}>();

const prompt = ref("");
const isGenerating = ref(false);

function handleGenerate() {
  if (!prompt.value.trim()) return;
  isGenerating.value = true;
  emit("generate", prompt.value);
}

function handleClose() {
  prompt.value = "";
  isGenerating.value = false;
  emit("close");
}
</script>

<template>
  <Transition name="fade">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
      @click.self="handleClose"
    >
      <div
        class="w-full max-w-lg overflow-hidden rounded-2xl border border-purple-500/30 bg-gradient-to-br from-slate-900 via-purple-900/10 to-slate-900 shadow-2xl shadow-purple-500/20"
      >
        <!-- Header -->
        <div
          class="border-b border-purple-500/20 bg-gradient-to-r from-purple-600/10 to-pink-600/10 px-6 py-4 backdrop-blur-sm"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 p-2">
                <SparklesIcon class="h-5 w-5 text-white" />
              </div>
              <div>
                <h2 class="text-lg font-bold text-white">AI Email Writer</h2>
                <p class="text-xs text-slate-400">
                  {{ isReply ? "How would you like to reply?" : "How should I write this email?" }}
                </p>
              </div>
            </div>
            <button
              class="rounded-full p-1.5 text-slate-400 transition hover:bg-slate-800 hover:text-white"
              @click="handleClose"
            >
              <XMarkIcon class="h-5 w-5" />
            </button>
          </div>
        </div>

        <!-- Content -->
        <div class="p-6">
          <div class="space-y-4">
            <div>
              <label class="mb-2 block text-sm font-medium text-slate-300">
                {{ isReply ? "How do you want to reply?" : "What should the email say?" }}
              </label>
              <textarea
                v-model="prompt"
                rows="4"
                :placeholder="
                  isReply
                    ? 'E.g., Thank them for the email and confirm the meeting time...'
                    : 'E.g., Request a meeting next week to discuss the project...'
                "
                class="w-full rounded-xl border border-slate-700 bg-slate-900/60 px-4 py-3 text-sm text-white placeholder-slate-500 focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20"
                :disabled="isGenerating"
              ></textarea>
            </div>

            <div v-if="isReply && previousEmail" class="rounded-xl border border-slate-700/50 bg-slate-800/40 p-3">
              <p class="mb-2 text-xs font-medium uppercase tracking-wider text-slate-500">Previous Email</p>
              <p class="text-xs font-semibold text-slate-300">{{ previousEmail.subject }}</p>
              <p class="mt-1 line-clamp-2 text-xs text-slate-400">{{ previousEmail.body }}</p>
            </div>

            <div class="flex items-center justify-end gap-3">
              <button
                class="rounded-xl border border-slate-700 px-4 py-2 text-sm text-slate-300 transition hover:border-slate-500 hover:bg-slate-800"
                :disabled="isGenerating"
                @click="handleClose"
              >
                Cancel
              </button>
              <button
                class="rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 px-5 py-2 text-sm font-semibold text-white shadow-lg shadow-purple-500/30 transition hover:shadow-purple-500/50 disabled:opacity-50"
                :disabled="isGenerating || !prompt.trim()"
                @click="handleGenerate"
              >
                <span v-if="!isGenerating" class="flex items-center gap-2">
                  <SparklesIcon class="h-4 w-4" />
                  Generate
                </span>
                <span v-else class="flex items-center gap-2">
                  <svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Generating...
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>

