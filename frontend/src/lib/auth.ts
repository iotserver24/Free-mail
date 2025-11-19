const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:4000";

export interface User {
  id: string;
  email: string;
  displayName: string | null;
}

export interface AuthResponse {
  user: User;
}

export async function register(email: string, password: string, displayName?: string): Promise<AuthResponse> {
  const res = await fetch(`${API_BASE}/api/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify({ email, password, displayName }),
  });
  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.error || "Registration failed");
  }
  return res.json();
}

export async function login(email: string, password: string): Promise<AuthResponse> {
  const res = await fetch(`${API_BASE}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.error || "Login failed");
  }
  return res.json();
}

export async function logout(): Promise<void> {
  await fetch(`${API_BASE}/api/auth/logout`, {
    method: "POST",
    credentials: "include",
  });
}

export async function getCurrentUser(): Promise<User | null> {
  const res = await fetch(`${API_BASE}/api/auth/me`, {
    credentials: "include",
  });
  if (!res.ok) {
    return null;
  }
  const data = await res.json();
  return data.user;
}

