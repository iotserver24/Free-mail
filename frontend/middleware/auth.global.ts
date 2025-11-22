import { useAuthStore } from "~/stores/auth";

const PUBLIC_ROUTES = ["/login", "/"];

export default defineNuxtRouteMiddleware(async (to) => {
  const auth = useAuthStore();
  if (!auth.initialized) {
    await auth.hydrate();
  }

  const isPublic = PUBLIC_ROUTES.includes(to.path);

  if (!auth.isAuthenticated && !isPublic) {
    return navigateTo("/login");
  }

  // Only redirect to inbox if on login page and already authenticated
  if (auth.isAuthenticated && to.path === "/login") {
    const mail = useMailStore();
    // If we have an active inbox, go there, otherwise go to the landing page or a default
    if (mail.activeInboxId) {
      return navigateTo(`/inbox/${mail.activeInboxId}`);
    }
    return navigateTo("/");
  }
});

