export type Operator = {
  id: string;
  name: string;
  username: string;
};

export type Session = {
  token: string;
  operator: Operator;
};

export type Zone = {
  id: string;
  name: string;
  city: string;
  spacesCount: number;
  freeCount: number;
  videoUrl: string | null;
};

export type ClientIdentity = {
  dni: string;
  ruc: string;
  name: string;
  address: string | null;
};

export type SpaceStatus = "free" | "occupied" | "reserved" | "outOfService";

export type Space = {
  id: string;
  code: string;
  zoneId: string;
  zoneName: string;
  latitude: number;
  longitude: number;
  hourlyRate: number;
  status: SpaceStatus;
  notes: string | null;
  updatedAt: string;
  activeSessionId: string | null;
  clientDni: string | null;
  clientRuc: string | null;
  clientName: string | null;
  occupiedSince: string | null;
  licensePlate?: string | null;
  reservedFrom?: string | null;
  limitUntil?: string | null;
  exceededLimit?: boolean;
};

export const statusLabel: Record<SpaceStatus, string> = {
  free: "Libre",
  occupied: "Ocupado",
  reserved: "Reservado",
  outOfService: "Fuera de servicio",
};

export const statusBadge: Record<SpaceStatus, string> = {
  free: "badge-success",
  occupied: "badge-error",
  reserved: "badge-warning",
  outOfService: "badge-ghost",
};

export function hoursOrFraction(startedAt: Date, endedAt: Date) {
  const elapsed = endedAt.getTime() - startedAt.getTime();
  if (elapsed <= 0) {
    return 1;
  }
  return Math.max(1, Math.ceil(elapsed / 3_600_000));
}

export function formatSoles(amount: number) {
  return `S/ ${amount.toFixed(2)}`;
}

export function isOverdue(space: Space, now = Date.now()) {
  if (!space.limitUntil) {
    return false;
  }
  if (space.status !== "occupied" && space.status !== "reserved") {
    return false;
  }
  return now > new Date(space.limitUntil).getTime();
}

export function formatOccupiedDuration(startedAt: string, now = Date.now()) {
  const elapsed = Math.max(0, now - new Date(startedAt).getTime());
  const totalMinutes = Math.floor(elapsed / 60_000);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0) {
    return `${hours} h ${minutes} min`;
  }
  if (totalMinutes < 1) {
    return "menos de 1 min";
  }
  return `${minutes} min`;
}

export type ParkingPayment = {
  id: string;
  spaceId: string;
  spaceCode: string;
  operatorId: string;
  operatorName: string;
  licensePlate: string | null;
  startedAt: string;
  endedAt: string | null;
  isActive: boolean;
  billedHours: number;
  amount: number;
  hourlyRate: number;
  paid: boolean;
};

export type EarningsDay = {
  date: string;
  paymentsCount: number;
  hours: number;
  amount: number;
};

export type EarningsReport = {
  from: string | null;
  to: string | null;
  paymentsCount: number;
  totalHours: number;
  totalAmount: number;
  days: EarningsDay[];
  payments: ParkingPayment[];
};
