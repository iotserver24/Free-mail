<script setup lang="ts">
const router = useRouter();
const auth = useAuthStore();
const mail = useMailStore();

onMounted(async () => {
  await mail.bootstrap();
});

const domainInput = ref("");
const domainLoading = ref(false);

const emailForm = reactive({
  localPart: "",
  domain: "",
  inboxName: "",
});
const emailLoading = ref(false);

const emailPreview = computed(() => {
  if (!emailForm.localPart || !emailForm.domain) return "";
  return `${emailForm.localPart}@${emailForm.domain}`;
});

watch(
  () => mail.domains,
  (domains) => {
    if (!emailForm.domain && domains.length) {
      emailForm.domain = domains[0].domain;
    }
  },
  { immediate: true }
);

async function handleDomainCreate() {
  if (!domainInput.value) return;
  domainLoading.value = true;
  try {
    await mail.createDomain(domainInput.value);
    domainInput.value = "";
  } finally {
    domainLoading.value = false;
  }
}

async function handleEmailCreate() {
  if (!emailPreview.value) return;
  emailLoading.value = true;
  try {
    await mail.createEmail({
      email: emailPreview.value,
      domain: emailForm.domain,
      inboxName: emailForm.inboxName || emailPreview.value,
    });
    emailForm.localPart = "";
    emailForm.inboxName = "";
  } finally {
    emailLoading.value = false;
  }
}

function goHome() {
  router.push("/");
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
      @settings="() => {}"
      @logout="handleLogout"
    />

    <main class="flex-1 bg-slate-950/60 p-8">
      <div class="mb-6 flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Control center</p>
          <h1 class="text-3xl font-semibold">Settings</h1>
          <p class="text-sm text-slate-400">Connect domains, mint inboxes, and manage delivery.</p>
        </div>
        <button class="rounded-2xl border border-slate-700 px-4 py-2 text-sm text-slate-200" @click="goHome">
          Back to inbox
        </button>
      </div>

      <div class="grid gap-6 lg:grid-cols-2">
        <section class="glass-panel rounded-3xl p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Domains</p>
              <h2 class="text-xl font-semibold">Bring your own domain</h2>
            </div>
            <span class="rounded-full bg-slate-800/70 px-3 py-1 text-xs text-slate-300">{{ mail.domains.length }} linked</span>
          </div>

          <form class="mt-4 space-y-4" @submit.prevent="handleDomainCreate">
            <div>
              <label class="text-xs text-slate-500">Domain</label>
              <input
                v-model="domainInput"
                type="text"
                placeholder="mail.yourcompany.com"
                class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              />
            </div>
            <button
              type="submit"
              :disabled="domainLoading"
              class="w-full rounded-2xl bg-brand-500 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-brand-500/30 hover:bg-brand-400 disabled:opacity-50"
            >
              {{ domainLoading ? "Adding…" : "Add domain" }}
            </button>
          </form>

          <ul class="mt-6 space-y-3 text-sm">
            <li v-for="domain in mail.domains" :key="domain.id" class="flex items-center justify-between rounded-2xl border border-slate-800/80 px-3 py-2">
              <div>
                <p class="font-semibold text-slate-100">{{ domain.domain }}</p>
                <p class="text-xs text-slate-500">Created {{ new Date(domain.created_at).toLocaleDateString() }}</p>
              </div>
              <span class="text-xs text-emerald-400">Active</span>
            </li>
            <li v-if="!mail.domains.length" class="text-slate-500">No domains yet.</li>
          </ul>
        </section>

        <section class="glass-panel rounded-3xl p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Emails</p>
              <h2 class="text-xl font-semibold">Create inbox identities</h2>
            </div>
            <span class="rounded-full bg-slate-800/70 px-3 py-1 text-xs text-slate-300">{{ mail.emails.length }} addresses</span>
          </div>

          <form class="mt-4 space-y-4" @submit.prevent="handleEmailCreate">
            <div class="grid gap-4 md:grid-cols-2">
              <div>
                <label class="text-xs text-slate-500">Local part</label>
                <input
                  v-model="emailForm.localPart"
                  type="text"
                  placeholder="support"
                  class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
                />
              </div>
              <div>
                <label class="text-xs text-slate-500">Domain</label>
                <select
                  v-model="emailForm.domain"
                  class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
                >
                  <option v-for="domain in mail.domains" :key="domain.id" :value="domain.domain">
                    {{ domain.domain }}
                  </option>
                </select>
              </div>
            </div>

            <div>
              <label class="text-xs text-slate-500">Inbox label</label>
              <input
                v-model="emailForm.inboxName"
                type="text"
                placeholder="Customer Support"
                class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none"
              />
            </div>

            <p class="text-sm text-slate-400">Preview: <span class="font-semibold text-white">{{ emailPreview || "—" }}</span></p>

            <button
              type="submit"
              :disabled="emailLoading || !emailPreview"
              class="w-full rounded-2xl bg-brand-500 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-brand-500/30 hover:bg-brand-400 disabled:opacity-50"
            >
              {{ emailLoading ? "Creating…" : "Create email & inbox" }}
            </button>
          </form>

          <div class="mt-6 space-y-3 text-sm">
            <div
              v-for="email in mail.emails"
              :key="email.id"
              class="rounded-2xl border border-slate-800/70 px-4 py-3 text-slate-200"
            >
              <p class="font-semibold">{{ email.email }}</p>
              <p class="text-xs text-slate-500">Inbox: {{ email.inbox_id }}</p>
            </div>
            <p v-if="!mail.emails.length" class="text-slate-500">No email identities yet.</p>
          </div>
        </section>
      </div>
    </main>

    <MailComposerDrawer
      :open="mail.composerOpen"
      :emails="mail.emails"
      :active-inbox-id="mail.activeInboxId"
      :submit="mail.sendMessage"
      @close="mail.toggleComposer(false)"
    />
  </div>
</template>

