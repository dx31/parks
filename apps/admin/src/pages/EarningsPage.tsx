import { useEffect, useState } from "react";
import { getEarningsReport } from "../api";
import { useAuth } from "../auth";
import { formatSoles, type EarningsReport } from "../types";

type Range = "today" | "week" | "month" | "all";

function rangeQuery(range: Range) {
  if (range === "all") {
    return {};
  }
  const now = new Date();
  const from = new Date(now);
  if (range === "today") {
    from.setHours(0, 0, 0, 0);
  } else if (range === "week") {
    from.setDate(from.getDate() - 7);
  } else {
    from.setMonth(from.getMonth() - 1);
  }
  return { from: from.toISOString(), to: now.toISOString() };
}

function formatWhen(value: string | null) {
  if (!value) {
    return "—";
  }
  return new Date(value).toLocaleString("es-PE");
}

export function EarningsPage() {
  const { session } = useAuth();
  const token = session!.token;
  const [range, setRange] = useState<Range>("month");
  const [report, setReport] = useState<EarningsReport | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  async function reload() {
    setLoading(true);
    setError(null);
    try {
      setReport(await getEarningsReport(token, rangeQuery(range)));
    } catch (err) {
      setError(err instanceof Error ? err.message : "No se pudo cargar el reporte.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void reload();
  }, [range]);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Ganancias</h1>
          <p className="text-sm opacity-70">
            Cada liberación de un espacio se registra como pagada (hora o fracción).
          </p>
        </div>
        <label className="form-control">
          <span className="label-text">Periodo</span>
          <select
            className="select select-bordered"
            value={range}
            onChange={(event) => setRange(event.target.value as Range)}
          >
            <option value="today">Hoy</option>
            <option value="week">Últimos 7 días</option>
            <option value="month">Último mes</option>
            <option value="all">Todo</option>
          </select>
        </label>
      </div>

      {error ? <div className="alert alert-error">{error}</div> : null}

      <div className="grid gap-3 md:grid-cols-3">
        <div className="stat rounded-box bg-base-100 shadow-sm">
          <div className="stat-title">Total cobrado</div>
          <div className="stat-value text-2xl">{formatSoles(report?.totalAmount ?? 0)}</div>
        </div>
        <div className="stat rounded-box bg-base-100 shadow-sm">
          <div className="stat-title">Pagos</div>
          <div className="stat-value text-2xl">{report?.paymentsCount ?? 0}</div>
        </div>
        <div className="stat rounded-box bg-base-100 shadow-sm">
          <div className="stat-title">Horas cobradas</div>
          <div className="stat-value text-2xl">{report?.totalHours ?? 0}</div>
        </div>
      </div>

      <div className="overflow-x-auto rounded-box bg-base-100 shadow-sm">
        <table className="table">
          <thead>
            <tr>
              <th>Día</th>
              <th>Pagos</th>
              <th>Horas</th>
              <th>Monto</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={4}>Cargando…</td>
              </tr>
            ) : !report || report.days.length === 0 ? (
              <tr>
                <td colSpan={4}>Aún no hay cobros en este periodo.</td>
              </tr>
            ) : (
              report.days.map((day) => (
                <tr key={day.date}>
                  <td>{day.date}</td>
                  <td>{day.paymentsCount}</td>
                  <td>{day.hours}</td>
                  <td>{formatSoles(day.amount)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="overflow-x-auto rounded-box bg-base-100 shadow-sm">
        <table className="table">
          <thead>
            <tr>
              <th>Liberado</th>
              <th>Espacio</th>
              <th>Operador</th>
              <th>Placa</th>
              <th>Horas</th>
              <th>Tarifa</th>
              <th>Cobrado</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7}>Cargando…</td>
              </tr>
            ) : !report || report.payments.length === 0 ? (
              <tr>
                <td colSpan={7}>No hay pagos registrados.</td>
              </tr>
            ) : (
              report.payments.map((payment) => (
                <tr key={payment.id}>
                  <td>{formatWhen(payment.endedAt)}</td>
                  <td className="font-medium">{payment.spaceCode}</td>
                  <td>{payment.operatorName}</td>
                  <td>{payment.licensePlate ?? "—"}</td>
                  <td>{payment.billedHours}</td>
                  <td>{formatSoles(payment.hourlyRate)} / h</td>
                  <td>{formatSoles(payment.amount)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
