import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth";

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `btn btn-ghost btn-sm ${isActive ? "btn-active" : ""}`;

export function Layout() {
  const { session, logout } = useAuth();

  return (
    <div className="min-h-screen bg-base-200">
      <div className="navbar bg-base-100 shadow-sm">
        <div className="navbar-start gap-2">
          <span className="btn btn-ghost text-lg font-bold">Parkímetro</span>
          <NavLink to="/espacios" className={linkClass}>
            Espacios
          </NavLink>
          <NavLink to="/usuarios" className={linkClass}>
            Usuarios
          </NavLink>
        </div>
        <div className="navbar-end gap-3 px-3">
          <span className="text-sm opacity-70">{session?.operator.name}</span>
          <button type="button" className="btn btn-outline btn-sm" onClick={logout}>
            Salir
          </button>
        </div>
      </div>
      <main className="mx-auto max-w-6xl p-6">
        <Outlet />
      </main>
    </div>
  );
}
