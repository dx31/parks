import { useState, type FormEvent } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth";

export function LoginPage() {
  const { session, login } = useAuth();
  const [username, setUsername] = useState("ana");
  const [pin, setPin] = useState("1234");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (session) {
    return <Navigate to="/espacios" replace />;
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(username, pin);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo iniciar sesión.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-base-200 p-6">
      <form className="card w-full max-w-md bg-base-100 shadow-xl" onSubmit={onSubmit}>
        <div className="card-body">
          <h1 className="card-title">Administración Parkímetro</h1>
          <p className="text-sm opacity-70">Entra con un usuario operador para gestionar espacios y cuentas.</p>
          {error ? <div className="alert alert-error">{error}</div> : null}
          <label className="form-control w-full">
            <span className="label-text">Usuario</span>
            <input
              className="input input-bordered"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              autoComplete="username"
            />
          </label>
          <label className="form-control w-full">
            <span className="label-text">PIN</span>
            <input
              className="input input-bordered"
              type="password"
              value={pin}
              onChange={(event) => setPin(event.target.value)}
              autoComplete="current-password"
            />
          </label>
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? "Entrando…" : "Entrar"}
          </button>
        </div>
      </form>
    </div>
  );
}
