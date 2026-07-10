import { useEffect, useState } from "react";
import client from "../api/client";

// Admin user management (FR-02 roles, FR-05 department assignment).
const ROLES = ["Employee", "Manager", "Compliance Officer", "Administrator"];
const EMPTY_FORM = {
  username: "",
  email: "",
  full_name: "",
  role: "Employee",
  department_id: "",
  password: "",
};

export default function Users() {
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [form, setForm] = useState(EMPTY_FORM);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function load() {
    const [u, d] = await Promise.all([
      client.get("/users"),
      client.get("/users/departments"),
    ]);
    setUsers(u.data);
    setDepartments(d.data);
  }

  useEffect(() => {
    load().catch(() => setError("Failed to load users."));
  }, []);

  async function createUser(e) {
    e.preventDefault();
    setError("");
    setBusy(true);
    try {
      await client.post("/users", {
        ...form,
        department_id: form.department_id ? Number(form.department_id) : null,
      });
      setForm(EMPTY_FORM);
      await load();
    } catch (err) {
      setError(err.response?.data?.error || "Failed to create user.");
    } finally {
      setBusy(false);
    }
  }

  async function patchUser(id, changes) {
    await client.patch(`/users/${id}`, changes);
    await load();
  }

  async function toggleActive(u) {
    const action = u.is_active ? "deactivate" : "activate";
    try {
      await client.post(`/users/${u.id}/${action}`);
      await load();
    } catch (err) {
      setError(err.response?.data?.error || "Action failed.");
    }
  }

  return (
    <div className="space-y-5">
      <div>
        <div className="text-xs font-semibold uppercase tracking-wide text-brand-600">
          Administration
        </div>
        <h1 className="text-xl font-bold text-ink">User Management</h1>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-status-unread">{error}</div>
      )}

      {/* Create user */}
      <form onSubmit={createUser} className="card grid gap-3 p-5 sm:grid-cols-2 lg:grid-cols-3">
        <input className="input" placeholder="Username" value={form.username}
          onChange={(e) => setForm({ ...form, username: e.target.value })} required />
        <input className="input" type="email" placeholder="Email" value={form.email}
          onChange={(e) => setForm({ ...form, email: e.target.value })} required />
        <input className="input" placeholder="Full name" value={form.full_name}
          onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
        <select className="input" value={form.role}
          onChange={(e) => setForm({ ...form, role: e.target.value })}>
          {ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
        </select>
        <select className="input" value={form.department_id}
          onChange={(e) => setForm({ ...form, department_id: e.target.value })}>
          <option value="">— Department —</option>
          {departments.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <input className="input" type="password" placeholder="Temp password (8+ chars)"
          value={form.password}
          onChange={(e) => setForm({ ...form, password: e.target.value })} required />
        <div className="sm:col-span-2 lg:col-span-3">
          <button type="submit" disabled={busy} className="btn-primary">
            {busy ? "Adding…" : "Add user"}
          </button>
        </div>
      </form>

      {/* Users table */}
      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-ink-surface text-left text-xs uppercase text-ink-muted">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Role</th>
              <th className="px-4 py-3 font-medium">Department</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-line">
            {users.map((u) => (
              <tr key={u.id} className={u.is_active ? "" : "opacity-50"}>
                <td className="px-4 py-3">
                  <div className="font-medium text-ink">{u.full_name}</div>
                  <div className="text-xs text-ink-muted">{u.username} · {u.email}</div>
                </td>
                <td className="px-4 py-3">
                  <select
                    className="input py-1 text-xs"
                    value={u.role}
                    onChange={(e) => patchUser(u.id, { role: e.target.value })}
                  >
                    {ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
                  </select>
                </td>
                <td className="px-4 py-3">
                  <select
                    className="input py-1 text-xs"
                    value={u.department_id || ""}
                    onChange={(e) =>
                      patchUser(u.id, {
                        department_id: e.target.value ? Number(e.target.value) : null,
                      })
                    }
                  >
                    <option value="">—</option>
                    {departments.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                </td>
                <td className="px-4 py-3">
                  <span className={`badge ${u.is_active
                    ? "bg-green-50 text-status-ack"
                    : "bg-red-50 text-status-unread"}`}>
                    {u.is_active ? "Active" : "Inactive"}
                  </span>
                </td>
                <td className="px-4 py-3 text-right">
                  <button onClick={() => toggleActive(u)} className="btn-ghost py-1.5 text-xs">
                    {u.is_active ? "Deactivate" : "Activate"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
