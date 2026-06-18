import { useCallback } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";
import useIdleTimeout from "../hooks/useIdleTimeout.js";
import NotificationBell from "./NotificationBell.jsx";
import Icon from "./Icon.jsx";

// Role-aware navigation: links shown depend on the user's role (RBAC).
const NAV = [
  { to: "/", label: "Circulars", icon: "document", roles: ["Employee", "Manager", "Administrator"] },
  { to: "/compliance", label: "Compliance", icon: "chart", roles: ["Manager", "Administrator"] },
  { to: "/requests", label: "Requests", icon: "inbox", roles: ["Manager", "Administrator"] },
  { to: "/upload", label: "Upload", icon: "upload", roles: ["Administrator"] },
  { to: "/users", label: "Users", icon: "users", roles: ["Administrator"] },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const links = NAV.filter((n) => n.roles.includes(user?.role));

  // FR-03: sign out after 30 minutes of inactivity.
  const handleIdle = useCallback(() => {
    logout();
    navigate("/login?expired=1");
  }, [logout, navigate]);
  useIdleTimeout(handleIdle);

  function handleLogout() {
    logout();
    navigate("/login");
  }

  return (
    <div className="flex h-full min-h-screen">
      {/* Sidebar */}
      <aside className="hidden w-64 flex-shrink-0 flex-col bg-brand-700 text-white md:flex">
        <div className="flex items-center gap-2 px-5 py-5">
          <div className="grid h-9 w-9 place-items-center rounded-lg bg-white/15">
            <Icon name="bank" className="h-5 w-5 text-white" />
          </div>
          <div className="leading-tight">
            <div className="text-sm font-semibold">Circular Hub</div>
            <div className="text-[11px] text-brand-100">CBSL Compliance</div>
          </div>
        </div>
        <nav className="mt-2 flex flex-col gap-1 px-3">
          {links.map((l) => (
            <NavLink
              key={l.to}
              to={l.to}
              end={l.to === "/"}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition ${
                  isActive
                    ? "bg-white/15 font-semibold text-white"
                    : "text-brand-100 hover:bg-white/10"
                }`
              }
            >
              <Icon name={l.icon} className="h-5 w-5" />
              {l.label}
            </NavLink>
          ))}
        </nav>
        <div className="mt-auto px-5 py-4 text-[11px] text-brand-100">
          Smart Circular Summarization &amp; Management System
        </div>
      </aside>

      {/* Main column */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-ink-line bg-white px-6 py-3">
          <div className="text-sm text-ink-muted">
            Welcome, <span className="font-semibold text-ink">{user?.full_name}</span>
          </div>
          <div className="flex items-center gap-3">
            <NotificationBell />
            <span className="badge bg-brand-50 text-brand-700">{user?.role}</span>
            <button onClick={handleLogout} className="btn-ghost py-1.5 text-xs">
              Sign out
            </button>
          </div>
        </header>
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
