import { useEffect, useState, type FormEvent } from "react";
import { createOperator, deleteOperator, listOperators, updateOperator } from "../api";
import { useAuth } from "../auth";
import type { Operator } from "../types";

const emptyForm = { name: "", username: "", pin: "" };

export function UsersPage() {
  const { session } = useAuth();
  const token = session!.token;
  const [users, setUsers] = useState<Operator[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Operator | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [open, setOpen] = useState(false);

  async function reload() {
    setLoading(true);
    setError(null);
    try {
      setUsers(await listOperators(token));
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudieron cargar los usuarios.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, []);

  function openCreate() {
    setEditing(null);
    setForm(emptyForm);
    setOpen(true);
  }

  function openEdit(user: Operator) {
    setEditing(user);
    setForm({ name: user.name, username: user.username, pin: "" });
    setOpen(true);
  }

  async function onSave(event: FormEvent) {
    event.preventDefault();
    setError(null);
    try {
      if (editing) {
        await updateOperator(token, editing.id, {
          name: form.name,
          username: form.username,
          pin: form.pin || undefined,
        });
      } else {
        await createOperator(token, form);
      }
      setOpen(false);
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo guardar el usuario.");
    }
  }

  async function onDelete(user: Operator) {
    if (!window.confirm(`¿Eliminar a ${user.name}?`)) {
      return;
    }
    try {
      await deleteOperator(token, user.id);
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo eliminar el usuario.");
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Usuarios</h1>
          <p className="text-sm opacity-70">Operadores que pueden entrar a las apps y a este panel.</p>
        </div>
        <button type="button" className="btn btn-primary" onClick={openCreate}>
          Nuevo usuario
        </button>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <div className="overflow-x-auto rounded-box bg-base-100 shadow-sm">
        <table className="table">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Usuario</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={3}>Cargando…</td>
              </tr>
            ) : (
              users.map((user) => (
                <tr key={user.id}>
                  <td className="font-medium">{user.name}</td>
                  <td>{user.username}</td>
                  <td className="text-right">
                    <button type="button" className="btn btn-ghost btn-sm" onClick={() => openEdit(user)}>
                      Editar
                    </button>
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm text-error"
                      onClick={() => onDelete(user)}
                    >
                      Borrar
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <dialog className={`modal ${open ? "modal-open" : ""}`}>
        <form className="modal-box space-y-3" onSubmit={onSave}>
          <h3 className="text-lg font-bold">{editing ? "Editar usuario" : "Nuevo usuario"}</h3>
          <label className="flex w-full flex-col gap-1">
            <span className="text-sm">Nombre</span>
            <input
              className="input input-bordered w-full"
              value={form.name}
              onChange={(event) => setForm({ ...form, name: event.target.value })}
              required
            />
          </label>
          <label className="flex w-full flex-col gap-1">
            <span className="text-sm">Usuario</span>
            <input
              className="input input-bordered w-full"
              value={form.username}
              onChange={(event) => setForm({ ...form, username: event.target.value })}
              required
            />
          </label>
          <label className="flex w-full flex-col gap-1">
            <span className="text-sm">{editing ? "PIN nuevo (opcional)" : "PIN"}</span>
            <input
              className="input input-bordered w-full"
              type="password"
              value={form.pin}
              onChange={(event) => setForm({ ...form, pin: event.target.value })}
              required={!editing}
              minLength={editing ? undefined : 4}
            />
          </label>
          <div className="modal-action">
            <button type="button" className="btn" onClick={() => setOpen(false)}>
              Cancelar
            </button>
            <button type="submit" className="btn btn-primary">
              Guardar
            </button>
          </div>
        </form>
        <form method="dialog" className="modal-backdrop">
          <button type="button" onClick={() => setOpen(false)}>
            close
          </button>
        </form>
      </dialog>
    </div>
  );
}
