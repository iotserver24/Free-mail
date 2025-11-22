<script setup lang="ts">
definePageMeta({
  layout: "landing",
});

const auth = useAuthStore();
const mail = useMailStore();
const router = useRouter();

async function handleGetStarted() {
  if (auth.isAuthenticated) {
    if (!mail.bootstrapped) {
      await mail.bootstrap();
    }
    
    if (mail.activeInboxId) {
      router.push(`/inbox/${mail.activeInboxId}`);
    } else {
      // Fallback if no inbox active yet, try to force login/setup
      router.push("/login");
    }
  } else {
    router.push("/login");
  }
}
</script>

<template>
  <div class="relative flex min-h-screen w-full flex-col items-center justify-center overflow-hidden bg-slate-950 text-slate-100">
    <!-- Background Gradients -->
    <div class="absolute -left-20 -top-20 h-96 w-96 rounded-full bg-brand-500/20 blur-[100px]"></div>
    <div class="absolute -bottom-20 -right-20 h-96 w-96 rounded-full bg-purple-500/20 blur-[100px]"></div>

    <div class="relative z-10 max-w-4xl px-6 text-center">
      <!-- Animated Badge -->
      <div class="animate-fade-in-up mx-auto mb-6 w-fit rounded-full border border-slate-800 bg-slate-900/50 px-4 py-1.5 backdrop-blur-md">
        <span class="bg-gradient-to-r from-brand-300 to-purple-300 bg-clip-text text-xs font-semibold uppercase tracking-widest text-transparent">
          Open Source • Self Hosted • Free
        </span>
      </div>

      <!-- Main Title -->
      <h1 class="animate-fade-in-up delay-100 text-5xl font-bold tracking-tight sm:text-7xl">
        <span class="block text-white">Reclaim your</span>
        <span class="bg-gradient-to-r from-brand-400 to-purple-400 bg-clip-text text-transparent">
          digital privacy.
        </span>
      </h1>

      <!-- Subtitle -->
      <p class="animate-fade-in-up mx-auto mt-6 max-w-2xl text-lg text-slate-400 delay-200">
        Free Mail is the modern, open-source solution for managing your emails. 
        Host it yourself, connect your domains, and enjoy a premium, ad-free experience.
      </p>

      <!-- CTA Buttons -->
      <div class="animate-fade-in-up mt-10 flex flex-col items-center justify-center gap-4 delay-300 sm:flex-row">
        <button
          @click="handleGetStarted"
          class="group relative rounded-2xl bg-brand-500 px-8 py-4 text-lg font-semibold text-white shadow-lg shadow-brand-500/25 transition-all hover:scale-105 hover:bg-brand-400 hover:shadow-brand-500/40"
        >
          <span class="relative z-10 flex items-center gap-2">
            {{ auth.isAuthenticated ? 'Go to Inbox' : 'Get Started' }}
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="h-5 w-5 transition-transform group-hover:translate-x-1">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
            </svg>
          </span>
        </button>
        
        <a
          href="https://github.com/iotserver24/free-mail.git"
          target="_blank"
          class="rounded-2xl border border-slate-800 bg-slate-900/50 px-8 py-4 text-lg font-semibold text-slate-300 backdrop-blur-sm transition-all hover:bg-slate-800 hover:text-white"
        >
          View on GitHub
        </a>
      </div>

      <!-- Feature Grid -->
      <div class="animate-fade-in-up mt-20 grid grid-cols-1 gap-8 delay-500 sm:grid-cols-3 text-left">
        <div class="rounded-3xl border border-slate-800 bg-slate-900/30 p-6 backdrop-blur-sm transition hover:border-slate-700">
          <div class="mb-4 inline-block rounded-xl bg-brand-500/10 p-3 text-brand-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-6 w-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12c0 5.523-4.477 10-10 10S1 17.523 1 12 5.477 2 11 2s10 4.477 10 10z" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-slate-100">Self Hosted</h3>
          <p class="mt-2 text-sm text-slate-400">You own your data. Deploy on your own server and never worry about privacy again.</p>
        </div>
        <div class="rounded-3xl border border-slate-800 bg-slate-900/30 p-6 backdrop-blur-sm transition hover:border-slate-700">
          <div class="mb-4 inline-block rounded-xl bg-purple-500/10 p-3 text-purple-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-6 w-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-slate-100">Unlimited Domains</h3>
          <p class="mt-2 text-sm text-slate-400">Connect as many domains as you want. Create unlimited inboxes for all your projects.</p>
        </div>
        <div class="rounded-3xl border border-slate-800 bg-slate-900/30 p-6 backdrop-blur-sm transition hover:border-slate-700">
          <div class="mb-4 inline-block rounded-xl bg-blue-500/10 p-3 text-blue-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-6 w-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-slate-100">Blazing Fast</h3>
          <p class="mt-2 text-sm text-slate-400">Built with modern tech for instant loading and a smooth, premium experience.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in-up {
  animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  opacity: 0;
  transform: translateY(20px);
}

.delay-100 { animation-delay: 0.1s; }
.delay-200 { animation-delay: 0.2s; }
.delay-300 { animation-delay: 0.3s; }
.delay-500 { animation-delay: 0.5s; }

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
