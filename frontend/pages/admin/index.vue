<template>
  <div class="min-h-screen bg-gray-900 text-white p-8">
    <div class="max-w-4xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <div class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700">
        <h2 class="text-xl font-semibold mb-6">Create New User</h2>

        <form @submit.prevent="createUser" class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Username -->
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

            <!-- Email -->
            <div>
              <label class="block text-sm font-medium text-gray-400 mb-2">Email Address</label>
              <input
                v-model="form.email"
                type="email"
                required
                class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                placeholder="jdoe@example.com"
              />
            </div>

            <!-- Permanent Domain -->
            <div>
              <label class="block text-sm font-medium text-gray-400 mb-2">Permanent Domain</label>
              <input
                v-model="form.permanent_domain"
                type="text"
                required
                class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                placeholder="example.com"
              />
            </div>

            <!-- Details -->
            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-400 mb-2">User Details</label>
              <textarea
                v-model="form.details"
                rows="3"
                class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                placeholder="Additional notes about this user..."
              ></textarea>
            </div>
          </div>

          <!-- Password Options -->
          <div class="border-t border-gray-700 pt-6">
            <label class="block text-sm font-medium text-gray-400 mb-4">Password Configuration</label>
            
            <div class="flex items-center space-x-6 mb-6">
              <label class="flex items-center cursor-pointer">
                <input
                  type="radio"
                  v-model="form.passwordOption"
                  value="manual"
                  class="form-radio text-blue-500 h-4 w-4 bg-gray-700 border-gray-600 focus:ring-blue-500 focus:ring-offset-gray-800"
                />
                <span class="ml-2">Set Password Manually</span>
              </label>
              
              <label class="flex items-center cursor-pointer">
                <input
                  type="radio"
                  v-model="form.passwordOption"
                  value="invite"
                  class="form-radio text-blue-500 h-4 w-4 bg-gray-700 border-gray-600 focus:ring-blue-500 focus:ring-offset-gray-800"
                />
                <span class="ml-2">Send Invite Link</span>
              </label>
            </div>

            <!-- Manual Password Input -->
            <div v-if="form.passwordOption === 'manual'" class="animate-fade-in">
              <label class="block text-sm font-medium text-gray-400 mb-2">Password</label>
              <input
                v-model="form.password"
                type="password"
                required
                class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                placeholder="••••••••"
              />
            </div>

            <!-- Invite Email Input -->
            <div v-if="form.passwordOption === 'invite'" class="animate-fade-in">
              <label class="block text-sm font-medium text-gray-400 mb-2">Personal Email (for invite)</label>
              <input
                v-model="form.personal_email"
                type="email"
                required
                class="w-full bg-gray-700 border border-gray-600 rounded-md px-4 py-2 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                placeholder="personal@gmail.com"
              />
              <p class="text-xs text-gray-500 mt-1">An invite link will be sent to this address.</p>
            </div>
          </div>

          <div class="flex justify-end pt-4">
            <button
              type="submit"
              :disabled="loading"
              class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
            >
              <span v-if="loading" class="mr-2">
                <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </span>
              {{ loading ? 'Creating...' : 'Create User' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { useAuthStore } from '~/stores/auth';
import { useRouter } from 'vue-router';
import { useApi } from '~/composables/useApi';
import { useToasts } from '~/composables/useToasts';

const authStore = useAuthStore();
const router = useRouter();
const api = useApi();
const toasts = useToasts();

// Protect route
if (!authStore.isAdmin) {
  router.push('/');
}

const loading = ref(false);

const form = reactive({
  username: '',
  email: '',
  permanent_domain: '',
  details: '',
  passwordOption: 'manual',
  password: '',
  personal_email: '',
});

async function createUser() {
  loading.value = true;
  try {
    await api('/api/users', {
      method: 'POST',
      body: {
        username: form.username,
        email: form.email,
        permanent_domain: form.permanent_domain,
        details: form.details,
        password: form.passwordOption === 'manual' ? form.password : undefined,
        send_invite: form.passwordOption === 'invite',
        personal_email: form.passwordOption === 'invite' ? form.personal_email : undefined,
      },
    });

    toasts.push({
      title: 'Success',
      message: 'User created successfully',
      variant: 'success',
    });

    // Reset form
    form.username = '';
    form.email = '';
    form.permanent_domain = '';
    form.details = '';
    form.password = '';
    form.personal_email = '';
    form.passwordOption = 'manual';

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
