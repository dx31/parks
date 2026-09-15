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
