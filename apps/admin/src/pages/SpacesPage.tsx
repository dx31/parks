import { useEffect, useState, type FormEvent } from "react";
import {
  changeSpaceStatus,
  createSpace,
  createZone,
  deleteSpace,
  listSpaces,
  listZones,
  lookupClient,
  reserveSpace,
  updateSpace,
} from "../api";
import { useAuth } from "../auth";
import { statusBadge, statusLabel, formatOccupiedDuration, formatSoles, hoursOrFraction, isOverdue, type Space, type SpaceStatus, type Zone } from "../types";

const emptyForm = {
  code: "",
  zoneId: "",
  latitude: "19.43",
  longitude: "-99.13",
  hourlyRate: "2",
  notes: "",
};

type FormState = typeof emptyForm;

function OccupiedTimer({ startedAt, hourlyRate }: { startedAt: string; hourlyRate: number }) {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const id = window.setInterval(() => setNow(Date.now()), 60_000);
    return () => window.clearInterval(id);
  }, []);

  const hours = hoursOrFraction(new Date(startedAt), new Date(now));
  const amount = hours * (hourlyRate > 0 ? hourlyRate : 2);
  return (
    <span>
      {formatOccupiedDuration(startedAt, now)} · {formatSoles(amount)}
    </span>
  );
}

export function SpacesPage() {
  const { session } = useAuth();
  const token = session!.token;
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [zoneFilter, setZoneFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<SpaceStatus | "">("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Space | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [zoneName, setZoneName] = useState("");
  const [zoneVideoUrl, setZoneVideoUrl] = useState("/api/cameras/demo");
  const [open, setOpen] = useState(false);

  async function reload() {
    setLoading(true);
    setError(null);
    try {
      const [nextZones, nextSpaces] = await Promise.all([
        listZones(token),
        listSpaces(token, {
          zoneId: zoneFilter || undefined,
          status: statusFilter || undefined,
        }),
      ]);
      setZones(nextZones);
      setSpaces(nextSpaces);
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudieron cargar los espacios.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, [zoneFilter, statusFilter]);

  function openCreate() {
    setEditing(null);
    setForm({ ...emptyForm, zoneId: zones[0]?.id ?? "" });
    setOpen(true);
  }

  function openEdit(space: Space) {
    setEditing(space);
    setForm({
      code: space.code,
      zoneId: space.zoneId,
      latitude: String(space.latitude),
      longitude: String(space.longitude),
      hourlyRate: String(space.hourlyRate),
      notes: space.notes ?? "",
    });
    setOpen(true);
  }

  async function onSave(event: FormEvent) {
    event.preventDefault();
    setError(null);
    try {
      const payload = {
        code: form.code,
        latitude: Number(form.latitude),
        longitude: Number(form.longitude),
        hourlyRate: Number(form.hourlyRate),
        notes: form.notes || undefined,
      };
      if (editing) {
        await updateSpace(token, editing.id, payload);
      } else {
        await createSpace(token, { ...payload, zoneId: form.zoneId });
      }
      setOpen(false);
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo guardar el espacio.");
    }
  }

  async function onStatus(space: Space, status: SpaceStatus) {
    try {
      if (status === "reserved") {
        const dni = window.prompt("DNI del cliente (8 dígitos):", space.clientDni ?? "");
        if (!dni) {
          return;
        }
        let clientName: string | undefined;
        try {
          const found = await lookupClient(token, dni.trim());
          clientName = found.name;
        } catch {
          const typed = window.prompt("No se encontró el DNI. Ingresa el nombre completo:", space.clientName ?? "");
          if (!typed?.trim()) {
            return;
          }
          clientName = typed.trim();
        }
        await reserveSpace(token, space.id, dni.trim(), clientName);
      } else {
        await changeSpaceStatus(token, space.id, status);
      }
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo cambiar el estado.");
    }
  }

  async function onDelete(space: Space) {
    if (!window.confirm(`¿Eliminar el espacio ${space.code}?`)) {
      return;
    }
    try {
      await deleteSpace(token, space.id);
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo eliminar el espacio.");
    }
  }

  async function onCreateZone(event: FormEvent) {
    event.preventDefault();
    if (!zoneName.trim()) {
      return;
    }
    try {
      await createZone(token, {
        name: zoneName,
        city: "Ciudad",
        videoUrl: zoneVideoUrl.trim() || undefined,
      });
      setZoneName("");
      await reload();
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo crear la zona.");
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Espacios</h1>
          <p className="text-sm opacity-70">Crea, edita y cambia el estado de los parquímetros.</p>
        </div>
        <button type="button" className="btn btn-primary" onClick={openCreate}>
          Nuevo espacio
        </button>
      </div>

      <div className="card bg-base-100 shadow-sm">
        <div className="card-body grid gap-3 md:grid-cols-3">
          <label className="form-control">
            <span className="label-text">Zona</span>
            <select
              className="select select-bordered"
              value={zoneFilter}
              onChange={(event) => setZoneFilter(event.target.value)}
            >
              <option value="">Todas</option>
              {zones.map((zone) => (
                <option key={zone.id} value={zone.id}>
                  {zone.name}
                </option>
              ))}
            </select>
          </label>
          <label className="form-control">
            <span className="label-text">Estado</span>
            <select
              className="select select-bordered"
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value as SpaceStatus | "")}
            >
              <option value="">Todos</option>
              <option value="free">Libre</option>
              <option value="occupied">Ocupado</option>
              <option value="reserved">Reservado</option>
              <option value="outOfService">Fuera de servicio</option>
            </select>
          </label>
          <form className="flex items-end gap-2" onSubmit={onCreateZone}>
            <label className="form-control flex-1">
              <span className="label-text">Nueva zona</span>
              <input
                className="input input-bordered"
                value={zoneName}
                onChange={(event) => setZoneName(event.target.value)}
                placeholder="Nombre de zona"
              />
            </label>
            <label className="form-control flex-1">
              <span className="label-text">URL de video</span>
              <input
                className="input input-bordered"
                value={zoneVideoUrl}
                onChange={(event) => setZoneVideoUrl(event.target.value)}
                placeholder="/api/cameras/demo"
              />
            </label>
            <button type="submit" className="btn btn-outline">
              Agregar
            </button>
          </form>
        </div>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <div className="overflow-x-auto rounded-box bg-base-100 shadow-sm">
        <table className="table">
          <thead>
            <tr>
              <th>Código</th>
              <th>Zona</th>
              <th>Estado</th>
              <th>Tarifa</th>
              <th>Ocupación</th>
              <th>Notas</th>
              <th>Cliente</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8}>Cargando…</td>
              </tr>
            ) : spaces.length === 0 ? (
              <tr>
                <td colSpan={8}>No hay espacios para mostrar.</td>
              </tr>
            ) : (
              spaces.map((space) => (
                <tr key={space.id}>
                  <td className="font-medium">
                    <span className="inline-flex items-center gap-2">
                      {isOverdue(space) ? (
                        <span className="text-warning" title="Se excedió la hora de salida estimada">
                          ⚠
                        </span>
                      ) : null}
                      {space.code}
                    </span>
                  </td>
                  <td>{space.zoneName}</td>
                  <td>
                    <span className={`badge ${statusBadge[space.status]}`}>
                      {statusLabel[space.status]}
                    </span>
                  </td>
                  <td>{formatSoles(space.hourlyRate)} / h</td>
                  <td>
                    {space.occupiedSince ? (
                      <OccupiedTimer startedAt={space.occupiedSince} hourlyRate={space.hourlyRate} />
                    ) : (
                      "—"
                    )}
                  </td>
                  <td>{space.notes ?? "—"}</td>
                  <td>
                    {space.clientName
                      ? `${space.clientName} · DNI ${space.clientDni}`
                      : "—"}
                  </td>
                  <td className="flex flex-wrap justify-end gap-2">
                    <select
                      className="select select-bordered select-sm w-40"
                      value={space.status}
                      onChange={(event) => onStatus(space, event.target.value as SpaceStatus)}
                    >
                      <option value="free">Libre</option>
                      <option value="occupied">Ocupado</option>
                      <option value="reserved">Reservado</option>
                      <option value="outOfService">Fuera de servicio</option>
                    </select>
                    <button type="button" className="btn btn-ghost btn-sm" onClick={() => openEdit(space)}>
                      Editar
                    </button>
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm text-error"
                      onClick={() => onDelete(space)}
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
          <h3 className="text-lg font-bold">{editing ? "Editar espacio" : "Nuevo espacio"}</h3>
          <label className="form-control">
            <span className="label-text">Código</span>
            <input
              className="input input-bordered"
              value={form.code}
              onChange={(event) => setForm({ ...form, code: event.target.value })}
              required
            />
          </label>
          {!editing ? (
            <label className="form-control">
              <span className="label-text">Zona</span>
              <select
                className="select select-bordered"
                value={form.zoneId}
                onChange={(event) => setForm({ ...form, zoneId: event.target.value })}
                required
              >
                {zones.map((zone) => (
                  <option key={zone.id} value={zone.id}>
                    {zone.name}
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          <div className="grid grid-cols-2 gap-3">
            <label className="form-control">
              <span className="label-text">Latitud</span>
              <input
                className="input input-bordered"
                value={form.latitude}
                onChange={(event) => setForm({ ...form, latitude: event.target.value })}
              />
            </label>
            <label className="form-control">
              <span className="label-text">Longitud</span>
              <input
                className="input input-bordered"
                value={form.longitude}
                onChange={(event) => setForm({ ...form, longitude: event.target.value })}
              />
            </label>
          </div>
          <label className="form-control">
            <span className="label-text">Tarifa por hora (S/)</span>
            <input
              className="input input-bordered"
              value={form.hourlyRate}
              onChange={(event) => setForm({ ...form, hourlyRate: event.target.value })}
            />
          </label>
          <label className="form-control">
            <span className="label-text">Notas</span>
            <input
              className="input input-bordered"
              value={form.notes}
              onChange={(event) => setForm({ ...form, notes: event.target.value })}
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
