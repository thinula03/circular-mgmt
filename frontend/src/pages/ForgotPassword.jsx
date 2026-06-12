import { useState } from "react";
import { Link } from "react-router-dom";
import client from "../api/client";

// FR-04 — request a password reset link.
export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [devLink, setDevLink] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    setMessage("");
    setDevLink("");
    try {
      const { data } = await client.post("/auth/forgot-password", { email });
      setMessage(data.message);
      if (data.dev_reset_url) setDevLink(data.dev_reset_url); // dev convenience
    } catch {
      setMessage("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-brand-700 to-brand-900 p-4">
      <div className="card w-full max-w-md p-8">
        <h1 className="text-lg font-bold text-ink">Reset your password</h1>
        <p className="mt-1 text-sm text-ink-muted">
          Enter your registered email and we'll send a reset link.
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-ink">Email</label>
            <input
              type="email"
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@bank.lk"
              required
            />
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full">
            {loading ? "Sending…" : "Send reset link"}
          </button>
        </form>

        {message && (
          <div className="mt-4 rounded-lg bg-brand-50 px-3 py-2 text-sm text-brand-700">
            {message}
          </div>
        )}
        {devLink && (
          <div className="mt-3 rounded-lg border border-dashed border-ink-line bg-ink-surface px-3 py-2 text-xs">
            <div className="mb-1 font-semibold text-ink-muted">Dev link (no SMTP configured):</div>
            <Link to={devLink.replace(/^https?:\/\/[^/]+/, "")} className="break-all text-brand-600 hover:underline">
              {devLink}
            </Link>
          </div>
        )}

        <div className="mt-6 text-center">
          <Link to="/login" className="text-sm text-brand-600 hover:underline">
            ← Back to sign in
          </Link>
        </div>
      </div>
    </div>
  );
}
