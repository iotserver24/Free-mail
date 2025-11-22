<script setup lang="ts">
import { ref, computed, reactive } from "vue";
import { SparklesIcon, XMarkIcon, ArrowPathIcon, CheckIcon } from "@heroicons/vue/24/outline";

const props = defineProps<{
  open: boolean;
  conversationContext?: Array<{ role: string; content: string; timestamp?: string }>;
}>();

const emit = defineEmits<{
  close: [];
  apply: [{ subject: string; body: string }];
}>();

interface AISettings {
  tone: "professional" | "casual" | "formal" | "friendly";
  priority: "high" | "medium" | "low";
  useContext: boolean;
}

const topic = ref("");
const streamedContent = ref("");
const isStreaming = ref(false);
const error = ref<string | null>(null);
const parsedEmail = ref<{ subject: string; body: string; tone?: string; priority?: string } | null>(null);

const settings = reactive<AISettings>({
  tone: "professional",
  priority: "medium",
  useContext: true,
});

const examplePrompts = [
  "Request for meeting next Tuesday at 2 PM",
  "Follow up on proposal sent last week",
  "Thank you for the interview opportunity",
  "Request deadline extension for project",
  "Schedule team meeting for sprint planning",
];

const toneOptions = [
  { value: "professional", label: "🎯 Professional", description: "Clear and business-like" },
  { value: "casual", label: "😊 Casual", description: "Friendly and relaxed" },
  { value: "formal", label: "👔 Formal", description: "Very polite and structured" },
  { value: "friendly", label: "🤝 Friendly", description: "Warm and approachable" },
];

const priorityOptions = [
  { value: "high", label: "🔴 High", color: "text-red-400" },
  { value: "medium", label: "🟡 Medium", color: "text-yellow-400" },
  { value: "low", label: "🟢 Low", color: "text-green-400" },
];

function useExamplePrompt(prompt: string) {
  topic.value = prompt;
}

function parseEmailXML(xmlString: string) {
  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(xmlString, "text/xml");

    const subject = doc.querySelector("subject")?.textContent || "";
    const bodyElement = doc.querySelector("body");
    let body = "";

    if (bodyElement) {
      // Get all paragraph tags or the entire body text
      const paragraphs = bodyElement.querySelectorAll("p");
      if (paragraphs.length > 0) {
        body = Array.from(paragraphs)
          .map((p) => p.textContent)
          .join("\n\n");
      } else {
        body = bodyElement.textContent || "";
      }
    }

    const tone = doc.querySelector("metadata tone")?.textContent || "";
    const priority = doc.querySelector("metadata priority")?.textContent || "";

    return { subject, body, tone, priority };
  } catch (err) {
    console.error("XML parsing error:", err);
    return null;
  }
}

async function generateEmail() {
  if (!topic.value.trim()) {
    error.value = "Please enter a topic";
    return;
  }

  streamedContent.value = "";
  parsedEmail.value = null;
  error.value = null;
  isStreaming.value = true;

  try {
    const requestBody: any = {
      topic: topic.value,
    };

    if (settings.useContext && props.conversationContext) {
      requestBody.conversationContext = props.conversationContext;
    }

    const response = await fetch("/api/ai/generate-email-stream", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split("\n");

      lines.forEach((line) => {
        if (line.startsWith("data: ")) {
          try {
            const data = JSON.parse(line.slice(6));

            if (data.content) {
              streamedContent.value += data.content;
            } else if (data.done) {
              isStreaming.value = false;
              // Parse the complete XML
              const parsed = parseEmailXML(streamedContent.value);
              if (parsed) {
                parsedEmail.value = parsed;
              }
            } else if (data.error) {
              throw new Error(data.error);
            }
          } catch (err) {
            console.error("JSON parse error:", err);
          }
        }
      });
    }
  } catch (err: any) {
    error.value = err.message || "Failed to generate email";
    isStreaming.value = false;
  }
}

function applyEmail() {
  if (parsedEmail.value) {
    emit("apply", {
      subject: parsedEmail.value.subject,
      body: parsedEmail.value.body,
    });
    reset();
    emit("close");
  }
}

function reset() {
  topic.value = "";
  streamedContent.value = "";
  parsedEmail.value = null;
  error.value = null;
  isStreaming.value = false;
}

function handleClose() {
  reset();
  emit("close");
}
</script>

<template>
  <Transition name="fade">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm"
      @click.self="handleClose"
    >
      <div
        class="w-full max-w-4xl overflow-hidden rounded-3xl border border-purple-500/30 bg-gradient-to-br from-slate-900 via-purple-900/10 to-slate-900 shadow-2xl shadow-purple-500/20"
      >
        <!-- Header -->
        <div
          class="border-b border-purple-500/20 bg-gradient-to-r from-purple-600/10 to-pink-600/10 px-6 py-4 backdrop-blur-sm"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="rounded-2xl bg-gradient-to-br from-purple-500 to-pink-500 p-2">
                <SparklesIcon class="h-6 w-6 text-white" />
              </div>
              <div>
                <h2 class="text-xl font-bold text-white">AI Email Writer</h2>
                <p class="text-sm text-slate-400">Let AI craft the perfect email for you</p>
              </div>
            </div>
            <button
              class="rounded-full p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white"
              @click="handleClose"
            >
              <XMarkIcon class="h-6 w-6" />
            </button>
          </div>
        </div>

        <div class="grid gap-6 p-6 md:grid-cols-2">
          <!-- Left Column: Input -->
          <div class="space-y-4">
            <!-- Topic Input -->
            <div>
              <label class="mb-2 block text-sm font-medium text-slate-300">What do you want to write about?</label>
              <textarea
                v-model="topic"
                rows="3"
                placeholder="E.g., Request meeting for next week to discuss project timeline..."
                class="w-full rounded-2xl border border-slate-700 bg-slate-900/60 px-4 py-3 text-sm text-white placeholder-slate-500 focus:border-purple-500 focus:outline-none focus:ring-2 focus:ring-purple-500/20"
              ></textarea>
            </div>

            <!-- Example Prompts -->
            <div>
              <p class="mb-2 text-xs font-medium uppercase tracking-wider text-slate-500">Quick Examples</p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="(prompt, idx) in examplePrompts"
                  :key="idx"
                  class="rounded-xl border border-slate-700 bg-slate-800/40 px-3 py-1.5 text-xs text-slate-300 transition hover:border-purple-500/50 hover:bg-slate-800"
                  @click="useExamplePrompt(prompt)"
                >
                  {{ prompt }}
                </button>
              </div>
            </div>

            <!-- Settings -->
            <div class="space-y-3">
              <!-- Tone Selection -->
              <div>
                <p class="mb-2 text-xs font-medium uppercase tracking-wider text-slate-500">Tone</p>
                <div class="grid grid-cols-2 gap-2">
                  <button
                    v-for="tone in toneOptions"
                    :key="tone.value"
                    class="rounded-xl border px-3 py-2 text-left text-xs transition"
                    :class="
                      settings.tone === tone.value
                        ? 'border-purple-500 bg-purple-500/10 text-white'
                        : 'border-slate-700 bg-slate-800/40 text-slate-400 hover:border-slate-600'
                    "
                    @click="settings.tone = tone.value as any"
                  >
                    <div class="font-medium">{{ tone.label }}</div>
                    <div class="mt-0.5 text-[10px] text-slate-500">{{ tone.description }}</div>
                  </button>
                </div>
              </div>

              <!-- Priority Selection -->
              <div>
                <p class="mb-2 text-xs font-medium uppercase tracking-wider text-slate-500">Priority</p>
                <div class="flex gap-2">
                  <button
                    v-for="priority in priorityOptions"
                    :key="priority.value"
                    class="flex-1 rounded-xl border px-3 py-2 text-xs font-medium transition"
                    :class="[
                      settings.priority === priority.value
                        ? 'border-purple-500 bg-purple-500/10 text-white'
                        : 'border-slate-700 bg-slate-800/40 text-slate-400 hover:border-slate-600',
                    ]"
                    @click="settings.priority = priority.value as any"
                  >
                    {{ priority.label }}
                  </button>
                </div>
              </div>

              <!-- Use Context Toggle -->
              <div
                v-if="conversationContext && conversationContext.length > 0"
                class="flex items-center gap-3 rounded-xl border border-slate-700 bg-slate-800/40 px-4 py-3"
              >
                <input
                  id="useContext"
                  v-model="settings.useContext"
                  type="checkbox"
                  class="h-4 w-4 rounded border-slate-600 bg-slate-700 text-purple-500 focus:ring-2 focus:ring-purple-500/20"
                />
                <label for="useContext" class="text-xs text-slate-300">
                  Use conversation context ({{ conversationContext.length }} messages)
                </label>
              </div>
            </div>

            <!-- Generate Button -->
            <button
              class="group relative w-full overflow-hidden rounded-2xl bg-gradient-to-r from-purple-600 to-pink-600 px-6 py-3 font-semibold text-white shadow-lg shadow-purple-500/30 transition hover:shadow-purple-500/50 disabled:opacity-50"
              :disabled="isStreaming || !topic.trim()"
              @click="generateEmail"
            >
              <span v-if="!isStreaming" class="flex items-center justify-center gap-2">
                <SparklesIcon class="h-5 w-5" />
                Generate Email
              </span>
              <span v-else class="flex items-center justify-center gap-2">
                <ArrowPathIcon class="h-5 w-5 animate-spin" />
                AI is thinking...
              </span>
            </button>
          </div>

          <!-- Right Column: Preview -->
          <div class="flex flex-col">
            <div class="mb-2 flex items-center justify-between">
              <p class="text-xs font-medium uppercase tracking-wider text-slate-500">Preview</p>
              <div v-if="isStreaming" class="flex items-center gap-2 text-xs text-purple-400">
                <div class="h-2 w-2 animate-pulse rounded-full bg-purple-400"></div>
                Streaming...
              </div>
            </div>

            <div
              class="flex-1 overflow-y-auto rounded-2xl border border-slate-700 bg-slate-900/60 p-4"
              style="max-height: 500px"
            >
              <!-- Error Message -->
              <div
                v-if="error"
                class="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400"
              >
                ⚠️ {{ error }}
              </div>

              <!-- Streaming Content (Raw XML) -->
              <div v-else-if="isStreaming && streamedContent" class="space-y-2">
                <div class="text-xs font-medium text-slate-500">Raw Output:</div>
                <pre
                  class="whitespace-pre-wrap break-words font-mono text-xs text-slate-400"
                >{{ streamedContent }}</pre>
              </div>

              <!-- Parsed Email (After completion) -->
              <div v-else-if="parsedEmail" class="space-y-4">
                <div>
                  <div class="mb-1 text-xs font-medium text-slate-500">Subject</div>
                  <div
                    class="rounded-xl border border-purple-500/30 bg-purple-500/5 px-3 py-2 text-sm font-medium text-white"
                  >
                    {{ parsedEmail.subject }}
                  </div>
                </div>

                <div>
                  <div class="mb-1 text-xs font-medium text-slate-500">Body</div>
                  <div class="rounded-xl border border-slate-700 bg-slate-800/40 px-3 py-3 text-sm text-slate-200">
                    <p
                      v-for="(line, idx) in parsedEmail.body.split('\n\n')"
                      :key="idx"
                      class="mb-2 last:mb-0"
                    >
                      {{ line }}
                    </p>
                  </div>
                </div>

                <div v-if="parsedEmail.tone || parsedEmail.priority" class="flex gap-2">
                  <span
                    v-if="parsedEmail.tone"
                    class="rounded-lg bg-slate-800/60 px-2 py-1 text-xs text-slate-400"
                  >
                    Tone: {{ parsedEmail.tone }}
                  </span>
                  <span
                    v-if="parsedEmail.priority"
                    class="rounded-lg bg-slate-800/60 px-2 py-1 text-xs text-slate-400"
                  >
                    Priority: {{ parsedEmail.priority }}
                  </span>
                </div>

                <!-- Apply Button -->
                <button
                  class="flex w-full items-center justify-center gap-2 rounded-2xl bg-green-600 px-4 py-3 font-semibold text-white shadow-lg shadow-green-500/30 transition hover:bg-green-500"
                  @click="applyEmail"
                >
                  <CheckIcon class="h-5 w-5" />
                  Use This Email
                </button>
              </div>

              <!-- Empty State -->
              <div v-else class="flex h-full items-center justify-center text-center text-sm text-slate-500">
                <div>
                  <SparklesIcon class="mx-auto mb-2 h-12 w-12 text-slate-700" />
                  <p>Your AI-generated email will appear here</p>
                </div>
              </div>
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
