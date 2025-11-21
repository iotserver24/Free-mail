<template>
  <div class="min-h-screen flex flex-col items-center justify-center bg-slate-950 px-4 py-10 text-slate-100">
    <div class="w-full max-w-md glass-panel rounded-2xl p-8 shadow-2xl shadow-black/50">
      <slot />
    </div>
    <UiToastStack />
  </div>
</template>

