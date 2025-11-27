// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  srcDir: ".",
  ssr: false,
  devtools: { enabled: true },
  modules: ["@pinia/nuxt", "@nuxtjs/tailwindcss"],
  pages: true,
  css: ["~/assets/css/main.css"],
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE ?? "http://localhost:4000",
      catboxUserHash: process.env.NUXT_PUBLIC_CATBOX_USERHASH ?? "",
    },
  },
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
  app: {
    head: {
      title: "Free Mail",
      meta: [
        {
          name: "description",
          content: "Gmail-like dashboard for managing custom domains and inboxes",
        },
      ],
      link: [{ rel: "icon", type: "image/x-icon", href: "/favicon.ico" }],
    },
  },
  tailwindcss: {
    viewer: false,
  },
});
