import { defineStore } from "pinia";
import type { ApiUser, ApiError } from "~/types/api";

interface Credentials {
  email: string;
  password: string;
}

interface AuthState {
  user: ApiUser | null;
  loading: boolean;
  initialized: boolean;
}

export const useAuthStore = defineStore("auth", {
  state: (): AuthState => ({
    user: null,
    loading: false,
    initialized: false,
  }),
  getters: {
    isAuthenticated: (state) => Boolean(state.user),
    currentEmail: (state) => state.user?.email ?? "",
    isAdmin: (state) => state.user?.role === "admin",
  },
  actions: {
    async hydrate() {
      if (this.initialized) {
        return;
      }
      this.loading = true;
      const api = useApi();
      try {
        const { user } = await api<{ user: ApiUser }>("/api/auth/me");
        this.user = user;
      } catch (error) {
        // Ignore 401s
        const err = error as { data?: ApiError; status?: number };
        if (err.status && err.status >= 500) {
          console.error("Failed to hydrate auth", err);
        }
        this.user = null;
      } finally {
        this.loading = false;
        this.initialized = true;
      }
    },
    async login(credentials: Credentials) {
      this.loading = true;
      const api = useApi();
      try {
        const { user } = await api<{ user: ApiUser }>("/api/auth/login", {
          method: "POST",
          body: credentials,
        });
        this.user = user;
        useToasts().push({
          title: "Welcome back",
          message: "Session restored successfully.",
          variant: "success",
        });
      } catch (error) {
        const message =
          (error as { data?: ApiError }).data?.error ?? "Invalid credentials";
        useToasts().push({
          title: "Login failed",
          message,
          variant: "error",
        });
        throw error;
      } finally {
        this.loading = false;
        this.initialized = true;
      }
    },
    async logout() {
      const api = useApi();
      await api("/api/auth/logout", { method: "POST" });
      this.user = null;
      this.initialized = false;
      useToasts().push({
        title: "Signed out",
        message: "Your session has ended.",
        variant: "info",
      });
    },
  },
});

