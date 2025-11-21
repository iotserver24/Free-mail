import { useAuthStore } from "~/stores/auth";

const PUBLIC_ROUTES = ["/login"];

export default defineNuxtRouteMiddleware(async (to) => {
  const auth = useAuthStore();
  if (!auth.initialized) {
    await auth.hydrate();
  }

  const isPublic = PUBLIC_ROUTES.includes(to.path);

  if (!auth.isAuthenticated && !isPublic) {
    return navigateTo("/login");
  }

  if (auth.isAuthenticated && isPublic) {
    return navigateTo("/");
  }
});

