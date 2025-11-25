<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '~/stores/auth';
import { useMailStore } from '~/stores/mail';
import { useApi } from '~/composables/useApi';
import { useToasts } from '~/composables/useToasts';
import { uploadToCatbox } from '~/lib/catbox';

const router = useRouter();
const auth = useAuthStore();
const mail = useMailStore();
const api = useApi();
const toasts = useToasts();

onMounted(async () => {
  await mail.bootstrap();
  // Initialize profile form
  const user = auth.user;
  if (user) {
    profileForm.displayName = user.displayName || '';
  }
});

const domainInput = ref("");
const domainLoading = ref(false);
const MAX_AVATAR_SIZE_BYTES = 4 * 1024 * 1024; // 4MB
const avatarUploading = ref(false);
const avatarUploadProgress = ref(0);

const profileForm = reactive({
  displayName: "",
});
const profileUpdating = ref(false);

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
    toasts.push({ title: 'Success', message: 'Domain added', variant: 'success' });
  } catch (e) {
    toasts.push({ title: 'Error', message: 'Failed to add domain', variant: 'error' });
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
    toasts.push({ title: 'Success', message: 'Email identity created', variant: 'success' });
  } catch (e) {
    toasts.push({ title: 'Error', message: 'Failed to create email', variant: 'error' });
  } finally {
    emailLoading.value = false;
  }
}

async function handleAvatarUpload(event: Event) {
  const input = event.target as HTMLInputElement;
  if (!input.files || input.files.length === 0) return;

  const file = input.files[0];
  if (!file) return;

  if (file.size > MAX_AVATAR_SIZE_BYTES) {
    toasts.push({ title: 'Error', message: 'File size must be under 4MB', variant: 'error' });
    return;
  }

  avatarUploading.value = true;
  avatarUploadProgress.value = 0;

  try {
    const uploadResult = await uploadToCatbox(file, (percent) => {
      avatarUploadProgress.value = percent;
    });

    // Update User Profile
    if (auth.user?.id) {
      await api(`/api/users/${auth.user.id}`, {
        method: 'PATCH',
        body: { avatar_url: uploadResult.url },
      });
      
      // Update local state
      auth.user.avatarUrl = uploadResult.url;
      toasts.push({ title: 'Success', message: 'Avatar updated', variant: 'success' });
    }
  } catch (error: any) {
    toasts.push({ title: 'Error', message: 'Upload failed', variant: 'error' });
  } finally {
    avatarUploading.value = false;
    avatarUploadProgress.value = 0;
    if (input) {
      input.value = '';
    }
  }
}

async function updateProfile() {
  if (!auth.user?.id) return;
  
  profileUpdating.value = true;
  try {
    await api(`/api/users/${auth.user.id}`, {
      method: 'PATCH',
      body: { 
        display_name: profileForm.displayName 
      },
    });
    
    // Update local state
    auth.user.displayName = profileForm.displayName;
    toasts.push({ title: 'Success', message: 'Profile updated', variant: 'success' });
  } catch (e) {
    toasts.push({ title: 'Error', message: 'Failed to update profile', variant: 'error' });
  } finally {
    profileUpdating.value = false;
  }
}

async function handleLogout() {
  await auth.logout();
  await router.push("/login");
}
</script>

<template>
  <div class="flex h-full w-full flex-col overflow-y-auto bg-slate-950/60">
    <main class="flex-1 p-4 md:p-8">
      <div class="mb-6">
        <div>
          <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Control center</p>
          <h1 class="text-3xl font-semibold">Settings</h1>
          <p class="text-sm text-slate-400">Manage your profile and account settings.</p>
        </div>
      </div>

      <div class="grid gap-6 lg:grid-cols-2">
        <!-- Profile Section -->
        <section class="glass-panel rounded-3xl p-6 lg:col-span-2">
          <div class="flex items-center justify-between mb-6">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Profile</p>
              <h2 class="text-xl font-semibold">Your Identity</h2>
            </div>
          </div>

          <div class="flex flex-col md:flex-row gap-8">
            <!-- Avatar -->
            <div class="flex flex-col items-center gap-4">
              <div class="relative group w-32 h-32">
                <div class="w-full h-full rounded-full overflow-hidden border-2 border-slate-700 bg-slate-900">
                  <img
                    :src="auth.user?.avatarUrl || 'https://via.placeholder.com/150'"
                    alt="Avatar"
                    class="w-full h-full object-cover"
                  />
                </div>
                <label class="absolute inset-0 flex items-center justify-center bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer rounded-full">
                  <span class="text-xs text-white font-medium">Change</span>
                  <input type="file" class="hidden" accept="image/*" @change="handleAvatarUpload" :disabled="avatarUploading" />
                </label>
                <div v-if="avatarUploading" class="absolute inset-0 flex flex-col items-center justify-center bg-black/70 rounded-full gap-2 text-white text-xs">
                  <svg class="animate-spin h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>{{ avatarUploadProgress }}%</span>
                </div>
              </div>
              <p class="text-xs text-slate-500">Max 4MB</p>
            </div>
            
            <!-- Details Form -->
            <div class="flex-1 space-y-4 max-w-2xl">
              <div>
                <label class="text-xs text-slate-500">Full Name</label>
                <input
                  v-model="profileForm.displayName"
                  type="text"
                  placeholder="Your Name"
                  class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/40 px-3 py-2 text-sm focus:border-brand-400 focus:outline-none text-white"
                />
              </div>
              
              <div>
                <label class="text-xs text-slate-500">Email</label>
                <input
                  :value="auth.user?.email"
                  type="text"
                  disabled
                  class="mt-1 w-full rounded-2xl border border-slate-800 bg-slate-950/20 px-3 py-2 text-sm text-slate-400 cursor-not-allowed"
                />
              </div>

              <div>
                <label class="text-xs text-slate-500">Role</label>
                <div class="mt-1">
                  <span class="inline-flex items-center rounded-full bg-slate-800 px-2.5 py-0.5 text-xs font-medium text-slate-300 uppercase tracking-wide">
                    {{ auth.user?.role }}
                  </span>
                </div>
              </div>

              <div class="pt-2">
                <button
                  @click="updateProfile"
                  :disabled="profileUpdating"
                  class="rounded-2xl bg-brand-600 px-6 py-2 text-sm font-semibold text-white shadow-lg shadow-brand-500/20 hover:bg-brand-500 disabled:opacity-50 transition-colors"
                >
                  {{ profileUpdating ? "Saving..." : "Save Changes" }}
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Admin Only Sections -->
        <template v-if="auth.isAdmin">
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
        </template>

        <!-- Emails Section (Visible to all) -->
        <section class="glass-panel rounded-3xl p-6">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-slate-500">Emails</p>
              <h2 class="text-xl font-semibold">{{ auth.isAdmin ? 'Create inbox identities' : 'Your Inboxes' }}</h2>
            </div>
            <span class="rounded-full bg-slate-800/70 px-3 py-1 text-xs text-slate-300">{{ mail.emails.length }} addresses</span>
          </div>

          <form v-if="auth.isAdmin" class="mt-4 space-y-4" @submit.prevent="handleEmailCreate">
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
            <p v-if="!mail.emails.length" class="text-slate-500">No email identities yet. {{ auth.isAdmin ? 'Create a domain first.' : 'Ask an admin to assign one.' }}</p>
          </div>
        </section>
      </div>
    </main>
  </div>
</template>

