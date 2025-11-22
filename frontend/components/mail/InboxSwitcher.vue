<script setup lang="ts">
import { Listbox, ListboxButton, ListboxOptions, ListboxOption } from "@headlessui/vue";
import { ChevronUpDownIcon, CheckIcon } from "@heroicons/vue/20/solid";
import type { EmailRecord } from "~/types/api";

const props = defineProps<{
  emails: EmailRecord[];
  activeInboxId: string | null;
}>();

const emit = defineEmits<{
  select: [inboxId: string];
}>();

const selectedEmail = computed(() => 
  props.emails.find((e) => e.inbox_id === props.activeInboxId)
);

function handleSelect(email: EmailRecord) {
  emit("select", email.inbox_id);
}
</script>

<template>
  <div class="w-full min-w-[200px] max-w-xs">
    <Listbox
      :model-value="selectedEmail"
      @update:model-value="handleSelect"
    >
      <div class="relative">
        <ListboxButton
          class="relative w-full cursor-default rounded-xl border border-slate-700 bg-slate-900/80 py-2.5 pl-4 pr-10 text-left text-sm text-slate-200 shadow-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 sm:text-sm"
        >
          <span class="block truncate">
            {{ selectedEmail?.email || "Select an inbox" }}
          </span>
          <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
            <ChevronUpDownIcon class="h-5 w-5 text-slate-400" aria-hidden="true" />
          </span>
        </ListboxButton>

        <transition
          leave-active-class="transition duration-100 ease-in"
          leave-from-class="opacity-100"
          leave-to-class="opacity-0"
        >
          <ListboxOptions
            class="absolute z-50 mt-1 max-h-60 w-full overflow-auto rounded-xl border border-slate-700 bg-slate-900 py-1 text-base shadow-lg ring-1 ring-black/5 focus:outline-none sm:text-sm"
          >
            <ListboxOption
              v-for="email in emails"
              :key="email.id"
              v-slot="{ active, selected }"
              :value="email"
              as="template"
            >
              <li
                :class="[
                  active ? 'bg-brand-500/10 text-brand-100' : 'text-slate-300',
                  'relative cursor-default select-none py-2.5 pl-10 pr-4 transition-colors',
                ]"
              >
                <span
                  :class="[
                    selected ? 'font-medium text-brand-400' : 'font-normal',
                    'block truncate',
                  ]"
                >
                  {{ email.email }}
                </span>
                <span
                  v-if="selected"
                  class="absolute inset-y-0 left-0 flex items-center pl-3 text-brand-400"
                >
                  <CheckIcon class="h-5 w-5" aria-hidden="true" />
                </span>
              </li>
            </ListboxOption>
            <div v-if="emails.length === 0" class="px-4 py-3 text-sm text-slate-500">
              No inboxes available
            </div>
          </ListboxOptions>
        </transition>
      </div>
    </Listbox>
  </div>
</template>
