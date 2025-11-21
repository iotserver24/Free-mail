<script setup lang="ts">
const { toasts, dismiss } = useToasts();
</script>

<template>
  <div class="pointer-events-none fixed inset-x-0 top-3 z-50 flex flex-col items-center gap-2 px-4">
    <TransitionGroup name="toast" tag="div" class="w-full max-w-md space-y-2">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        class="pointer-events-auto rounded-xl border border-slate-700/80 bg-slate-900/90 px-4 py-3 shadow-2xl shadow-black/40 backdrop-blur"
      >
        <div class="flex items-start gap-3">
          <span
            class="mt-1 h-2.5 w-2.5 shrink-0 rounded-full"
            :class="{
              'bg-emerald-400': toast.variant === 'success',
              'bg-rose-400': toast.variant === 'error',
              'bg-sky-400': toast.variant === 'info',
            }"
          />
          <div class="flex-1 text-sm">
            <p class="font-semibold text-slate-100">
              {{ toast.title }}
            </p>
            <p v-if="toast.message" class="mt-0.5 text-slate-400">
              {{ toast.message }}
            </p>
          </div>
          <button
            class="rounded-full p-1 text-slate-500 transition hover:bg-slate-800 hover:text-slate-200"
            @click="dismiss(toast.id)"
          >
            <span class="sr-only">Close</span>
            ×
          </button>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.2s ease, opacity 0.2s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(-10px) scale(0.98);
}
</style>

