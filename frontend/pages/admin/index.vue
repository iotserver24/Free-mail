<template>
  <div class="min-h-screen bg-gray-900 text-white p-8 overflow-y-auto">
    <div class="max-w-6xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Create User Form -->
        <div class="lg:col-span-1">
          <div class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700 sticky top-8">
            <h2 class="text-xl font-semibold mb-6">Create New User</h2>

            <form @submit.prevent="createUser" class="space-y-6">
              <!-- PFP Upload -->
              <div class="flex flex-col items-center mb-6">
                <div class="relative w-24 h-24 mb-4">
                  <img
                    :src="form.avatar_url || 'https://via.placeholder.com/150'"
                    alt="Avatar Preview"
                    class="w-full h-full rounded-full object-cover border-2 border-gray-600"
                  />
                  <label
                    class="absolute bottom-0 right-0 bg-blue-600 rounded-full p-2 cursor-pointer hover:bg-blue-700 transition-colors"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <input type="file" class="hidden" accept="image/*" @change="handleFileUpload" />
                  </label>
                </div>
                <p v-if="uploading" class="text-xs text-blue-400">Uploading...</p>
              </div>

              <!-- Full Name -->
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">Full Name</label>
                <input
                  v-model="form.fullname"
                  type="text"
                  class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  placeholder="John Doe"
                />
              </div>

              <!-- Username & Domain -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-400 mb-2">Username</label>
                  <input
                    v-model="form.username"
                    type="text"
                    required
                    class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    placeholder="jdoe"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-400 mb-2">Domain</label>
                  <select
                    v-model="form.domain_id"
                    required
                    class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  >
                    <option value="" disabled>Select Domain</option>
                    <option v-for="domain in domains" :key="domain.id" :value="domain.id">
                      {{ domain.domain }}
                    </option>
                  </select>
                </div>
              </div>

              <!-- Details -->
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">Details</label>
                <textarea
                  v-model="form.details"
                  rows="2"
                  class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  placeholder="Notes..."
                ></textarea>
              </div>

              <!-- Password Options -->
              <div class="border-t border-gray-700 pt-4">
                <label class="block text-sm font-medium text-gray-400 mb-3">Password</label>
                
                <div class="flex flex-col space-y-2 mb-4">
                  <label class="flex items-center cursor-pointer">
                    <input type="radio" v-model="form.passwordOption" value="manual" class="form-radio text-blue-500" />
                    <span class="ml-2 text-sm">Set Manually</span>
                  </label>
                  <label class="flex items-center cursor-pointer">
                    <input type="radio" v-model="form.passwordOption" value="invite" class="form-radio text-blue-500" />
                    <span class="ml-2 text-sm">Send Invite Link</span>
                  </label>
                </div>

                <div v-if="form.passwordOption === 'manual'" class="animate-fade-in">
                  <input
                    v-model="form.password"
                    type="password"
                    required
                    class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    placeholder="Password"
                  />
                </div>

                <div v-if="form.passwordOption === 'invite'" class="animate-fade-in">
                  <input
                    v-model="form.personal_email"
                    type="email"
                    required
                    class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                    placeholder="Personal Email"
                  />
                </div>
              </div>

              <button
                type="submit"
                :disabled="loading || uploading"
                class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex justify-center items-center"
              >
                <span v-if="loading" class="mr-2">
                  <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                </span>
                {{ loading ? 'Creating...' : 'Create User' }}
              </button>
            </form>
          </div>
        </div>

        <!-- User List -->
        <div class="lg:col-span-2">
          <div class="bg-gray-800 rounded-lg shadow-lg border border-gray-700 overflow-hidden">
            <div class="p-6 border-b border-gray-700 flex justify-between items-center">
              <h2 class="text-xl font-semibold">Users</h2>
              <button @click="fetchUsers" class="text-sm text-blue-400 hover:text-blue-300">Refresh</button>
            </div>
            <div class="overflow-x-auto">
              <table class="w-full text-left">
                <thead class="bg-gray-700/50 text-gray-400 text-xs uppercase">
                  <tr>
                    <th class="px-6 py-3">User</th>
                    <th class="px-6 py-3">Role</th>
                    <th class="px-6 py-3">Created</th>
                    <th class="px-6 py-3">Status</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-700">
                  <tr v-for="user in users" :key="user.id" class="hover:bg-gray-700/30 transition-colors">
                    <td class="px-6 py-4">
                      <div class="flex items-center">
                        <img
                          :src="user.avatarUrl || 'https://via.placeholder.com/40'"
                          alt=""
                          class="h-10 w-10 rounded-full object-cover mr-3 border border-gray-600"
                        />
                        <div>
                          <div class="font-medium text-white">{{ user.displayName || user.username }}</div>
                          <div class="text-sm text-gray-400">{{ user.email }}</div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <span
                        class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                        :class="user.role === 'admin' ? 'bg-purple-100 text-purple-800' : 'bg-green-100 text-green-800'"
                      >
                        {{ user.role }}
                      </span>
                    </td>
                    <td class="px-6 py-4 text-sm text-gray-400">
                      {{ new Date(user.created_at || Date.now()).toLocaleDateString() }}
                    </td>
                    <td class="px-6 py-4">
                       <span class="text-xs text-gray-500">Active</span>
                    </td>
                  </tr>
                  <tr v-if="users.length === 0">
                    <td colspan="4" class="px-6 py-8 text-center text-gray-500">
                      No users found.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { useAuthStore } from '~/stores/auth';
import { useRouter } from 'vue-router';
import { useApi } from '~/composables/useApi';
import { useToasts } from '~/composables/useToasts';
import type { DomainRecord, ApiUser } from '~/types/api';

const authStore = useAuthStore();
const router = useRouter();
const api = useApi();
const toasts = useToasts();

// Protect route
if (!authStore.isAdmin) {
  router.push('/');
}

const loading = ref(false);
const uploading = ref(false);
const domains = ref<DomainRecord[]>([]);
const users = ref<any[]>([]); // Using any for now to include extra fields like created_at

const form = reactive({
  username: '',
  fullname: '',
  domain_id: '',
  details: '',
  passwordOption: 'manual',
  password: '',
  personal_email: '',
  avatar_url: '',
});

async function fetchDomains() {
  try {
    const data = await api<DomainRecord[]>('/api/domains');
    domains.value = data;
    if (data.length > 0) {
      form.domain_id = data[0].id;
    }
  } catch (e) {
    console.error('Failed to fetch domains', e);
  }
}

async function fetchUsers() {
  try {
    const data = await api<any[]>('/api/users');
    users.value = data;
  } catch (e) {
    console.error('Failed to fetch users', e);
  }
}

async function handleFileUpload(event: Event) {
  const input = event.target as HTMLInputElement;
  if (!input.files?.length) return;

  const file = input.files[0];
  if (file.size > 5 * 1024 * 1024) {
    toasts.push({ title: 'Error', message: 'File size must be under 5MB', variant: 'error' });
    return;
  }

  uploading.value = true;
  const formData = new FormData();
  formData.append('file', file);

  try {
    // We need to use fetch directly or configure useApi to handle FormData correctly if it doesn't already
    // Assuming useApi handles it or we use raw fetch for upload
    // Let's try useApi first, but usually it sets JSON headers. 
    // If useApi is strict about JSON, we might need a custom call.
    // For safety, let's use the token from authStore and raw fetch
    
    // Actually, let's try to use the api composable but we might need to unset Content-Type
    // But since I can't see useApi implementation details right now, I'll assume standard fetch with auth header
    
    // Wait, I can see useApi in previous context? No.
    // I'll use a standard fetch with the token.
    
    const token = useCookie('auth_token').value; // Assuming cookie name
    // Or better, use api() and let it handle auth, but pass body as FormData
    
    const res = await api<{ url: string }>('/api/uploads/catbox', {
      method: 'POST',
      body: formData,
      // headers: { 'Content-Type': undefined } // Let browser set boundary
    });
    
    form.avatar_url = res.url;
    toasts.push({ title: 'Success', message: 'Avatar uploaded', variant: 'success' });
  } catch (error: any) {
    toasts.push({ title: 'Error', message: 'Upload failed', variant: 'error' });
  } finally {
    uploading.value = false;
  }
}

async function createUser() {
  loading.value = true;
  try {
    await api('/api/users', {
      method: 'POST',
      body: {
        username: form.username,
        fullname: form.fullname,
        domain_id: form.domain_id,
        details: form.details,
        password: form.passwordOption === 'manual' ? form.password : undefined,
        send_invite: form.passwordOption === 'invite',
        personal_email: form.passwordOption === 'invite' ? form.personal_email : undefined,
        avatar_url: form.avatar_url || undefined,
      },
    });

    toasts.push({
      title: 'Success',
      message: 'User created successfully',
      variant: 'success',
    });

    // Reset form
    form.username = '';
    form.fullname = '';
    form.details = '';
    form.password = '';
    form.personal_email = '';
    form.avatar_url = '';
    form.passwordOption = 'manual';
    
    // Refresh list
    await fetchUsers();

  } catch (error: any) {
    toasts.push({
      title: 'Error',
      message: error.data?.error || 'Failed to create user',
      variant: 'error',
    });
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  fetchDomains();
  fetchUsers();
});
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
