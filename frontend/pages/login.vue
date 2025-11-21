<script setup lang="ts">
definePageMeta({
  layout: "auth",
});

const router = useRouter();
const auth = useAuthStore();
const mail = useMailStore();

const form = reactive({
  email: "",
  password: "",
});

const submitting = ref(false);
const errorMessage = ref("");

async function handleSubmit() {
  submitting.value = true;
  errorMessage.value = "";
  try {
    await auth.login({ ...form });
    await mail.bootstrap();
    await router.push("/");
  } catch (error) {
    errorMessage.value =
      (error as { data?: { error?: string }; message?: string }).data?.error ??
      (error as Error).message ??
      "Unable to login";
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <form class="space-y-6" @submit.prevent="handleSubmit">
    <div class="space-y-2 text-center">
      <p class="text-sm font-medium uppercase tracking-[0.3em] text-brand-400">Free Mail</p>
      <h1 class="text-2xl font-semibold">Welcome back</h1>
      <p class="text-sm text-slate-400">Sign in to manage your inboxes and domains.</p>
    </div>

    <div class="space-y-4">
      <div>
        <label for="email" class="text-sm font-medium text-slate-300">Email</label>
        <input
          id="email"
          v-model="form.email"
          type="email"
          required
          placeholder="admin@yourdomain.com"
          class="mt-2 w-full rounded-xl border border-slate-700 bg-slate-900/50 px-4 py-3 text-slate-100 placeholder-slate-500 focus:border-brand-400 focus:outline-none focus:ring-2 focus:ring-brand-400/40"
        />
      </div>

      <div>
        <label for="password" class="text-sm font-medium text-slate-300">Password</label>
        <input
          id="password"
          v-model="form.password"
          type="password"
          required
          placeholder="••••••••"
          class="mt-2 w-full rounded-xl border border-slate-700 bg-slate-900/50 px-4 py-3 text-slate-100 placeholder-slate-500 focus:border-brand-400 focus:outline-none focus:ring-2 focus:ring-brand-400/40"
        />
      </div>
    </div>

    <p v-if="errorMessage" class="text-sm text-rose-400">
      {{ errorMessage }}
    </p>

    <button
      type="submit"
      :disabled="submitting"
      class="w-full rounded-xl bg-brand-500 px-4 py-3 text-sm font-semibold text-white shadow-lg shadow-brand-500/30 transition hover:bg-brand-400 disabled:cursor-not-allowed disabled:opacity-60"
    >
      <span v-if="!submitting">Sign in</span>
      <span v-else>Signing you in…</span>
    </button>
  </form>
</template>

