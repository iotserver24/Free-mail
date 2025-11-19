import type { FormEvent } from "react";
import { useState } from "react";
import { register } from "../lib/auth";

interface RegisterProps {
  onSuccess: () => void;
  onSwitchToLogin: () => void;
}

export function Register({ onSuccess, onSwitchToLogin }: RegisterProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await register(email, password, displayName || undefined);
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-card">
      <h2>Create Account</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="register-email">Email</label>
          <input
            id="register-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
            placeholder="you@example.com"
          />
        </div>
        <div className="form-group">
          <label htmlFor="register-password">Password</label>
          <input
            id="register-password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="new-password"
            placeholder="At least 6 characters"
            minLength={6}
          />
        </div>
        <div className="form-group">
          <label htmlFor="register-name">Display Name (optional)</label>
          <input
            id="register-name"
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            autoComplete="name"
            placeholder="Your name"
          />
        </div>
        {error && <div className="error-message">{error}</div>}
        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? "Creating account..." : "Sign Up"}
        </button>
      </form>
      <p className="auth-switch">
        Already have an account?{" "}
        <button type="button" className="link-btn" onClick={onSwitchToLogin}>
          Sign in
        </button>
      </p>
    </div>
  );
}

